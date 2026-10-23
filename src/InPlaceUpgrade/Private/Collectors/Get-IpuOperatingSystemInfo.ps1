function Get-IpuOperatingSystemInfo {
    [CmdletBinding()]
    param()

    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $currentVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop

    [pscustomobject]@{
        Caption          = $os.Caption
        Version          = $os.Version
        BuildNumber      = [int]$os.BuildNumber
        EditionId        = Get-IpuProperty -InputObject $currentVersion -Name 'EditionID'
        InstallationType = Get-IpuProperty -InputObject $currentVersion -Name 'InstallationType'
        OSLanguage       = [int]$os.OSLanguage
        SystemDrive      = $os.SystemDrive
    }
}
