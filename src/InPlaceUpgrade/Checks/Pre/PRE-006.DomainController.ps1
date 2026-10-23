@{
    Id       = 'PRE-006'
    Phase    = 'Pre'
    Title    = 'Not a domain controller'
    Requires = @('Snapshot.ComputerSystem')
    Test     = {
        param($Context)

        # Win32_ComputerSystem.DomainRole: 4 = backup domain controller, 5 = primary domain controller.
        if ($Context.Snapshot.ComputerSystem.DomainRole -ge 4) {
            return @{ Status = 'Warning'; Message = 'The server is a domain controller. Microsoft recommends promoting a new domain controller on a clean install instead of upgrading in place.' }
        }
        @{ Status = 'Pass'; Message = 'The server is not a domain controller.' }
    }
}
