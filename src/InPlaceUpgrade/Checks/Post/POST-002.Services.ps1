@{
    Id       = 'POST-002'
    Phase    = 'Post'
    Title    = 'Automatic services are running'
    Requires = @('Baseline.Services', 'Snapshot.Services')
    Test     = {
        param($Context)

        $current = @{}
        foreach ($service in $Context.Snapshot.Services) {
            $current[$service.Name] = $service
        }

        $problems = @(foreach ($service in $Context.Baseline.Services) {
                if ($service.StartMode -ne 'Auto' -or $service.State -ne 'Running') {
                    continue
                }
                if (Test-IpuNameMatch -Name $service.Name -Pattern $Context.Settings.IgnoredServices) {
                    continue
                }
                # Per-user service instances (e.g. CDPUserSvc_1a2b3) get a new suffix at every logon.
                if ($service.Name -match '_[0-9a-f]+$' -and $service.DisplayName -like "*$($Matches[0])") {
                    continue
                }

                $after = $current[$service.Name]
                if (-not $after) {
                    '{0} (missing)' -f $service.Name
                }
                elseif ($after.State -ne 'Running') {
                    '{0} ({1})' -f $service.Name, $after.State
                }
            })

        if ($problems.Count -gt 0) {
            return @{
                Status  = 'Fail'
                Message = "$($problems.Count) service(s) that ran before the upgrade are not running: $(Format-IpuList -Item $problems)."
                Details = $problems
            }
        }
        @{ Status = 'Pass'; Message = 'All automatic services that ran before the upgrade are running.' }
    }
}
