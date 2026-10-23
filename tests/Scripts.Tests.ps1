BeforeDiscovery {
    $scriptNames = @('Invoke-PreUpgradeCheck', 'Invoke-PostUpgradeCheck')
}

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
    $scriptsPath = Join-Path -Path $IpuRepositoryRoot -ChildPath 'scripts'
    $preScript = Join-Path -Path $scriptsPath -ChildPath 'Invoke-PreUpgradeCheck.ps1'
    $postScript = Join-Path -Path $scriptsPath -ChildPath 'Invoke-PostUpgradeCheck.ps1'

    function Invoke-IpuTestProcess {
        # Runs a script with -File in a new process, as other tools do, and returns its exit code and errors.
        param(
            [Parameter(Mandatory)]
            [string] $ScriptPath,

            [string[]] $ArgumentList = @()
        )

        $errorFile = Join-Path -Path $TestDrive -ChildPath "$([guid]::NewGuid().Guid).err"
        $arguments = @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', "`"$ScriptPath`"") + $ArgumentList
        $process = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $arguments -Wait -PassThru -NoNewWindow `
            -RedirectStandardError $errorFile -RedirectStandardOutput (Join-Path -Path $TestDrive -ChildPath "$([guid]::NewGuid().Guid).out")
        [pscustomobject]@{
            ExitCode = $process.ExitCode
            Errors   = (Get-Content -Path $errorFile) -join "`n"
        }
    }
}

Describe 'Entry-point scripts' {
    BeforeAll {
        Mock -ModuleName InPlaceUpgrade -CommandName Show-IpuReport -MockWith {}
    }

    BeforeEach {
        $outputPath = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().Guid)
    }

    It 'pre-check exits with 0 when every check passes' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith { New-IpuTestSnapshot }
        & $preScript -TargetVersion 2022 -OutputPath $outputPath
        $LASTEXITCODE | Should -Be 0
    }

    It 'pre-check exits with 2 when a check warns' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith {
            $domainController = New-IpuTestSnapshot
            $domainController.ComputerSystem.DomainRole = 5
            $domainController
        }
        & $preScript -TargetVersion 2022 -OutputPath $outputPath
        $LASTEXITCODE | Should -Be 2
    }

    It 'pre-check exits with 1 when a check fails' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith {
            $pending = New-IpuTestSnapshot
            $pending.PendingReboot.IsPending = $true
            $pending
        }
        & $preScript -TargetVersion 2022 -OutputPath $outputPath
        $LASTEXITCODE | Should -Be 1
    }

    It 'post-check compares with the baseline saved by the pre-check' {
        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith { New-IpuTestSnapshot }
        & $preScript -TargetVersion 2022 -OutputPath $outputPath

        Mock -ModuleName InPlaceUpgrade -CommandName Get-IpuSnapshot -MockWith {
            $upgraded = New-IpuTestSnapshot
            $upgraded.OperatingSystem.BuildNumber = 20348
            $upgraded
        }
        & $postScript -OutputPath $outputPath
        $LASTEXITCODE | Should -Be 0
    }
}

Describe 'Entry-point scripts in a new process' {
    It 'exit with 1 when the check can''t run' {
        $result = Invoke-IpuTestProcess -ScriptPath $postScript -ArgumentList '-OutputPath', "`"$TestDrive\empty`""
        $result.ExitCode | Should -Be 1
        $result.Errors | Should -BeLike '*No pre-check report*'
    }

    It 'exit with 1 when a parameter is invalid' {
        $result = Invoke-IpuTestProcess -ScriptPath $preScript -ArgumentList '-TargetVersion', '2023'
        $result.ExitCode | Should -Be 1
    }

    It 'find the module next to them, as in the release zip' {
        $release = Join-Path -Path $TestDrive -ChildPath 'release'
        New-Item -Path $release -ItemType Directory | Out-Null
        Copy-Item -Path $IpuSourcePath -Destination $release -Recurse
        Copy-Item -Path $postScript -Destination $release

        $result = Invoke-IpuTestProcess -ScriptPath (Join-Path -Path $release -ChildPath 'Invoke-PostUpgradeCheck.ps1') -ArgumentList '-OutputPath', "`"$TestDrive\empty`""
        $result.Errors | Should -BeLike '*No pre-check report*'
    }
}

Describe 'Help for <_>.ps1' -ForEach $scriptNames {
    BeforeAll {
        $path = Join-Path -Path $IpuRepositoryRoot -ChildPath "scripts\$_.ps1"
        $help = Get-Help -Name $path -Full
    }

    It 'has a synopsis, a description and an example' {
        $help.Synopsis | Should -Not -BeNullOrEmpty
        $help.Description | Should -Not -BeNullOrEmpty
        @($help.Examples.Example).Count | Should -BeGreaterThan 0
    }

    It 'describes every parameter' {
        $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
        $parameters = @((Get-Command -Name $path).Parameters.Keys | Where-Object { $commonParameters -notcontains $_ })
        foreach ($parameter in $parameters) {
            $parameterHelp = $help.Parameters.Parameter | Where-Object { $_.Name -eq $parameter }
            $parameterHelp.Description | Should -Not -BeNullOrEmpty -Because "-$parameter needs a .PARAMETER description"
        }
    }
}
