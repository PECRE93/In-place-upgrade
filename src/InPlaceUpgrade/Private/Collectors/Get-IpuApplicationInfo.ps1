function Get-IpuApplicationInfo {
    # Applications as listed in Programs and Features (64- and 32-bit uninstall keys).
    [CmdletBinding()]
    param()

    $uninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $applications = foreach ($entry in (Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue)) {
        $name = Get-IpuProperty -InputObject $entry -Name 'DisplayName'
        $isHidden = (Get-IpuProperty -InputObject $entry -Name 'SystemComponent') -eq 1
        $isUpdate = [bool](Get-IpuProperty -InputObject $entry -Name 'ParentKeyName')
        if (-not $name -or $isHidden -or $isUpdate) {
            continue
        }
        [pscustomobject]@{
            Name      = $name
            Version   = Get-IpuProperty -InputObject $entry -Name 'DisplayVersion'
            Publisher = Get-IpuProperty -InputObject $entry -Name 'Publisher'
        }
    }
    , @($applications | Sort-Object -Property Name -Unique)
}
