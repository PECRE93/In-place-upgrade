# In-place upgrade checks

Pre- and post-checks for in-place upgrades of Windows Server.

Run `Invoke-IpuPreCheck` before the upgrade to find out whether the upgrade is supported and the server is ready, and to save a baseline. Run `Invoke-IpuPostCheck` after the upgrade to verify that the server runs as it did before.

| Before the upgrade | After the upgrade |
| --- | --- |
| Supported upgrade path, edition, free disk space, pending restart, failover clustering, domain controller role, NIC Teaming and, on Azure VMs, the language and licensing the Azure upgrade media requires | OS version, automatic services, roles and features, listening TCP ports, volumes and drive letters, domain membership and secure channel, installed applications, activation |

[docs/checks.md](docs/checks.md) describes every check and why it exists.

## Requirements

- A server running Windows Server 2012 R2, 2016, 2019 or 2022, as an Azure VM or on-premises.
- Windows PowerShell 4.0 or later, which is included from Windows Server 2012 R2. PowerShell 7 works too.
- An elevated session, and an execution policy that allows local scripts (RemoteSigned, the Windows Server default).

The tool only reads from the server. The JSON report is the only thing it writes.

## Usage

1. Copy the `InPlaceUpgrade` folder to the server, for example to `C:\Tools\InPlaceUpgrade`. Take it from the zip of a [release](https://github.com/PECRE93/In-place-upgrade/releases) or from `src/`. If you downloaded the zip, unblock it before you extract it: `Unblock-File .\InPlaceUpgrade-x.y.z.zip`.

2. **Before the upgrade**, in an elevated Windows PowerShell session:

   ```powershell
   Import-Module C:\Tools\InPlaceUpgrade
   Invoke-IpuPreCheck -TargetVersion 2022
   ```

   Fix every FAIL, review every WARNING and run it again. The report, which includes the baseline, is saved as `C:\ProgramData\InPlaceUpgrade\<computer>-pre-<timestamp>.json`.

3. Back up the server or snapshot its disks, then run the upgrade. On Azure, follow [In-place upgrade for VMs running Windows Server in Azure](https://learn.microsoft.com/azure/virtual-machines/windows-in-place-upgrade). Run the pre-check before you attach the upgrade media, or the post-check reports the media disk as a missing volume once it's detached.

4. **After the upgrade**, once the server has been up for a few minutes:

   ```powershell
   Import-Module C:\Tools\InPlaceUpgrade
   Invoke-IpuPostCheck
   ```

   It compares the server with the newest baseline in `C:\ProgramData\InPlaceUpgrade`. Use `-BaselinePath` to pick another one.

Example output:

```text
In-place upgrade pre-check of SRV01 - target Windows Server 2022

  [PASS]    PRE-001   Supported upgrade path
                      Windows Server 2016 can be upgraded in place to 2022.
  [FAIL]    PRE-003   Free space on the system drive
                      C: has 18.2 GB free; at least 32 GB is required. Free up space or expand the OS disk.
  ...

Overall: FAIL
Report:  C:\ProgramData\InPlaceUpgrade\SRV01-pre-20261023T080000Z.json
```

Use `-OutputPath` to write the reports somewhere else, and `-PassThru` to get the report as an object in scripts; `Get-Help Invoke-IpuPreCheck -Full` has the details. Keep a copy of the reports off the server, so you still have them if the upgrade fails.

On Azure VMs, also consider Microsoft's [Windows OS Upgrade Assessment Tool](https://learn.microsoft.com/troubleshoot/azure/virtual-machines/windows/windows-vm-osupgradeassessment-tool), which checks Azure features such as Trusted Launch.

## Repository layout

```text
.github/                   CI and release workflows, pull request template, Dependabot
docs/adr/                  Architecture decision records
docs/checks.md             Catalogue of all checks
src/InPlaceUpgrade/        The module
  Public/                  Exported commands
  Private/                 Internal functions
    Collectors/            The only code that reads the system
  Checks/Pre, Checks/Post  One file per check
  Data/                    Settings and the Windows Server upgrade matrix
tests/                     Pester tests
build.ps1                  Bootstrap, analyze, test and package
CHANGELOG.md               Notable changes per version
```

## Development

```powershell
./build.ps1 -Task Bootstrap   # once: installs the pinned Pester and PSScriptAnalyzer versions
./build.ps1                   # analyze and test
```

[CONTRIBUTING.md](CONTRIBUTING.md) covers the workflow, the coding conventions and how to add a check.

## Versioning

The module follows [Semantic Versioning](https://semver.org/). Changes are recorded in [CHANGELOG.md](CHANGELOG.md), and pushing a `vX.Y.Z` tag publishes a release ([ADR-0004](docs/adr/0004-versioning-and-releases.md)). Design decisions are recorded in [docs/adr](docs/adr/README.md).
