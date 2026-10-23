# Report format

Every run writes one JSON report, `<computer>-<phase>-<UTC timestamp>.json`, to the output folder. Scripts and other tools can rely on the fields below. Changing them in an incompatible way is a major version change ([ADR-0004](adr/0004-versioning-and-releases.md)).

| Field | Description |
| --- | --- |
| `Tool`, `ToolVersion` | `InPlaceUpgrade` and the module version that wrote the report. |
| `Phase` | `Pre` or `Post`. |
| `ComputerName` | The server the report is about. |
| `TargetVersion` | The Windows Server version of the upgrade, for example `2022`. |
| `CreatedAtUtc` | When the report was written, as an ISO 8601 UTC timestamp. |
| `OverallStatus` | `Pass`, `Warning` or `Fail`. The exit codes of the scripts follow it. |
| `BaselinePath` | Post-check only: the pre-check report it compared with. |
| `Results` | One entry per check with `Id`, `Title`, `Status`, `Message` and `Details`. `Details` lists every finding when the message shows only the first few. |
| `Snapshot` | The facts the checks evaluated. The snapshot of a pre-check report is the baseline for the post-check. |

## Snapshot

| Section | Contents |
| --- | --- |
| `SchemaVersion` | Version of the snapshot format. The post-check refuses a baseline with another version. |
| `ComputerName`, `CollectedAtUtc` | Where and when the snapshot was taken. |
| `OperatingSystem` | Caption, version, build number, edition ID, installation type (`Server` or `Server Core`), install language (LCID) and system drive. |
| `ComputerSystem` | Domain, domain membership, domain role, and whether the secure channel works (`null` when it couldn't be tested). |
| `Volumes` | Local volumes: drive letter, label, file system, and size and free space in GB. |
| `PendingReboot` | Whether a restart is pending, and the reasons. |
| `Services` | Every service: name, display name, state and start mode. |
| `Features` | Names of the installed roles and features. |
| `Applications` | Programs and Features entries: name, version and publisher. |
| `ListeningPorts` | Listening TCP ports with the name of the owning process. |
| `NicTeams` | Names of the LBFO NIC teams. |
| `Licensing` | The Windows licence: name, channel description and activation status. |
| `Azure` | Whether the server is an Azure VM and, if it is, its resource ID, size, region and zone. |
| `CollectionErrors` | Sections that couldn't be collected, with the error. Those sections are `null`. |
