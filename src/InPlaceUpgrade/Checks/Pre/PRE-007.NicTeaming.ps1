@{
    Id       = 'PRE-007'
    Phase    = 'Pre'
    Title    = 'NIC Teaming not in use'
    Requires = @('Snapshot.NicTeams')
    Test     = {
        param($Context)

        $teams = @($Context.Snapshot.NicTeams)
        if ($teams.Count -gt 0) {
            return @{
                Status  = 'Fail'
                Message = "NIC Teaming is configured ($($teams -join ', ')). Disable it before the upgrade and re-enable it afterwards."
                Details = $teams
            }
        }
        @{ Status = 'Pass'; Message = 'No NIC teams are configured.' }
    }
}
