@{
    Id       = 'PRE-004'
    Phase    = 'Pre'
    Title    = 'No pending restart'
    Requires = @('Snapshot.PendingReboot')
    Test     = {
        param($Context)

        $pendingReboot = $Context.Snapshot.PendingReboot
        if ($pendingReboot.IsPending) {
            return @{
                Status  = 'Fail'
                Message = "A restart is pending ($($pendingReboot.Reasons -join ', ')). Restart the server before upgrading."
                Details = $pendingReboot.Reasons
            }
        }
        @{ Status = 'Pass'; Message = 'No restart is pending.' }
    }
}
