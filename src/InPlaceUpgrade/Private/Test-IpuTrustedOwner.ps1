function Test-IpuTrustedOwner {
    # True when Administrators, SYSTEM or the current user owns the file or folder; any other owner could change it.
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $fullName = (Get-Item -LiteralPath $Path -Force -ErrorAction Stop).FullName
    # Owners on shares and mapped drives are accounts of the file server, so they can't be judged here.
    if (-not (Test-IpuLocalDisk -Path $fullName)) {
        return $true
    }
    $owner = (Get-Acl -LiteralPath $fullName -ErrorAction Stop).GetOwner([System.Security.Principal.SecurityIdentifier]).Value
    @('S-1-5-32-544', 'S-1-5-18', [Security.Principal.WindowsIdentity]::GetCurrent().User.Value) -contains $owner
}
