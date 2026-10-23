function Get-IpuComputerSystemInfo {
    [CmdletBinding()]
    param()

    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop

    # $null means "not domain joined" or "could not be verified"; POST-006 tells them apart.
    $secureChannel = $null
    if ($computerSystem.PartOfDomain) {
        try {
            # [bool] unwraps the object PowerShell 7 returns through its Windows PowerShell compatibility session.
            $secureChannel = [bool](Test-ComputerSecureChannel -ErrorAction Stop)
        }
        catch {
            Write-Warning -Message "Could not verify the domain secure channel: $($_.Exception.Message)"
        }
    }

    [pscustomobject]@{
        Domain        = $computerSystem.Domain
        PartOfDomain  = [bool]$computerSystem.PartOfDomain
        DomainRole    = [int]$computerSystem.DomainRole
        SecureChannel = $secureChannel
    }
}
