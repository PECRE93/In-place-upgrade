BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
}

Describe 'Post-upgrade checks' {
    BeforeEach {
        $baseline = New-IpuTestSnapshot
        $snapshot = New-IpuTestSnapshot
        $snapshot.OperatingSystem.Caption = 'Microsoft Windows Server 2022 Datacenter'
        $snapshot.OperatingSystem.Version = '10.0.20348'
        $snapshot.OperatingSystem.BuildNumber = 20348
    }

    It 'passes every check when only the version changed' {
        $problems = Invoke-IpuTestCheck -Phase Post -Snapshot $snapshot -Baseline $baseline |
            Where-Object { $_.Status -ne 'Pass' } |
            ForEach-Object { '{0} {1}: {2}' -f $_.Id, $_.Status, $_.Message }
        $problems | Should -BeNullOrEmpty
    }

    It 'reports Error when the baseline lacks the data a check needs' {
        $baseline.Services = $null
        $result = Invoke-IpuTestCheck -Phase Post -Id 'POST-002' -Snapshot $snapshot -Baseline $baseline
        $result.Status | Should -Be 'Error'
        $result.Message | Should -BeLike '*Baseline.Services*'
    }

    It 'skips a check when the baseline is from a version that did not collect its data' {
        $baseline.PSObject.Properties.Remove('Features')
        $result = Invoke-IpuTestCheck -Phase Post -Id 'POST-003' -Snapshot $snapshot -Baseline $baseline
        $result.Status | Should -Be 'Skipped'
        $result.Message | Should -BeLike '*older version*Baseline.Features*'
    }

    Context 'POST-001 Upgraded to the target version' {
        It 'fails when the server still runs the old version' {
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-001' -Snapshot $baseline -Baseline $baseline).Status | Should -Be 'Fail'
        }
    }

    Context 'POST-002 Automatic services are running' {
        It 'fails for a service that stopped' {
            ($snapshot.Services | Where-Object { $_.Name -eq 'W32Time' }).State = 'Stopped'
            $result = Invoke-IpuTestCheck -Phase Post -Id 'POST-002' -Snapshot $snapshot -Baseline $baseline
            $result.Status | Should -Be 'Fail'
            $result.Details | Should -Contain 'W32Time (Stopped)'
        }

        It 'fails for a service that disappeared' {
            $snapshot.Services = @($snapshot.Services | Where-Object { $_.Name -ne 'W32Time' })
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-002' -Snapshot $snapshot -Baseline $baseline).Details | Should -Contain 'W32Time (missing)'
        }

        It 'fails for a service that the upgrade disabled' {
            $w32time = $snapshot.Services | Where-Object { $_.Name -eq 'W32Time' }
            $w32time.State = 'Stopped'
            $w32time.StartMode = 'Disabled'
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-002' -Snapshot $snapshot -Baseline $baseline).Details | Should -Contain 'W32Time (disabled)'
        }

        It 'accepts a service that the new version starts on demand' {
            $w32time = $snapshot.Services | Where-Object { $_.Name -eq 'W32Time' }
            $w32time.State = 'Stopped'
            $w32time.StartMode = 'Manual'
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-002' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Pass'
        }

        It 'ignores services listed in the settings' {
            ($snapshot.Services | Where-Object { $_.Name -eq 'sppsvc' }).State = 'Stopped'
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-002' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Pass'
        }

        It 'ignores per-user services, which get a new name suffix' {
            ($snapshot.Services | Where-Object { $_.Name -eq 'CDPUserSvc_1a2b3' }).Name = 'CDPUserSvc_4c5d6'
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-002' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Pass'
        }

        It 'ignores services that were not running before the upgrade' {
            $snapshot.Services = @($snapshot.Services | Where-Object { $_.Name -ne 'Spooler' })
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-002' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Pass'
        }
    }

    Context 'POST-003 Roles and features are still installed' {
        It 'fails for a removed feature' {
            $snapshot.Features = @('FileAndStorage-Services')
            $result = Invoke-IpuTestCheck -Phase Post -Id 'POST-003' -Snapshot $snapshot -Baseline $baseline
            $result.Status | Should -Be 'Fail'
            $result.Details | Should -Contain 'Web-Server'
        }

        It 'ignores features that newer versions removed' {
            $baseline.Features = @($baseline.Features) + @('PowerShell-V2', 'Server-Gui-Shell')
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-003' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Pass'
        }
    }

    Context 'POST-004 TCP ports are listening again' {
        It 'fails for a port that no longer listens' {
            $snapshot.ListeningPorts = @($snapshot.ListeningPorts | Where-Object { $_.Port -ne 443 })
            $result = Invoke-IpuTestCheck -Phase Post -Id 'POST-004' -Snapshot $snapshot -Baseline $baseline
            $result.Status | Should -Be 'Fail'
            $result.Details | Should -Contain '443 (System)'
        }

        It 'ignores ports in the dynamic range' {
            $snapshot.ListeningPorts = @($snapshot.ListeningPorts | Where-Object { $_.Port -lt 49152 })
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-004' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Pass'
        }
    }

    Context 'POST-005 Volumes and drive letters are unchanged' {
        It 'fails for a missing volume' {
            $snapshot.Volumes = @($snapshot.Volumes | Where-Object { $_.DriveLetter -ne 'D:' })
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-005' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Fail'
        }

        It 'fails for a relabeled volume' {
            ($snapshot.Volumes | Where-Object { $_.DriveLetter -eq 'D:' }).Label = 'New Volume'
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-005' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Fail'
        }
    }

    Context 'POST-006 Domain membership and secure channel' {
        It 'is skipped when the server was not domain joined' {
            $baseline.ComputerSystem.PartOfDomain = $false
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-006' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Skipped'
        }

        It 'fails when the server left the domain' {
            $snapshot.ComputerSystem.PartOfDomain = $false
            $snapshot.ComputerSystem.Domain = 'WORKGROUP'
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-006' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Fail'
        }

        It 'fails when the secure channel is broken' {
            $snapshot.ComputerSystem.SecureChannel = $false
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-006' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Fail'
        }

        It 'warns when the secure channel could not be verified' {
            $snapshot.ComputerSystem.SecureChannel = $null
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-006' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Warning'
        }
    }

    Context 'POST-007 Applications are still installed' {
        It 'warns for an application that is no longer installed' {
            $snapshot.Applications = @()
            $result = Invoke-IpuTestCheck -Phase Post -Id 'POST-007' -Snapshot $snapshot -Baseline $baseline
            $result.Status | Should -Be 'Warning'
            $result.Details | Should -Contain 'Contoso Agent'
        }
    }

    Context 'POST-008 Windows is activated' {
        It 'warns when Windows is not activated' {
            $snapshot.Licensing.LicenseStatus = 5
            (Invoke-IpuTestCheck -Phase Post -Id 'POST-008' -Snapshot $snapshot -Baseline $baseline).Status | Should -Be 'Warning'
        }
    }
}
