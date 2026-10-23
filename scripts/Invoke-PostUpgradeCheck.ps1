<#
.SYNOPSIS
    Runs the in-place upgrade post-check on this server and returns the result as an exit code.

.DESCRIPTION
    Loads the InPlaceUpgrade module and runs Invoke-IpuPostCheck: compares the upgraded server with
    the baseline saved by Invoke-PreUpgradeCheck.ps1. Run it in an elevated Windows PowerShell
    session once the server has been up for a few minutes.

    The module is loaded from the InPlaceUpgrade folder next to this script (release zip), from
    ..\src\InPlaceUpgrade (repository), or by name from the PowerShell module path.

    Exit codes: 0 = Pass, 1 = Fail or the check could not run, 2 = Warning.

.PARAMETER BaselinePath
    Path to the pre-check report to compare with. Defaults to the newest pre-check report for this
    computer in OutputPath.

.PARAMETER OutputPath
    Folder for the report, and where the baseline is looked up. Defaults to %ProgramData%\InPlaceUpgrade.

.EXAMPLE
    .\Invoke-PostUpgradeCheck.ps1

    Compares the server with the newest baseline in %ProgramData%\InPlaceUpgrade.

.EXAMPLE
    powershell.exe -NoProfile -File C:\Tools\InPlaceUpgrade\Invoke-PostUpgradeCheck.ps1

    Runs the post-check from another tool, which reads the result from the exit code.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $BaselinePath,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

# Any error must end the script with exit code 1 instead of falling through to exit code 0.
$ErrorActionPreference = 'Stop'

# The module sits next to this script in the release zip, and in ..\src in the repository.
$manifest = @(
    (Join-Path -Path $PSScriptRoot -ChildPath 'InPlaceUpgrade\InPlaceUpgrade.psd1')
    (Join-Path -Path $PSScriptRoot -ChildPath '..\src\InPlaceUpgrade\InPlaceUpgrade.psd1')
) | Where-Object { Test-Path -Path $_ } | Select-Object -First 1
if (-not $manifest) {
    $manifest = 'InPlaceUpgrade'
}
Import-Module -Name $manifest

$report = Invoke-IpuPostCheck @PSBoundParameters -PassThru
switch ($report.OverallStatus) {
    'Pass' { exit 0 }
    'Warning' { exit 2 }
    default { exit 1 }
}
