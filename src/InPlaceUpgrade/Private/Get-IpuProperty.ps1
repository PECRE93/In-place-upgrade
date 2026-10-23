function Get-IpuProperty {
    # Reads an optional property without tripping StrictMode; returns $null when it doesn't exist.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($null -eq $InputObject) {
        return $null
    }
    $property = $InputObject.PSObject.Properties[$Name]
    if (-not $property) {
        return $null
    }
    # The comma stops PowerShell from unrolling arrays, which would turn an empty array into $null.
    return , $property.Value
}
