function Invoke-IpuPreCheck {
    <#
    .SYNOPSIS
        Checks whether this server is ready for an in-place upgrade and saves a baseline.

    .DESCRIPTION
        Collects a snapshot of the server (operating system, roles and features, services, applications,
        listening ports, volumes, licensing, Azure metadata), runs the pre-upgrade checks against it and
        writes a JSON report to OutputPath. The report also holds the baseline that Invoke-IpuPostCheck
        compares the upgraded server with.

        Run it from an elevated Windows PowerShell session. The command only reads from the server; the
        report is the only thing it writes.

    .PARAMETER TargetVersion
        The Windows Server version you are upgrading to.

    .PARAMETER OutputPath
        Folder for the report. The default, %ProgramData%\InPlaceUpgrade, survives the upgrade.

    .PARAMETER PassThru
        Returns the report object, for example to act on OverallStatus in a script.

    .OUTPUTS
        None by default. With -PassThru, the report object.

    .EXAMPLE
        Invoke-IpuPreCheck -TargetVersion 2022

        Checks whether the server can be upgraded to Windows Server 2022 and saves the baseline.

    .EXAMPLE
        $report = Invoke-IpuPreCheck -TargetVersion 2025 -PassThru
        if ($report.OverallStatus -eq 'Fail') { throw 'The server is not ready for the upgrade.' }

        Stops a script when a check failed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('2016', '2019', '2022', '2025')]
        [string] $TargetVersion,

        [ValidateNotNullOrEmpty()]
        [string] $OutputPath = (Join-Path -Path $env:ProgramData -ChildPath 'InPlaceUpgrade'),

        [switch] $PassThru
    )

    $report = Invoke-IpuPhase -Phase 'Pre' -TargetVersion $TargetVersion -OutputPath $OutputPath
    if ($PassThru) {
        $report
    }
}
