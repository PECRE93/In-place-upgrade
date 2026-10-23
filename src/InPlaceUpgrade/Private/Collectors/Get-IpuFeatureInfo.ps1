function Get-IpuFeatureInfo {
    # Names of the installed roles and features, e.g. 'Web-Server'. Needs the ServerManager module.
    [CmdletBinding()]
    param()

    $installed = Get-WindowsFeature -ErrorAction Stop | Where-Object { $_.Installed } | ForEach-Object { $_.Name }
    , @($installed | Sort-Object)
}
