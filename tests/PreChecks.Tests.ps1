BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
}

Describe 'Pre-upgrade checks' {
    BeforeEach {
        $snapshot = New-IpuTestSnapshot
    }

    It 'passes every check on a healthy server' {
        $problems = Invoke-IpuTestCheck -Phase Pre -Snapshot $snapshot |
            Where-Object { $_.Status -ne 'Pass' } |
            ForEach-Object { '{0} {1}: {2}' -f $_.Id, $_.Status, $_.Message }
        $problems | Should -BeNullOrEmpty
    }

    Context 'PRE-001 Supported upgrade path' {
        It 'passes from build <Build> to <Target>' -ForEach @(
            @{ Build = 9600; Target = '2016' }
            @{ Build = 9600; Target = '2025' }
            @{ Build = 14393; Target = '2022' }
            @{ Build = 17763; Target = '2025' }
            @{ Build = 20348; Target = '2025' }
        ) {
            $snapshot.OperatingSystem.BuildNumber = $Build
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-001' -Snapshot $snapshot -TargetVersion $Target).Status | Should -Be 'Pass'
        }

        It 'fails from build <Build> to <Target>' -ForEach @(
            @{ Build = 9600; Target = '2022' }
            @{ Build = 14393; Target = '2016' }
            @{ Build = 26100; Target = '2025' }
            @{ Build = 19045; Target = '2022' }
        ) {
            $snapshot.OperatingSystem.BuildNumber = $Build
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-001' -Snapshot $snapshot -TargetVersion $Target).Status | Should -Be 'Fail'
        }
    }

    Context 'PRE-002 Edition can be upgraded' {
        It 'warns about an evaluation edition' {
            $snapshot.OperatingSystem.EditionId = 'ServerDatacenterEval'
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-002' -Snapshot $snapshot).Status | Should -Be 'Warning'
        }

        It 'fails for Windows Storage Server' {
            $snapshot.OperatingSystem.EditionId = 'ServerStorageStandard'
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-002' -Snapshot $snapshot).Status | Should -Be 'Fail'
        }

        It 'tells the operator to pick a Server Core image on Server Core' {
            $snapshot.OperatingSystem.InstallationType = 'Server Core'
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-002' -Snapshot $snapshot).Message | Should -BeLike '*Server Core image*'
        }
    }

    Context 'PRE-003 Free space on the system drive' {
        It 'fails below the minimum' {
            ($snapshot.Volumes | Where-Object { $_.DriveLetter -eq 'C:' }).FreeGB = 10.4
            $result = Invoke-IpuTestCheck -Phase Pre -Id 'PRE-003' -Snapshot $snapshot
            $result.Status | Should -Be 'Fail'
            $result.Message | Should -BeLike '*10.4 GB free*'
        }

        It 'fails when the system drive is not found' {
            $snapshot.OperatingSystem.SystemDrive = 'E:'
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-003' -Snapshot $snapshot).Status | Should -Be 'Fail'
        }
    }

    Context 'PRE-004 No pending restart' {
        It 'fails and names the reason' {
            $snapshot.PendingReboot.IsPending = $true
            $snapshot.PendingReboot.Reasons = @('Windows Update')
            $result = Invoke-IpuTestCheck -Phase Pre -Id 'PRE-004' -Snapshot $snapshot
            $result.Status | Should -Be 'Fail'
            $result.Message | Should -BeLike '*Windows Update*'
        }
    }

    Context 'PRE-005 Not a failover cluster node' {
        It 'fails when the Cluster service runs' {
            $snapshot.Services += [pscustomobject]@{ Name = 'ClusSvc'; DisplayName = 'Cluster Service'; State = 'Running'; StartMode = 'Auto' }
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-005' -Snapshot $snapshot).Status | Should -Be 'Fail'
        }
    }

    Context 'PRE-006 Not a domain controller' {
        It 'warns on a domain controller' {
            $snapshot.ComputerSystem.DomainRole = 5
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-006' -Snapshot $snapshot).Status | Should -Be 'Warning'
        }
    }

    Context 'PRE-007 NIC Teaming not in use' {
        It 'fails when a NIC team exists' {
            $snapshot.NicTeams = @('Team1')
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-007' -Snapshot $snapshot).Status | Should -Be 'Fail'
        }
    }

    Context 'PRE-008 OS language matches the Azure upgrade media' {
        It 'warns when the OS language is not en-US' {
            $snapshot.OperatingSystem.OSLanguage = 1030
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-008' -Snapshot $snapshot).Status | Should -Be 'Warning'
        }

        It 'is skipped outside Azure' {
            $snapshot.Azure.IsAzureVm = $false
            $snapshot.OperatingSystem.OSLanguage = 1030
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-008' -Snapshot $snapshot).Status | Should -Be 'Skipped'
        }
    }

    Context 'PRE-009 Volume licensing for the Azure upgrade media' {
        It 'fails with a retail product key' {
            $snapshot.Licensing.Description = 'Windows(R) Operating System, RETAIL channel'
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-009' -Snapshot $snapshot).Status | Should -Be 'Fail'
        }

        It 'is skipped outside Azure' {
            $snapshot.Azure.IsAzureVm = $false
            $snapshot.Licensing.Description = 'Windows(R) Operating System, RETAIL channel'
            (Invoke-IpuTestCheck -Phase Pre -Id 'PRE-009' -Snapshot $snapshot).Status | Should -Be 'Skipped'
        }
    }
}

Describe 'Check runner' {
    It 'reports Error when the data a check needs was not collected' {
        $snapshot = New-IpuTestSnapshot
        $snapshot.Services = $null
        $result = Invoke-IpuTestCheck -Phase Pre -Id 'PRE-005' -Snapshot $snapshot
        $result.Status | Should -Be 'Error'
        $result.Message | Should -BeLike '*Snapshot.Services*'
    }

    It 'reports Error when a check throws or returns an invalid outcome' {
        InModuleScope -ModuleName InPlaceUpgrade -ScriptBlock {
            $originalChecks = $script:Checks
            try {
                $script:Checks = @(
                    @{ Id = 'PRE-901'; Phase = 'Pre'; Title = 'Throws'; Requires = @(); Test = { throw 'boom' } }
                    @{ Id = 'PRE-902'; Phase = 'Pre'; Title = 'Invalid'; Requires = @(); Test = { 'not a hashtable' } }
                )
                $results = @(Invoke-IpuCheck -Phase Pre -Context @{ Snapshot = [pscustomobject]@{} })

                ($results | ForEach-Object { $_.Status }) -join ',' | Should -Be 'Error,Error'
                $results[0].Message | Should -BeLike '*boom*'
            }
            finally {
                $script:Checks = $originalChecks
            }
        }
    }
}
