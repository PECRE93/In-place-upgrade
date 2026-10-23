# In-place upgrade checks

[![CI](https://github.com/PECRE93/In-place-upgrade/actions/workflows/ci.yml/badge.svg)](https://github.com/PECRE93/In-place-upgrade/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/PECRE93/In-place-upgrade?sort=semver)](https://github.com/PECRE93/In-place-upgrade/releases)

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

1. Download the zip of a [release](https://github.com/PECRE93/In-place-upgrade/releases), unblock it with `Unblock-File .\InPlaceUpgrade-x.y.z.zip` and extract it on the server, for example to `C:\Tools\InPlaceUpgrade`. The zip holds the two scripts from [scripts/](scripts) and the `InPlaceUpgrade` module folder. A copy of the repository works as well.

   To check that the zip is the one the release workflow built, compare `(Get-FileHash .\InPlaceUpgrade-x.y.z.zip).Hash` with the `.sha256` file of the release, or run `gh attestation verify .\InPlaceUpgrade-x.y.z.zip --repo PECRE93/In-place-upgrade`.

2. **Before the upgrade**, in an elevated Windows PowerShell session:

   ```powershell
   C:\Tools\InPlaceUpgrade\Invoke-PreUpgradeCheck.ps1 -TargetVersion 2022
   ```

   Fix every FAIL, review every WARNING and run it again. The report, which includes the baseline, is saved as `C:\ProgramData\InPlaceUpgrade\<computer>-pre-<timestamp>.json`. The tool creates that folder with access for administrators and SYSTEM only, so nobody else can add a fake baseline.

3. Back up the server or snapshot its disks, then run the upgrade. On Azure, follow [In-place upgrade for VMs running Windows Server in Azure](https://learn.microsoft.com/azure/virtual-machines/windows-in-place-upgrade). Run the pre-check before you attach the upgrade media, or the post-check reports the media disk as a missing volume once it's detached.

4. **After the upgrade**, once the server has been up for a few minutes:

   ```powershell
   C:\Tools\InPlaceUpgrade\Invoke-PostUpgradeCheck.ps1
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

Both scripts take `-OutputPath` to write the reports somewhere else, and `Get-Help` shows all their parameters. Keep a copy of the reports off the server, so you still have them if the upgrade fails.

The scripts set an exit code, so other tools can run them with `powershell.exe -File` and act on the result:

| Exit code | Result |
| --- | --- |
| 0 | Pass |
| 1 | Fail, or the check couldn't run |
| 2 | Warning |

In your own PowerShell code, you can import the module instead and call `Invoke-IpuPreCheck` or `Invoke-IpuPostCheck` with `-PassThru` to get the report as an object. [docs/report.md](docs/report.md) describes the report.

On Azure VMs, also consider Microsoft's [Windows OS Upgrade Assessment Tool](https://learn.microsoft.com/troubleshoot/azure/virtual-machines/windows/windows-vm-osupgradeassessment-tool), which checks Azure features such as Trusted Launch.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| "Run this command from an elevated PowerShell session" | Start Windows PowerShell with **Run as administrator**. |
| A script "is not digitally signed" | The files are still marked as downloaded. Run `Unblock-File` on the zip before you extract it, or on the extracted files. |
| A check has status **Error** | The data it needs couldn't be collected. The `CollectionErrors` section of the report says why. |
| "No pre-check report for ..." | Run the pre-check first. Give the post-check the same `-OutputPath` as the pre-check, or the report itself with `-BaselinePath`. |
| A post-check flags a service, feature or application that changes by design | Add it to the ignore lists in [Settings.psd1](src/InPlaceUpgrade/Data/Settings.psd1) through a pull request. |

## Repository layout

```text
.github/                   CI and release workflows, issue and pull request templates, code owners, Dependabot
docs/adr/                  Architecture decision records
docs/checks.md             Catalogue of all checks
docs/report.md             Format of the JSON reports
scripts/                   Scripts to run on the servers: pre- and post-check
src/InPlaceUpgrade/        The module
  Public/                  Exported commands
  Private/                 Internal functions
    Collectors/            The only code that reads the system
  Checks/Pre, Checks/Post  One file per check
  Data/                    Settings and the Windows Server upgrade matrix
tests/                     Pester tests
build.ps1                  Bootstrap, analyze, test and package
CHANGELOG.md               Notable changes per version
SECURITY.md                How to report vulnerabilities
```

## Development

```powershell
./build.ps1 -Task Bootstrap   # once: installs the pinned Pester and PSScriptAnalyzer versions
./build.ps1                   # analyze and test
```

[CONTRIBUTING.md](CONTRIBUTING.md) covers the workflow, the coding conventions and how to add a check. Report bugs and suggest checks with the [issue templates](https://github.com/PECRE93/In-place-upgrade/issues/new/choose), and report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## Versioning

The module follows [Semantic Versioning](https://semver.org/). Changes are recorded in [CHANGELOG.md](CHANGELOG.md), and pushing a `vX.Y.Z` tag publishes a release ([ADR-0004](docs/adr/0004-versioning-and-releases.md)). Design decisions are recorded in [docs/adr](docs/adr/README.md).
