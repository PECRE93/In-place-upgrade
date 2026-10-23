@{
    Id       = 'POST-007'
    Phase    = 'Post'
    Title    = 'Applications are still installed'
    Requires = @('Baseline.Applications', 'Snapshot.Applications')
    Test     = {
        param($Context)

        $currentNames = @($Context.Snapshot.Applications | ForEach-Object { $_.Name })
        $missing = @($Context.Baseline.Applications | Where-Object {
                $currentNames -notcontains $_.Name -and -not (Test-IpuNameMatch -Name $_.Name -Pattern $Context.Settings.IgnoredApplications)
            } | ForEach-Object { $_.Name })

        if ($missing.Count -gt 0) {
            return @{
                Status  = 'Warning'
                Message = "$($missing.Count) application(s) are no longer registered as installed: $(Format-IpuList -Item $missing). Setup may have updated or removed them."
                Details = $missing
            }
        }
        @{ Status = 'Pass'; Message = "All applications are still installed ($(@($Context.Baseline.Applications).Count) checked)." }
    }
}
