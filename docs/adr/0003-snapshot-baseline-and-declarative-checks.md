# 0003. Snapshot, baseline and declarative checks

- Status: Accepted
- Date: 2026-10-23

## Context

The tool has two jobs:

1. Before the upgrade, tell whether the upgrade is supported and the server is ready for it.
2. After the upgrade, verify that the server runs as it did before: the same services, roles, ports, volumes, domain membership and so on.

The second job needs a record of the server's state from before the upgrade. Both jobs need checks that are easy to add and review, and that can be tested without a real server, because nobody can run unit tests against a server in the middle of an upgrade.

## Decision

Collecting facts is separated from evaluating them.

- **Collectors** (`Private/Collectors/Get-Ipu*Info.ps1`) are the only code that reads the system. Each one fills one section of a **snapshot**: a plain object that can be stored as JSON. A collector that fails leaves its section `$null` and is recorded in `CollectionErrors`; the other collectors still run. Collectors never change the server and never collect secrets.
- **Checks** (`Checks/Pre` and `Checks/Post`) are declarative: one file per check, returning `@{ Id; Phase; Title; Requires; Test }`. `Test` is a script block that receives a context, with the current `Snapshot`, the pre-upgrade `Baseline` (post-checks only), the `TargetVersion`, the `Settings` and the `WindowsServer` release data, and returns `@{ Status; Message; Details }`. Checks never call the system.
- `Requires` lists the snapshot sections a check reads, such as `Snapshot.Services` or `Baseline.Services`. The runner gives the check status **Error** if a section wasn't collected, and **Skipped** if the baseline was created by an older version that didn't collect it.
- A check that throws or returns something invalid gets status **Error**. It never stops the run.
- The statuses are Pass, Warning, Fail, Error and Skipped. The overall result is the worst of them, with Error counting as Fail.
- `Invoke-IpuPreCheck` saves its report, **including the snapshot**, to `%ProgramData%\InPlaceUpgrade`, which survives the upgrade. That snapshot is the baseline `Invoke-IpuPostCheck` compares with. The live snapshot is round-tripped through JSON before it is evaluated, so checks see the same data types whether the data is live or read from disk.
- Check IDs (`PRE-NNN`, `POST-NNN`) are stable and never reused, so reports from different versions can be compared.
- Thresholds and ignore lists are data in `Data/Settings.psd1`, and Microsoft's upgrade matrix is data in `Data/WindowsServer.psd1`. Both are loaded as restricted-language data, so they can't run code.

## Consequences

- Checks are small pure functions, unit tested with handmade snapshots in milliseconds on any machine.
- Adding a check means one file, its tests and a row in [docs/checks.md](../checks.md). A test fails if the catalogue is missing a check.
- New data needs a new collector and snapshot section. Adding a section is backward compatible; renaming, removing or reshaping one is a breaking change ([ADR-0004](0004-versioning-and-releases.md)).
- The post-check depends on the pre-check. Without a baseline it refuses to run.
- Reports contain an inventory of the server (services, applications, ports). They hold no secrets, but should be stored like other server documentation.
