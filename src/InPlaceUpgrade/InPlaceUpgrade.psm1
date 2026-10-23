Set-StrictMode -Version Latest

$privateFiles = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private') -Filter '*.ps1' -Recurse)
$publicFiles = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter '*.ps1' -Recurse)
foreach ($file in ($privateFiles + $publicFiles)) {
    . $file.FullName
}

# Bump together with the MAJOR version when the snapshot format changes incompatibly (docs/adr/0004).
$script:SnapshotSchemaVersion = 1
$script:Settings = Import-IpuDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Data\Settings.psd1')
$script:WindowsServer = Import-IpuDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Data\WindowsServer.psd1')

# Each file under Checks returns one check definition (docs/adr/0003).
$script:Checks = @(
    Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Checks') -Filter '*.ps1' -Recurse |
        Sort-Object -Property Name |
        ForEach-Object { & $_.FullName }
)

Export-ModuleMember -Function ($publicFiles | ForEach-Object { $_.BaseName })
