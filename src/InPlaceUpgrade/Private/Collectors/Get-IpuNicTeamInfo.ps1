function Get-IpuNicTeamInfo {
    # Names of the LBFO NIC teams.
    [CmdletBinding()]
    param()

    $teams = Get-NetLbfoTeam -ErrorAction Stop | ForEach-Object { $_.Name }
    , @($teams)
}
