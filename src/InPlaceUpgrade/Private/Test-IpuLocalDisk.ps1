function Test-IpuLocalDisk {
    # True for a full path on a local fixed disk, false for shares and mapped drives.
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $root = [System.IO.Path]::GetPathRoot($Path)
    if ($root -notmatch '^[a-z]:\\$') {
        return $false
    }
    (New-Object -TypeName System.IO.DriveInfo -ArgumentList $root).DriveType -eq 'Fixed'
}
