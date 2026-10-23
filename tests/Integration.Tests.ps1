BeforeDiscovery {
    # The collectors need Windows Server (ProductType 1 is a workstation) and an elevated session.
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $principal = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList ([Security.Principal.WindowsIdentity]::GetCurrent())
    $canRun = $os.ProductType -ne 1 -and $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
}

Describe 'Get-IpuSnapshot on this server' -Tag 'Integration' -Skip:(-not $canRun) {
    BeforeAll {
        $snapshot = InModuleScope -ModuleName InPlaceUpgrade -ScriptBlock { Get-IpuSnapshot }
    }

    It 'collects every section without errors' {
        $snapshot.CollectionErrors | Should -BeNullOrEmpty
    }

    It 'collects the operating system, services and listening ports' {
        $snapshot.OperatingSystem.BuildNumber | Should -BeGreaterThan 9000
        @($snapshot.Services).Count | Should -BeGreaterThan 10
        @($snapshot.ListeningPorts).Count | Should -BeGreaterThan 0
    }

    It 'can be saved as JSON and read back' {
        { ConvertTo-Json -InputObject $snapshot -Depth 10 | ConvertFrom-Json } | Should -Not -Throw
    }
}
