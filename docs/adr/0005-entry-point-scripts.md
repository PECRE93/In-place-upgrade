# 0005. Entry-point scripts with exit codes

- Status: Accepted
- Date: 2026-10-23

## Context

Operators run the checks by hand on each server, and other tools such as scheduled tasks, deployment tools or remote execution may run them too. Importing the module and calling a function is an extra manual step, and other tools judge a run by its process exit code, not by a PowerShell object.

## Decision

- The `scripts` folder holds one script per public command: `Invoke-PreUpgradeCheck.ps1` and `Invoke-PostUpgradeCheck.ps1`.
- The scripts are thin entry points. They load the module, call the command with the same parameters and turn the overall result into an exit code: **0** = Pass, **1** = Fail or the check couldn't run, **2** = Warning. Any error ends a script with exit code 1, which is also what PowerShell returns when a script can't start, for example because of an invalid parameter.
- A script loads the module from the `InPlaceUpgrade` folder next to it, from `..\src\InPlaceUpgrade` in a copy of the repository, or by name from the PowerShell module path.
- The release zip contains the scripts and the `InPlaceUpgrade` module folder side by side.
- The scripts follow the same rules as the module ([ADR-0002](0002-windows-powershell-module.md)) and are analyzed and tested with it.
- Script names, parameters and exit codes are a public interface: changing them is a major change ([ADR-0004](0004-versioning-and-releases.md)).

## Consequences

- Operators run one script, and other tools can act on the exit code without parsing output.
- Any non-zero exit code means "don't continue automatically": a Fail and a Warning both need someone to read the report.
- The logic stays in the module, where it's unit tested. The script tests only cover loading the module and the exit codes.
