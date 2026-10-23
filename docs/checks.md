# Checks

Every check has a stable ID; the IDs of removed checks are never reused. The definitions live in [src/InPlaceUpgrade/Checks](../src/InPlaceUpgrade/Checks), the thresholds and ignore lists in [Settings.psd1](../src/InPlaceUpgrade/Data/Settings.psd1).

| Status | Meaning |
| --- | --- |
| Pass | Nothing to do. |
| Warning | Review it before you continue. The upgrade may still work. |
| Fail | Pre-check: fix it before upgrading. Post-check: investigate now. |
| Error | The check couldn't run, usually because its data wasn't collected. Counts as Fail. |
| Skipped | Doesn't apply to this server, for example an Azure-only check on-premises. |

The overall result is **Fail** if any check failed or had an error, **Warning** if any check warned, and **Pass** otherwise.

## Pre-upgrade checks

Run by `Invoke-IpuPreCheck` against the current server.

| ID | Check | When not met | Why |
| --- | --- | --- | --- |
| PRE-001 | Supported upgrade path | Fail | The source and target version must be a supported pair in Microsoft's [upgrade matrix](https://learn.microsoft.com/windows-server/get-started/install-upgrade-migrate#supported-in-place-upgrade-paths-by-version), for example 2012 R2 → 2016/2019/2025 or 2016 → 2019/2022/2025. |
| PRE-002 | Edition can be upgraded | Fail (Storage Server), Warning (evaluation) | Storage Server editions can't be upgraded in place, and evaluation editions must be converted first. On a pass, the message says which image to select, because Setup can't switch between Server Core and Desktop Experience. |
| PRE-003 | Free space on the system drive | Fail | Setup needs room for the new OS and the rollback copy of the old one. Default: 32 GB (`MinimumSystemDriveFreeGB`). |
| PRE-004 | No pending restart | Fail, Warning if only file renames are pending | Pending servicing, Windows Update or computer rename operations. Restart first. Pending file renames alone only warn, because antivirus software often adds them again right after a restart. |
| PRE-005 | Not a failover cluster node | Fail | Cluster nodes must use a cluster OS rolling upgrade. |
| PRE-006 | Not a domain controller | Warning | Microsoft recommends replacing domain controllers rather than upgrading them in place. |
| PRE-007 | NIC Teaming not in use | Fail | NIC Teaming must be disabled during the upgrade and re-enabled afterwards. |
| PRE-008 | OS language matches the Azure upgrade media | Warning (Azure only) | The Azure upgrade media is en-US only. |
| PRE-009 | Volume licensing for the Azure upgrade media | Fail (Azure only) | The Azure upgrade media requires KMS client (volume) activation. |

## Post-upgrade checks

Run by `Invoke-IpuPostCheck`, which compares the server with the baseline saved by the pre-check.

| ID | Check | When not met | What is compared |
| --- | --- | --- | --- |
| POST-001 | Upgraded to the target version | Fail | The OS build is the target version of the pre-check. |
| POST-002 | Automatic services are running | Fail | Every service that was automatic and running before still exists, isn't disabled and, if it's still automatic, is running. Services that the new version starts on demand, per-user services and `IgnoredServices` are skipped. |
| POST-003 | Roles and features are still installed | Fail | Every role and feature installed before is still installed, except `IgnoredFeatures`. By default, that list holds features that newer versions removed, such as the 2012 R2 GUI features and PowerShell-V2. |
| POST-004 | TCP ports are listening again | Fail | Every TCP port below 49152 that listened before listens again, except `IgnoredPorts`. Higher ports are dynamic and change at every restart. |
| POST-005 | Volumes and drive letters are unchanged | Fail | Every local volume still has its drive letter and label. |
| POST-006 | Domain membership and secure channel | Fail, Warning if it can't be verified | The server is in the same domain as before and its secure channel works. |
| POST-007 | Applications are still installed | Warning | Every application in Programs and Features is still there, except `IgnoredApplications`. |
| POST-008 | Windows is activated | Warning | Windows is activated. |
