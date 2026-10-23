<#
.SYNOPSIS
    Lints, tests and packages the InPlaceUpgrade module.

.DESCRIPTION
    Bootstrap  Installs the pinned versions of Pester and PSScriptAnalyzer for the current user.
    Analyze    Runs PSScriptAnalyzer on src with PSScriptAnalyzerSettings.psd1.
    Test       Runs the Pester tests and writes out/testResults.xml.
    Package    Writes out/InPlaceUpgrade-<version>.zip and out/release-notes.md (taken from CHANGELOG.md).

.EXAMPLE
    ./build.ps1 -Task Bootstrap, Analyze, Test
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCommands', '', Justification = 'Runs on build agents, not on the servers.')]
[CmdletBinding()]
param(
    [ValidateSet('Bootstrap', 'Analyze', 'Test', 'Package')]
    [string[]] $Task = @('Analyze', 'Test')
)

$ErrorActionPreference = 'Stop'

# Pinned for reproducible builds; update them through a pull request.
$requiredModules = [ordered]@{
    Pester           = '6.2.0'
    PSScriptAnalyzer = '1.25.0'
}
$moduleName = 'InPlaceUpgrade'
$sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "src\$moduleName"
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath 'out'

function Import-BuildModule {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )
    Import-Module -Name $Name -RequiredVersion $requiredModules[$Name] -Force
}

if ($Task -contains 'Bootstrap') {
    foreach ($name in $requiredModules.Keys) {
        $version = $requiredModules[$name]
        if (Get-Module -ListAvailable -Name $name | Where-Object { $_.Version -eq [version]$version }) {
            continue
        }
        Write-Host "Installing $name $version"
        if (Get-Command -Name 'Install-PSResource' -ErrorAction SilentlyContinue) {
            Install-PSResource -Name $name -Version $version -Scope CurrentUser -TrustRepository -Quiet
        }
        else {
            Install-Module -Name $name -RequiredVersion $version -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber
        }
    }
}

if ($Task -contains 'Analyze') {
    Import-BuildModule -Name PSScriptAnalyzer
    $settingsPath = Join-Path -Path $PSScriptRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
    $findings = @(Invoke-ScriptAnalyzer -Path $sourcePath -Recurse -Settings $settingsPath)
    if ($findings.Count -gt 0) {
        $findings | Format-Table -Property Severity, RuleName, ScriptName, Line, Message -AutoSize -Wrap | Out-String -Width 200 | Write-Host
        throw "PSScriptAnalyzer reported $($findings.Count) finding(s)."
    }
    Write-Host 'PSScriptAnalyzer: no findings.'
}

if ($Task -contains 'Test') {
    Import-BuildModule -Name Pester
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
    $configuration = New-PesterConfiguration
    $configuration.Run.Path = Join-Path -Path $PSScriptRoot -ChildPath 'tests'
    $configuration.Run.Throw = $true
    $configuration.Output.Verbosity = 'Detailed'
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputPath = Join-Path -Path $outputPath -ChildPath 'testResults.xml'
    Invoke-Pester -Configuration $configuration
}

if ($Task -contains 'Package') {
    $version = (Test-ModuleManifest -Path (Join-Path -Path $sourcePath -ChildPath "$moduleName.psd1")).Version.ToString()
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null

    $zipPath = Join-Path -Path $outputPath -ChildPath "$moduleName-$version.zip"
    Compress-Archive -Path $sourcePath -DestinationPath $zipPath -Force

    # The release notes are this version's section of CHANGELOG.md.
    $changelog = @(Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'CHANGELOG.md'))
    $start = -1
    $end = $changelog.Count
    for ($i = 0; $i -lt $changelog.Count; $i++) {
        if ($start -lt 0) {
            if ($changelog[$i] -match ('^## \[' + [regex]::Escape($version) + '\]')) {
                $start = $i
            }
        }
        elseif ($changelog[$i] -match '^## \[' -or $changelog[$i] -match '^\[[^\]]+\]: ') {
            $end = $i
            break
        }
    }
    if ($start -lt 0 -or $end -le $start + 1) {
        throw "CHANGELOG.md has no entries for version $version."
    }
    $notes = ($changelog[($start + 1)..($end - 1)] -join [Environment]::NewLine).Trim()
    Set-Content -Path (Join-Path -Path $outputPath -ChildPath 'release-notes.md') -Value $notes -Encoding UTF8
    Write-Host "Packaged $zipPath"
}
