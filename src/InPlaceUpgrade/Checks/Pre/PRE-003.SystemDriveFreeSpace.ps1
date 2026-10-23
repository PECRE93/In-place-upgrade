@{
    Id       = 'PRE-003'
    Phase    = 'Pre'
    Title    = 'Free space on the system drive'
    Requires = @('Snapshot.OperatingSystem', 'Snapshot.Volumes')
    Test     = {
        param($Context)

        $drive = $Context.Snapshot.OperatingSystem.SystemDrive
        $minimum = $Context.Settings.MinimumSystemDriveFreeGB
        $volume = @($Context.Snapshot.Volumes | Where-Object { $_.DriveLetter -eq $drive }) | Select-Object -First 1

        if (-not $volume) {
            return @{ Status = 'Fail'; Message = "The system drive $drive was not found." }
        }
        if ($volume.FreeGB -lt $minimum) {
            return @{ Status = 'Fail'; Message = "$drive has $($volume.FreeGB) GB free; at least $minimum GB is required. Free up space or expand the OS disk." }
        }
        @{ Status = 'Pass'; Message = "$drive has $($volume.FreeGB) GB free (minimum $minimum GB)." }
    }
}
