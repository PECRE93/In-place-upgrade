function Save-IpuReport {
    # Writes the report as <computer>-<phase>-<UTC timestamp>.json and returns the path.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [object] $Report,

        [Parameter(Mandatory)]
        [string] $OutputPath
    )

    if (-not (Test-Path -Path $OutputPath)) {
        Protect-IpuDirectory -Directory (New-Item -Path $OutputPath -ItemType Directory -Force -ErrorAction Stop)
    }

    $fileName = '{0}-{1}-{2}.json' -f $Report.ComputerName, $Report.Phase.ToLowerInvariant(), [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
    $path = Join-Path -Path $OutputPath -ChildPath $fileName
    ConvertTo-Json -InputObject $Report -Depth 10 | Set-Content -Path $path -Encoding UTF8 -ErrorAction Stop
    $path
}
