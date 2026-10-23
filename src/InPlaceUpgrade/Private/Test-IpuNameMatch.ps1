function Test-IpuNameMatch {
    # True when Name matches any of the wildcard patterns (case-insensitive).
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()]
        [string] $Name,

        [AllowNull()]
        [object[]] $Pattern
    )

    foreach ($item in @($Pattern)) {
        if ($null -ne $item -and $Name -like $item) {
            return $true
        }
    }
    return $false
}
