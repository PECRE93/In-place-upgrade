@{
    RootModule        = 'InPlaceUpgrade.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'da880e91-d4cd-4b10-82ec-579543bdc381'
    Author            = 'PECRE93'
    Description       = 'Readiness checks before, and validation after, an in-place upgrade of Windows Server.'
    PowerShellVersion = '4.0'
    FunctionsToExport = @('Invoke-IpuPreCheck', 'Invoke-IpuPostCheck')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('WindowsServer', 'InPlaceUpgrade', 'Upgrade', 'Validation')
            ProjectUri   = 'https://github.com/PECRE93/In-place-upgrade'
            ReleaseNotes = 'https://github.com/PECRE93/In-place-upgrade/blob/main/CHANGELOG.md'
        }
    }
}
