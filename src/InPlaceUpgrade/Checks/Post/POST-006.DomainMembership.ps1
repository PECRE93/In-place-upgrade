@{
    Id       = 'POST-006'
    Phase    = 'Post'
    Title    = 'Domain membership and secure channel'
    Requires = @('Baseline.ComputerSystem', 'Snapshot.ComputerSystem')
    Test     = {
        param($Context)

        $before = $Context.Baseline.ComputerSystem
        $after = $Context.Snapshot.ComputerSystem

        if (-not $before.PartOfDomain) {
            return @{ Status = 'Skipped'; Message = 'The server was not domain joined before the upgrade.' }
        }
        if (-not $after.PartOfDomain -or $after.Domain -ne $before.Domain) {
            return @{ Status = 'Fail'; Message = "The server was joined to $($before.Domain) but is now in '$($after.Domain)'." }
        }
        if ($after.SecureChannel -eq $false) {
            return @{ Status = 'Fail'; Message = "The secure channel to $($after.Domain) is broken. Repair it with Test-ComputerSecureChannel -Repair." }
        }
        if ($null -eq $after.SecureChannel) {
            return @{ Status = 'Warning'; Message = "Joined to $($after.Domain), but the secure channel could not be verified." }
        }
        @{ Status = 'Pass'; Message = "Joined to $($after.Domain) with a working secure channel." }
    }
}
