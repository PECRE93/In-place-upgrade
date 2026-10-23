@{
    Id       = 'POST-005'
    Phase    = 'Post'
    Title    = 'Volumes and drive letters are unchanged'
    Requires = @('Baseline.Volumes', 'Snapshot.Volumes')
    Test     = {
        param($Context)

        $current = @{}
        foreach ($volume in $Context.Snapshot.Volumes) {
            $current[$volume.DriveLetter] = $volume
        }

        $problems = @(foreach ($volume in $Context.Baseline.Volumes) {
                $after = $current[$volume.DriveLetter]
                if (-not $after) {
                    "{0} '{1}' is missing" -f $volume.DriveLetter, $volume.Label
                }
                elseif ("$($after.Label)" -ne "$($volume.Label)") {
                    "{0} was relabeled from '{1}' to '{2}'" -f $volume.DriveLetter, $volume.Label, $after.Label
                }
            })

        if ($problems.Count -gt 0) {
            return @{
                Status  = 'Fail'
                Message = "Volumes changed: $(Format-IpuList -Item $problems)."
                Details = $problems
            }
        }
        @{ Status = 'Pass'; Message = "All volumes kept their drive letters and labels ($(@($Context.Baseline.Volumes).Count) checked)." }
    }
}
