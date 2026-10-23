<#
.SYNOPSIS
    Runs the in-place upgrade pre-check on this server and returns the result as an exit code.

.DESCRIPTION
    Loads the InPlaceUpgrade module and runs Invoke-IpuPreCheck: checks whether the server can be
    upgraded in place to TargetVersion and saves the baseline for Invoke-PostUpgradeCheck.ps1.
    Run it in an elevated Windows PowerShell session.

    The module is loaded from the InPlaceUpgrade folder next to this script (release zip), from
    ..\src\InPlaceUpgrade (repository), or by name from the PowerShell module path.

    Exit codes: 0 = Pass, 1 = Fail or the check could not run, 2 = Warning.

.PARAMETER TargetVersion
    The Windows Server version you are upgrading to.

.PARAMETER OutputPath
    Folder for the report. Defaults to %ProgramData%\InPlaceUpgrade, which survives the upgrade.

.EXAMPLE
    .\Invoke-PreUpgradeCheck.ps1 -TargetVersion 2022

    Checks whether the server can be upgraded to Windows Server 2022 and saves the baseline.

.EXAMPLE
    powershell.exe -NoProfile -File C:\Tools\InPlaceUpgrade\Invoke-PreUpgradeCheck.ps1 -TargetVersion 2025

    Runs the pre-check from another tool, which reads the result from the exit code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('2016', '2019', '2022', '2025')]
    [string] $TargetVersion,

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

$report = Invoke-IpuPreCheck @PSBoundParameters -PassThru
switch ($report.OverallStatus) {
    'Pass' { exit 0 }
    'Warning' { exit 2 }
    default { exit 1 }
}
