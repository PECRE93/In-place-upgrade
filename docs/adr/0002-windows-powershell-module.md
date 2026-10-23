# 0002. Implement the tool as a Windows PowerShell module

- Status: Accepted
- Date: 2026-10-23

## Context

The checks run on the servers that are about to be upgraded: Windows Server 2012 R2 to 2022, as Azure VMs or on-premises. Those servers:

- ship only Windows PowerShell: 4.0 on Windows Server 2012 R2 (unless WMF 5.1 was installed) and 5.1 on 2016 and later;
- often have no internet access and strict change control, so installing a runtime or packages right before an upgrade isn't an option;
- are administered by operators who already use PowerShell.

The tool must also be testable on a build agent, without a real server.

## Decision

- Implement the tool as a PowerShell script module, `InPlaceUpgrade`, in `src/InPlaceUpgrade`. Deploying it means copying the folder, or the release zip, to the server.
- The module must run on **Windows PowerShell 4.0 and later** with no dependencies beyond Windows itself: no classes or enums, no `using`, no `::new()`, and no cmdlets newer than 4.0 such as `Import-PowerShellDataFile`, `Get-ComputerInfo` or `Compress-Archive`. PSScriptAnalyzer's compatibility rules enforce this against the Windows Server 2012 R2, 2016 and 2019 profiles.
- Source files are ASCII, because Windows PowerShell reads UTF-8 files without a byte order mark as ANSI.
- The module also runs on PowerShell 7, but nothing may depend on it.
- Public commands use approved verbs and the `Ipu` noun prefix. There is one function per file; exported functions live in `Public`, everything else in `Private`.
- Tests use Pester and run in CI on both Windows PowerShell 5.1 and PowerShell 7.

Options considered:

- **A standalone script**: the simplest to copy, but hard to structure and unit test as it grows.
- **A compiled tool (.NET or Go)**: a single binary, but it needs a build tool chain, is harder for operators to read and change, and would still need PowerShell or WMI for most of the facts.
- **Configuration management (DSC, Ansible, ...)**: not available on every server, and built to enforce state rather than report on it.

## Consequences

- Nothing has to be installed on the servers, and operators can read what the tool does.
- PowerShell 4.0 rules out some modern syntax. Contributors must know the restrictions ([CONTRIBUTING.md](../../CONTRIBUTING.md)); the analyzer catches most mistakes.
- Unit tests run anywhere. The collectors that read the real system are covered by an integration test on the Windows Server CI runner.
