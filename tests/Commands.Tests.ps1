BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
}

Describe 'Invoke-IpuPreCheck and Invoke-IpuPostCheck' {
    BeforeAll {
        Mock -ModuleName InPlaceUpgrade -CommandName Show-IpuReport -MockWith {}
    }

    BeforeEach {
        $outputPath = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().Guid)
    }

    It 'saves a baseline that the post-check compares with' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith { New-IpuTestSnapshot }
        $pre = Invoke-IpuPreCheck -TargetVersion 2022 -OutputPath $outputPath -PassThru

        $pre.OverallStatus | Should -Be 'Pass'
        @(Get-ChildItem -Path $outputPath -Filter "$env:COMPUTERNAME-pre-*.json").Count | Should -Be 1

        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith {
            $upgraded = New-IpuTestSnapshot
            $upgraded.OperatingSystem.BuildNumber = 20348
            $upgraded
        }
        $post = Invoke-IpuPostCheck -OutputPath $outputPath -PassThru

        $post.OverallStatus | Should -Be 'Pass'
        $post.TargetVersion | Should -Be '2022'
        $post.BaselinePath | Should -BeLike "*$env:COMPUTERNAME-pre-*.json"
        @(Get-ChildItem -Path $outputPath -Filter "$env:COMPUTERNAME-post-*.json").Count | Should -Be 1
    }

    It 'returns nothing without -PassThru' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith { New-IpuTestSnapshot }
        Invoke-IpuPreCheck -TargetVersion 2022 -OutputPath $outputPath | Should -BeNullOrEmpty
    }

    It 'reports Fail overall when a check fails' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith {
            $pending = New-IpuTestSnapshot
            $pending.PendingReboot.IsPending = $true
            $pending.PendingReboot.Reasons = @('Windows Update')
            $pending
        }
        (Invoke-IpuPreCheck -TargetVersion 2022 -OutputPath $outputPath -PassThru).OverallStatus | Should -Be 'Fail'
    }

    It 'needs a baseline for the post-check' {
        { Invoke-IpuPostCheck -OutputPath $outputPath } | Should -Throw '*No pre-check report*'
    }

    It 'limits a report folder it creates to administrators, SYSTEM and the current user' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith { New-IpuTestSnapshot }
        Invoke-IpuPreCheck -TargetVersion 2022 -OutputPath $outputPath

        $acl = Get-Acl -Path $outputPath
        $acl.AreAccessRulesProtected | Should -BeTrue
        $expected = @('S-1-5-32-544', 'S-1-5-18', [Security.Principal.WindowsIdentity]::GetCurrent().User.Value) | Sort-Object -Unique
        $actual = $acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | ForEach-Object { $_.IdentityReference.Value } | Sort-Object -Unique
        ($actual -join ',') | Should -Be ($expected -join ',')
    }

    It 'keeps the permissions of an existing report folder' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith { New-IpuTestSnapshot }
        New-Item -Path $outputPath -ItemType Directory | Out-Null
        $before = (Get-Acl -Path $outputPath).Sddl

        Invoke-IpuPreCheck -TargetVersion 2022 -OutputPath $outputPath
        (Get-Acl -Path $outputPath).Sddl | Should -Be $before
    }

    It 'refuses an existing report folder that someone else owns' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith { New-IpuTestSnapshot }
        Mock -ModuleName InPlaceUpgrade -CommandName Test-IpuTrustedOwner -MockWith { $false }
        New-Item -Path $outputPath -ItemType Directory | Out-Null

        { Invoke-IpuPreCheck -TargetVersion 2022 -OutputPath $outputPath } | Should -Throw '*Delete the folder*'
        Get-ChildItem -Path $outputPath | Should -BeNullOrEmpty
    }

    It 'refuses a baseline from another computer' {
        New-Item -Path $outputPath -ItemType Directory | Out-Null
        $path = Join-Path -Path $outputPath -ChildPath 'other.json'
        ConvertTo-Json -InputObject @{ Phase = 'Pre'; ComputerName = 'OTHER-SERVER'; TargetVersion = '2022'; Snapshot = @{ SchemaVersion = 1 } } |
            Set-Content -Path $path
        { Invoke-IpuPostCheck -BaselinePath $path -OutputPath $outputPath } | Should -Throw '*OTHER-SERVER*'
    }

    It 'refuses a baseline with another snapshot schema version' {
        New-Item -Path $outputPath -ItemType Directory | Out-Null
        $path = Join-Path -Path $outputPath -ChildPath 'future.json'
        ConvertTo-Json -InputObject @{ Phase = 'Pre'; ComputerName = $env:COMPUTERNAME; TargetVersion = '2022'; Snapshot = @{ SchemaVersion = 99 } } |
            Set-Content -Path $path
        { Invoke-IpuPostCheck -BaselinePath $path -OutputPath $outputPath } | Should -Throw '*schema version 99*'
    }

    It 'refuses a baseline that someone else owns' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith { New-IpuTestSnapshot }
        Invoke-IpuPreCheck -TargetVersion 2022 -OutputPath $outputPath

        Mock -ModuleName InPlaceUpgrade -CommandName Test-IpuTrustedOwner -MockWith { $false }
        { Invoke-IpuPostCheck -OutputPath $outputPath } | Should -Throw '*someone else may have created or changed it*'
    }

    It 'reads a baseline without a byte order mark, as PowerShell 7 writes it' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith {
            $upgraded = New-IpuTestSnapshot
            $upgraded.OperatingSystem.BuildNumber = 20348
            ($upgraded.Volumes | Where-Object { $_.DriveLetter -eq 'D:' }).Label = "Donn$([char]0x00E9)es"
            $upgraded
        }
        $baseline = New-IpuTestSnapshot
        ($baseline.Volumes | Where-Object { $_.DriveLetter -eq 'D:' }).Label = "Donn$([char]0x00E9)es"
        New-Item -Path $outputPath -ItemType Directory | Out-Null
        $path = Join-Path -Path $outputPath -ChildPath 'baseline.json'
        $json = ConvertTo-Json -InputObject @{ Phase = 'Pre'; ComputerName = $env:COMPUTERNAME; TargetVersion = '2022'; Snapshot = $baseline } -Depth 10
        [System.IO.File]::WriteAllText($path, $json, (New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false))

        $post = Invoke-IpuPostCheck -BaselinePath $path -OutputPath $outputPath -PassThru
        ($post.Results | Where-Object { $_.Id -eq 'POST-005' }).Status | Should -Be 'Pass'
    }
}

Describe 'Get-IpuSnapshot' {
    It 'requires an elevated session' {
        InModuleScope -ModuleName InPlaceUpgrade -ScriptBlock {
            Mock -CommandName Test-IpuAdministrator -MockWith { $false }
            { Get-IpuSnapshot } | Should -Throw '*elevated*'
        }
    }

    It 'records a failing collector and still collects the other sections' {
        InModuleScope -ModuleName InPlaceUpgrade -ScriptBlock {
            Mock -CommandName Test-IpuAdministrator -MockWith { $true }
            foreach ($collector in (Get-Command -Name 'Get-Ipu*Info' -CommandType Function)) {
                Mock -CommandName $collector.Name -MockWith { 'collected' }
            }
            Mock -CommandName Get-IpuServiceInfo -MockWith { throw 'WMI is broken' }

            $snapshot = Get-IpuSnapshot -WarningAction SilentlyContinue

            $snapshot.Services | Should -BeNullOrEmpty
            $snapshot.OperatingSystem | Should -Be 'collected'
            $snapshot.CollectionErrors.Section | Should -Be 'Services'
            $snapshot.CollectionErrors.Message | Should -Be 'WMI is broken'
        }
    }
}
