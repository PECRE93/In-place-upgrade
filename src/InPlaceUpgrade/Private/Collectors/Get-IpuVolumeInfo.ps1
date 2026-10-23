function Get-IpuVolumeInfo {
    [CmdletBinding()]
    param()

    # DriveType 3 = local disk.
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction Stop
    $volumes = foreach ($disk in $disks) {
        [pscustomobject]@{
            DriveLetter = $disk.DeviceID
            Label       = $disk.VolumeName
            FileSystem  = $disk.FileSystem
            SizeGB      = [math]::Round($disk.Size / 1GB, 1)
            FreeGB      = [math]::Round($disk.FreeSpace / 1GB, 1)
        }
    }
    # The comma stops PowerShell from unrolling the array into a single item or $null.
    , @($volumes | Sort-Object -Property DriveLetter)
}
