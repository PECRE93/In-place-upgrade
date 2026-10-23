function Show-IpuReport {
    # Prints a color-coded summary for the operator; the JSON report holds the details.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Report,

        [Parameter(Mandatory)]
        [string] $Path
    )

    $colors = @{
        Pass    = 'Green'
        Warning = 'Yellow'
        Fail    = 'Red'
        Error   = 'Magenta'
        Skipped = 'DarkGray'
    }

    Write-Host ''
    Write-Host ('In-place upgrade {0}-check of {1} - target Windows Server {2}' -f $Report.Phase.ToLowerInvariant(), $Report.ComputerName, $Report.TargetVersion)
    Write-Host ''
    foreach ($result in $Report.Results) {
        $label = '[{0}]' -f $result.Status.ToUpperInvariant()
        Write-Host ('  {0,-9} {1,-9} {2}' -f $label, $result.Id, $result.Title) -ForegroundColor $colors[$result.Status]
        Write-Host ('{0}{1}' -f (' ' * 22), $result.Message)
    }
    Write-Host ''
    Write-Host ('Overall: {0}' -f $Report.OverallStatus.ToUpperInvariant()) -ForegroundColor $colors[$Report.OverallStatus]
    Write-Host ('Report:  {0}' -f $Path)
}
