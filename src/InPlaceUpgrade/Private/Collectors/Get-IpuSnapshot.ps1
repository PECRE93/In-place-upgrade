function Get-IpuSnapshot {
    # Collects the facts every check evaluates. A collector that fails leaves its section $null and is
    # recorded in CollectionErrors; the remaining sections are still collected.
    [CmdletBinding()]
    param()

    if (-not (Test-IpuAdministrator)) {
        throw 'Run this command from an elevated PowerShell session (Run as administrator).'
    }

    $collectors = [ordered]@{
        OperatingSystem = 'Get-IpuOperatingSystemInfo'
        ComputerSystem  = 'Get-IpuComputerSystemInfo'
        Volumes         = 'Get-IpuVolumeInfo'
        PendingReboot   = 'Get-IpuPendingRebootInfo'
        Services        = 'Get-IpuServiceInfo'
        Features        = 'Get-IpuFeatureInfo'
        Applications    = 'Get-IpuApplicationInfo'
        ListeningPorts  = 'Get-IpuListeningPortInfo'
        NicTeams        = 'Get-IpuNicTeamInfo'
        Licensing       = 'Get-IpuLicensingInfo'
        Azure           = 'Get-IpuAzureInfo'
    }

    $snapshot = [ordered]@{
        SchemaVersion  = $script:SnapshotSchemaVersion
        ComputerName   = $env:COMPUTERNAME
        CollectedAtUtc = [DateTime]::UtcNow.ToString('o')
    }
    $collectionErrors = @()

    foreach ($section in $collectors.Keys) {
        Write-Verbose -Message "Collecting $section"
        try {
            $snapshot[$section] = & $collectors[$section]
        }
        catch {
            $snapshot[$section] = $null
            $collectionErrors += [pscustomobject]@{ Section = $section; Message = $_.Exception.Message }
            Write-Warning -Message "Could not collect ${section}: $($_.Exception.Message)"
        }
    }

    $snapshot['CollectionErrors'] = $collectionErrors
    [pscustomobject]$snapshot
}
