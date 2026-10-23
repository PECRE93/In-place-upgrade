@{
    Id       = 'POST-004'
    Phase    = 'Post'
    Title    = 'TCP ports are listening again'
    Requires = @('Baseline.ListeningPorts', 'Snapshot.ListeningPorts')
    Test     = {
        param($Context)

        # 49152 and up is the dynamic port range; services get new ports there after every restart.
        $dynamicPortStart = 49152
        $currentPorts = @($Context.Snapshot.ListeningPorts | ForEach-Object { $_.Port })
        $missing = @($Context.Baseline.ListeningPorts | Where-Object {
                $_.Port -lt $dynamicPortStart -and
                $currentPorts -notcontains $_.Port -and
                $Context.Settings.IgnoredPorts -notcontains $_.Port
            } | ForEach-Object { '{0} ({1})' -f $_.Port, $_.Process })

        if ($missing.Count -gt 0) {
            return @{
                Status  = 'Fail'
                Message = "$($missing.Count) TCP port(s) are no longer listening: $(Format-IpuList -Item $missing)."
                Details = $missing
            }
        }
        @{ Status = 'Pass'; Message = 'All TCP ports that listened before the upgrade are listening.' }
    }
}
