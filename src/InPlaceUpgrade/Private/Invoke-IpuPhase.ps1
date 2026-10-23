function Invoke-IpuPhase {
    # The flow shared by the pre- and post-check: snapshot, evaluate, save and show the report.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Pre', 'Post')]
        [string] $Phase,

        [Parameter(Mandatory)]
        [string] $TargetVersion,

        [Parameter(Mandatory)]
        [string] $OutputPath,

        [object] $Baseline,

        [string] $BaselinePath
    )

    # Round-trip through JSON so the live snapshot has exactly the shape of a baseline read from disk.
    $snapshot = ConvertTo-Json -InputObject (Get-IpuSnapshot) -Depth 10 | ConvertFrom-Json

    $context = @{
        Snapshot      = $snapshot
        Baseline      = $Baseline
        TargetVersion = $TargetVersion
        Settings      = $script:Settings
        WindowsServer = $script:WindowsServer
    }
    $results = @(Invoke-IpuCheck -Phase $Phase -Context $context)

    $statuses = @($results | ForEach-Object { $_.Status })
    $overallStatus = 'Pass'
    if ($statuses -contains 'Fail' -or $statuses -contains 'Error') {
        $overallStatus = 'Fail'
    }
    elseif ($statuses -contains 'Warning') {
        $overallStatus = 'Warning'
    }

    $report = [pscustomobject]@{
        Tool          = 'InPlaceUpgrade'
        ToolVersion   = $MyInvocation.MyCommand.Module.Version.ToString()
        Phase         = $Phase
        ComputerName  = $snapshot.ComputerName
        TargetVersion = $TargetVersion
        CreatedAtUtc  = [DateTime]::UtcNow.ToString('o')
        OverallStatus = $overallStatus
        BaselinePath  = $BaselinePath
        Results       = $results
        Snapshot      = $snapshot
    }

    $path = Save-IpuReport -Report $report -OutputPath $OutputPath
    Show-IpuReport -Report $report -Path $path
    $report
}
