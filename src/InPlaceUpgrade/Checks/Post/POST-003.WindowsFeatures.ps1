@{
    Id       = 'POST-003'
    Phase    = 'Post'
    Title    = 'Roles and features are still installed'
    Requires = @('Baseline.Features', 'Snapshot.Features')
    Test     = {
        param($Context)

        $installed = @($Context.Snapshot.Features)
        $missing = @($Context.Baseline.Features | Where-Object {
                $installed -notcontains $_ -and -not (Test-IpuNameMatch -Name $_ -Pattern $Context.Settings.IgnoredFeatures)
            })

        if ($missing.Count -gt 0) {
            return @{
                Status  = 'Fail'
                Message = "$($missing.Count) role(s) or feature(s) are no longer installed: $(Format-IpuList -Item $missing)."
                Details = $missing
            }
        }
        @{ Status = 'Pass'; Message = "All roles and features from before the upgrade are installed ($(@($Context.Baseline.Features).Count) checked)." }
    }
}
