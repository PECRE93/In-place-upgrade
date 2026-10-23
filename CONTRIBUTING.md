# Contributing

## Workflow

1. Create a branch from `main`: `feature/<name>`, `fix/<name>` or `docs/<name>`.
2. Make the change, with tests.
3. Run `./build.ps1` in PowerShell 7 or Windows PowerShell 5.1. It runs PSScriptAnalyzer and all tests. Run `./build.ps1 -Task Bootstrap` once beforehand.
4. Add a line under **Unreleased** in [CHANGELOG.md](CHANGELOG.md) for anything a user would notice.
5. Open a pull request. CI must pass, and someone else must review it.

Write an [ADR](docs/adr/README.md) when you change how the tool is structured, what it's compatible with, its report or baseline format, or how it's built and released.

## Conventions

- **Windows PowerShell 4.0 compatible.** No classes, enums, `using`, `::new()`, or cmdlets newer than 4.0 (`Import-PowerShellDataFile`, `Get-ComputerInfo`, `Compress-Archive`, ...). The analyzer checks this against Windows Server 2012 R2, 2016 and 2019; see [ADR-0002](docs/adr/0002-windows-powershell-module.md).
- **ASCII only** in `.ps1`, `.psm1` and `.psd1` files, because Windows PowerShell reads UTF-8 without a byte order mark as ANSI.
- **One function per file**, named after the function. Exported functions go in `Public` and in `FunctionsToExport` in the manifest; everything else goes in `Private`.
- Approved verbs (`Get-Verb`) and the `Ipu` noun prefix.
- `Set-StrictMode -Version Latest` applies to the whole module. Read properties that may not exist with `Get-IpuProperty`.
- **Collectors only read.** Nothing in the module may change the server.

## Adding a check

1. Pick the next free ID. IDs are never reused, even when a check is removed.
2. Add `src/InPlaceUpgrade/Checks/Pre/PRE-NNN.<Name>.ps1`, or `Checks/Post/POST-NNN.<Name>.ps1`:

   ```powershell
   @{
       Id       = 'PRE-010'
       Phase    = 'Pre'
       Title    = 'What must be true'
       Requires = @('Snapshot.OperatingSystem')   # post-checks can also require 'Baseline.<Section>'
       Test     = {
           param($Context)
           # $Context.Snapshot, .Baseline (post-checks only), .TargetVersion, .Settings, .WindowsServer
           if ($Context.Snapshot.OperatingSystem.SystemDrive -ne 'C:') {
               return @{ Status = 'Warning'; Message = 'What is wrong, and what to do about it.' }
           }
           @{ Status = 'Pass'; Message = 'What was verified.' }
       }
   }
   ```

   The status is `Pass`, `Warning`, `Fail` or `Skipped`; put long lists in `Details`. Read only from `$Context`, never from the system: if you need data that isn't in the snapshot, add a collector first. Thresholds and ignore lists belong in `Data/Settings.psd1`.
3. Add tests to `tests/PreChecks.Tests.ps1` or `tests/PostChecks.Tests.ps1`, with at least one case that passes and one that doesn't.
4. Add the check to [docs/checks.md](docs/checks.md) and to the changelog.

## Adding data to the snapshot

1. Add `src/InPlaceUpgrade/Private/Collectors/Get-Ipu<Name>Info.ps1`. It returns plain objects that survive a JSON round trip and throws when it can't collect. Return arrays with a leading comma (`, @($items)`) so that empty and single-item arrays aren't unrolled.
2. Register it in `Get-IpuSnapshot`, and add the section to `New-IpuTestSnapshot` in `tests/TestHelpers.ps1`.
3. A new section is a minor change. Renaming, removing or reshaping a section is a breaking change: bump `$script:SnapshotSchemaVersion` in `InPlaceUpgrade.psm1` and the major version ([ADR-0004](docs/adr/0004-versioning-and-releases.md)).

## Releasing

1. In a pull request, set `ModuleVersion` in `src/InPlaceUpgrade/InPlaceUpgrade.psd1`, rename **Unreleased** in the changelog to `[x.y.z] - YYYY-MM-DD`, add a new empty **Unreleased** section and update the links at the bottom.
2. After the merge, tag the merge commit and push the tag:

   ```powershell
   git tag vx.y.z
   git push origin vx.y.z
   ```

3. The release workflow builds, tests and publishes the GitHub release with the module zip and the release notes.
