function Get-IpuServerVersion {
    # Maps an OS build number to a Windows Server version, e.g. 17763 -> '2019'. $null when unknown.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [int] $BuildNumber,

        [Parameter(Mandatory)]
        [object[]] $Releases
    )

    foreach ($release in $Releases) {
        if ($release.Build -eq $BuildNumber) {
            return $release.Version
        }
    }
    return $null
}
