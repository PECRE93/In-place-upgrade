function Invoke-IpuPostCheck {
    <#
    .SYNOPSIS
        Verifies a server after an in-place upgrade against the baseline saved by Invoke-IpuPreCheck.

    .DESCRIPTION
        Collects a new snapshot and compares it with the baseline from Invoke-IpuPreCheck: operating
        system version, services, roles and features, listening ports, volumes, domain membership,
        applications and activation. Writes a JSON report to OutputPath.

        Run it from an elevated Windows PowerShell session once the server has finished starting. Allow
        a few minutes after logon so delayed-start services are running.

    .PARAMETER BaselinePath
        Path to the pre-check report to compare with. Defaults to the newest pre-check report for this
        computer in OutputPath.

    .PARAMETER OutputPath
        Folder for the report and where the baseline is looked up. Defaults to %ProgramData%\InPlaceUpgrade.
        A folder that the command creates on a local disk is accessible only to administrators, SYSTEM and you.

    .PARAMETER PassThru
        Returns the report object, for example to act on OverallStatus in a script.

    .OUTPUTS
        None by default. With -PassThru, the report object.

    .EXAMPLE
        Invoke-IpuPostCheck

        Compares the server with the newest baseline in %ProgramData%\InPlaceUpgrade.

    .EXAMPLE
        Invoke-IpuPostCheck -BaselinePath 'D:\Upgrade\SRV01-pre-20261023T080000Z.json'

        Compares the server with a specific baseline.
    #>
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string] $BaselinePath,

        [ValidateNotNullOrEmpty()]
        [string] $OutputPath = (Join-Path -Path $env:ProgramData -ChildPath 'InPlaceUpgrade'),

        [switch] $PassThru
    )

    if (-not $BaselinePath) {
        $latest = Get-ChildItem -Path $OutputPath -Filter "$env:COMPUTERNAME-pre-*.json" -ErrorAction SilentlyContinue |
            Sort-Object -Property Name |
            Select-Object -Last 1
        if (-not $latest) {
            throw "No pre-check report for $env:COMPUTERNAME in '$OutputPath'. Run Invoke-IpuPreCheck before the upgrade, or use -BaselinePath."
        }
        $BaselinePath = $latest.FullName
    }

    $baseline = Get-Content -Path $BaselinePath -Raw -ErrorAction Stop | ConvertFrom-Json
    $baselineSnapshot = Get-IpuProperty -InputObject $baseline -Name 'Snapshot'
    if ((Get-IpuProperty -InputObject $baseline -Name 'Phase') -ne 'Pre' -or $null -eq $baselineSnapshot) {
        throw "'$BaselinePath' is not a pre-check report."
    }
    $baselineComputer = Get-IpuProperty -InputObject $baseline -Name 'ComputerName'
    if ($baselineComputer -ne $env:COMPUTERNAME) {
        throw "'$BaselinePath' was created on $baselineComputer, not on $env:COMPUTERNAME."
    }
    $schemaVersion = Get-IpuProperty -InputObject $baselineSnapshot -Name 'SchemaVersion'
    if ($schemaVersion -ne $script:SnapshotSchemaVersion) {
        throw "'$BaselinePath' has snapshot schema version $schemaVersion, but this module reads version $($script:SnapshotSchemaVersion). Use the module version that created the baseline."
    }

    $report = Invoke-IpuPhase -Phase 'Post' -TargetVersion $baseline.TargetVersion -Baseline $baselineSnapshot -BaselinePath $BaselinePath -OutputPath $OutputPath
    if ($PassThru) {
        $report
    }
}
