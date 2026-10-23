BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
}

Describe 'Import-IpuDataFile' {
    It 'loads a data file' {
        $path = Join-Path -Path $TestDrive -ChildPath 'data.psd1'
        Set-Content -Path $path -Value "@{ Number = 1; List = @('a', 'b') }"

        $data = InModuleScope -ModuleName InPlaceUpgrade -Parameters @{ Path = $path } -ScriptBlock {
            param($Path)
            Import-IpuDataFile -Path $Path
        }
        $data.Number | Should -Be 1
        $data.List -join ',' | Should -Be 'a,b'
    }

    It 'refuses a data file that would run code' {
        $path = Join-Path -Path $TestDrive -ChildPath 'code.psd1'
        Set-Content -Path $path -Value '@{ Value = (Get-Date) }'

        {
            InModuleScope -ModuleName InPlaceUpgrade -Parameters @{ Path = $path } -ScriptBlock {
                param($Path)
                Import-IpuDataFile -Path $Path
            }
        } | Should -Throw
    }
}

Describe 'Format-IpuList' {
    It 'joins a short list' {
        InModuleScope -ModuleName InPlaceUpgrade -ScriptBlock { Format-IpuList -Item 'a', 'b' } | Should -Be 'a, b'
    }

    It 'shortens a long list' {
        InModuleScope -ModuleName InPlaceUpgrade -ScriptBlock { Format-IpuList -Item (1..7) } | Should -Be '1, 2, 3, 4, 5 and 2 more'
    }
}
