@{
    Id       = 'PRE-004'
    Phase    = 'Pre'
    Title    = 'No pending restart'
    Requires = @('Snapshot.PendingReboot')
    Test     = {
        param($Context)

        $reasons = @($Context.Snapshot.PendingReboot.Reasons)
        # Antivirus and similar software often add file rename operations again right after a restart.
        $blocking = @($reasons | Where-Object { $_ -ne 'Pending file rename operations' })
        if ($blocking.Count -gt 0) {
            return @{
                Status  = 'Fail'
                Message = "A restart is pending ($($reasons -join ', ')). Restart the server before upgrading."
                Details = $reasons
            }
        }
        if ($reasons.Count -gt 0) {
            return @{ Status = 'Warning'; Message = 'File rename operations are pending. Restart the server before upgrading. If they are back right after a restart, software such as antivirus adds them and they are usually harmless.' }
        }
        @{ Status = 'Pass'; Message = 'No restart is pending.' }
    }
}
