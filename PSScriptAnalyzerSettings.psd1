@{
    Severity = @('Error', 'Warning')

    Rules    = @{
        # The module must run on the Windows PowerShell versions that ship with the servers it checks.
        PSUseCompatibleSyntax   = @{
            Enable         = $true
            TargetVersions = @('4.0', '5.1', '7.0')
        }
        PSUseCompatibleCommands = @{
            Enable         = $true
            TargetProfiles = @(
                'win-8_x64_6.3.9600.0_4.0_x64_4.0.30319.42000_framework'           # Windows Server 2012 R2, PowerShell 4.0
                'win-8_x64_10.0.14393.0_5.1.14393.2791_x64_4.0.30319.42000_framework' # Windows Server 2016, PowerShell 5.1
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'  # Windows Server 2019, PowerShell 5.1
            )
            # Pester commands, so editors don't flag the tests.
            IgnoreCommands = @(
                'AfterAll', 'AfterEach', 'BeforeAll', 'BeforeDiscovery', 'BeforeEach', 'Context', 'Describe',
                'InModuleScope', 'It', 'Mock', 'Should'
            )
        }
    }
}
