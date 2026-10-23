@{
    Id       = 'PRE-005'
    Phase    = 'Pre'
    Title    = 'Not a failover cluster node'
    Requires = @('Snapshot.Services')
    Test     = {
        param($Context)

        $clusterService = @($Context.Snapshot.Services | Where-Object { $_.Name -eq 'ClusSvc' -and $_.State -eq 'Running' })
        if ($clusterService.Count -gt 0) {
            return @{ Status = 'Fail'; Message = 'The server is a failover cluster node. Use a cluster OS rolling upgrade instead of an in-place upgrade.' }
        }
        @{ Status = 'Pass'; Message = 'The Cluster service is not running.' }
    }
}
