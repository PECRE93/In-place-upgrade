BeforeDiscovery {
    $repositoryRoot = Join-Path -Path $PSScriptRoot -ChildPath '..'
    $checkFiles = @(
        Get-ChildItem -Path (Join-Path -Path $repositoryRoot -ChildPath 'src\InPlaceUpgrade\Checks') -Filter '*.ps1' -Recurse |
            ForEach-Object { @{ Name = $_.Name; Path = $_.FullName; Phase = $_.Directory.Name } }
    )
    $publicFunctions = @(
        Get-ChildItem -Path (Join-Path -Path $repositoryRoot -ChildPath 'src\InPlaceUpgrade\Public') -Filter '*.ps1' |
            ForEach-Object { $_.BaseName }
    )
}

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
}

Describe 'Module' {
    It 'has a valid manifest' {
        { Test-ModuleManifest -Path $IpuManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'exports exactly the functions in Public' {
        $expected = @(Get-ChildItem -Path (Join-Path -Path $IpuSourcePath -ChildPath 'Public') -Filter '*.ps1' | ForEach-Object { $_.BaseName } | Sort-Object) -join ','
        @((Test-ModuleManifest -Path $IpuManifestPath).ExportedFunctions.Keys | Sort-Object) -join ',' | Should -Be $expected
        @(Get-Command -Module InPlaceUpgrade | ForEach-Object { $_.Name } | Sort-Object) -join ',' | Should -Be $expected
    }

    It 'has a CHANGELOG entry for its version' {
        $version = (Test-ModuleManifest -Path $IpuManifestPath).Version.ToString()
        $changelog = Get-Content -Path (Join-Path -Path $IpuRepositoryRoot -ChildPath 'CHANGELOG.md') -Raw
        $changelog | Should -Match ('(?m)^## \[' + [regex]::Escape($version) + '\] - \d{4}-\d{2}-\d{2}')
    }

    It 'loads one check per file under Checks, with unique IDs' {
        $checks = @(InModuleScope -ModuleName InPlaceUpgrade -ScriptBlock { $script:Checks })
        $files = @(Get-ChildItem -Path (Join-Path -Path $IpuSourcePath -ChildPath 'Checks') -Filter '*.ps1' -Recurse)
        $checks.Count | Should -Be $files.Count
        @($checks | ForEach-Object { $_.Id } | Sort-Object -Unique).Count | Should -Be $checks.Count
    }
}

Describe 'Help for <_>' -ForEach $publicFunctions {
    BeforeAll {
        $commandName = $_
        $help = Get-Help -Name $commandName -Full
    }

    It 'has a synopsis, a description and an example' {
        $help.Synopsis | Should -Not -BeNullOrEmpty
        $help.Description | Should -Not -BeNullOrEmpty
        @($help.Examples.Example).Count | Should -BeGreaterThan 0
    }

    It 'describes every parameter' {
        $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
        $parameters = @((Get-Command -Name $commandName).Parameters.Keys | Where-Object { $commonParameters -notcontains $_ })
        foreach ($parameter in $parameters) {
            $parameterHelp = $help.Parameters.Parameter | Where-Object { $_.Name -eq $parameter }
            $parameterHelp.Description | Should -Not -BeNullOrEmpty -Because "-$parameter needs a .PARAMETER description"
        }
    }
}

Describe 'Check <Name>' -ForEach $checkFiles {
    BeforeAll {
        $definition = & $Path
    }

    It 'defines Id, Phase, Title, Requires and Test' {
        $definition | Should -BeOfType [hashtable]
        @($definition.Keys | Sort-Object) -join ',' | Should -Be 'Id,Phase,Requires,Test,Title'
        $definition.Test | Should -BeOfType [scriptblock]
    }

    It 'matches its folder and file name' {
        $definition.Phase | Should -Be $Phase
        $definition.Id | Should -Match ('^' + $Phase.ToUpperInvariant() + '-\d{3}$')
        $Name | Should -BeLike "$($definition.Id).*.ps1"
    }

    It 'requires only data its phase has' {
        foreach ($requirement in $definition.Requires) {
            $requirement | Should -Match '^(Snapshot|Baseline)\.\w+$'
            if ($Phase -eq 'Pre') {
                $requirement | Should -Not -BeLike 'Baseline.*'
            }
        }
    }

    It 'is documented in docs/checks.md' {
        $catalogue = Get-Content -Path (Join-Path -Path $IpuRepositoryRoot -ChildPath 'docs\checks.md') -Raw
        $catalogue | Should -Match ('\| ' + $definition.Id + ' \|')
    }
}
