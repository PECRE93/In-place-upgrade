# Shared by the test files: dot-source it in BeforeAll. Imports the module from src.

$IpuRepositoryRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
$IpuSourcePath = Join-Path -Path $IpuRepositoryRoot -ChildPath 'src\InPlaceUpgrade'
$IpuManifestPath = Join-Path -Path $IpuSourcePath -ChildPath 'InPlaceUpgrade.psd1'

Import-Module -Name $IpuManifestPath -Force

function New-IpuTestSnapshot {
    # A healthy, domain-joined Windows Server 2016 Azure VM. Tests change only what they need.
    $snapshot = @{
        SchemaVersion    = 1
        ComputerName     = $env:COMPUTERNAME
        CollectedAtUtc   = '2026-10-23T08:00:00.0000000Z'
        OperatingSystem  = @{
            Caption          = 'Microsoft Windows Server 2016 Datacenter'
            Version          = '10.0.14393'
            BuildNumber      = 14393
            EditionId        = 'ServerDatacenter'
            InstallationType = 'Server'
            OSLanguage       = 1033
            SystemDrive      = 'C:'
        }
        ComputerSystem   = @{ Domain = 'contoso.com'; PartOfDomain = $true; DomainRole = 3; SecureChannel = $true }
        Volumes          = @(
            @{ DriveLetter = 'C:'; Label = 'Windows'; FileSystem = 'NTFS'; SizeGB = 127; FreeGB = 80.5 }
            @{ DriveLetter = 'D:'; Label = 'Temporary Storage'; FileSystem = 'NTFS'; SizeGB = 16; FreeGB = 14.2 }
        )
        PendingReboot    = @{ IsPending = $false; Reasons = @() }
        Services         = @(
            @{ Name = 'CDPUserSvc_1a2b3'; DisplayName = 'Connected Devices Platform User Service_1a2b3'; State = 'Running'; StartMode = 'Auto' }
            @{ Name = 'sppsvc'; DisplayName = 'Software Protection'; State = 'Running'; StartMode = 'Auto' }
            @{ Name = 'Spooler'; DisplayName = 'Print Spooler'; State = 'Stopped'; StartMode = 'Manual' }
            @{ Name = 'W32Time'; DisplayName = 'Windows Time'; State = 'Running'; StartMode = 'Auto' }
        )
        Features         = @('FileAndStorage-Services', 'Web-Server')
        Applications     = @(
            @{ Name = 'Contoso Agent'; Version = '1.2.3'; Publisher = 'Contoso' }
        )
        ListeningPorts   = @(
            @{ Port = 135; Process = 'svchost' }
            @{ Port = 443; Process = 'System' }
            @{ Port = 49664; Process = 'lsass' }
        )
        NicTeams         = @()
        Licensing        = @{
            Name          = 'Windows(R), ServerDatacenter edition'
            Description   = 'Windows(R) Operating System, VOLUME_KMSCLIENT channel'
            LicenseStatus = 1
        }
        Azure            = @{ IsAzureVm = $true; ResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm-test'; VmSize = 'Standard_D2s_v5'; Location = 'westeurope'; Zone = '' }
        CollectionErrors = @()
    }
    # Real snapshots are round-tripped through JSON, so give the test data the same shape.
    ConvertTo-Json -InputObject $snapshot -Depth 10 | ConvertFrom-Json
}

function Invoke-IpuTestCheck {
    # Runs the checks of a phase through the module's runner; -Id narrows the result to one check.
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Pre', 'Post')]
        [string] $Phase,

        [Parameter(Mandatory)]
        [object] $Snapshot,

        [object] $Baseline,

        [string] $TargetVersion = '2022',

        [string] $Id = '*'
    )

    $parameters = @{ Phase = $Phase; Snapshot = $Snapshot; Baseline = $Baseline; TargetVersion = $TargetVersion; Id = $Id }
    InModuleScope -ModuleName InPlaceUpgrade -Parameters $parameters -ScriptBlock {
        param($Phase, $Snapshot, $Baseline, $TargetVersion, $Id)

        $context = @{
            Snapshot      = $Snapshot
            Baseline      = $Baseline
            TargetVersion = $TargetVersion
            Settings      = $script:Settings
            WindowsServer = $script:WindowsServer
        }
        Invoke-IpuCheck -Phase $Phase -Context $context | Where-Object { $_.Id -like $Id }
    }
}
