function Protect-IpuDirectory {
    # Limits a new local report folder to administrators, SYSTEM and the current user. Under ProgramData,
    # any local user could otherwise add files to it, such as a fake baseline for the post-check.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.DirectoryInfo] $Directory
    )

    # Shares and mapped drives keep their permissions.
    $root = $Directory.Root.FullName
    if ($root -notmatch '^[a-z]:\\$' -or (New-Object -TypeName System.IO.DriveInfo -ArgumentList $root).DriveType -ne 'Fixed') {
        return
    }

    $acl = Get-Acl -Path $Directory.FullName
    $acl.SetAccessRuleProtection($true, $false)
    # Administrators, SYSTEM and the account running the tool.
    foreach ($sid in @('S-1-5-32-544', 'S-1-5-18', [Security.Principal.WindowsIdentity]::GetCurrent().User.Value)) {
        $identity = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $sid
        $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $identity, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
        $acl.AddAccessRule($rule)
    }
    Set-Acl -Path $Directory.FullName -AclObject $acl
}
