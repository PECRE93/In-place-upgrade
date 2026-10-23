# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). [ADR-0004](docs/adr/0004-versioning-and-releases.md) defines what counts as a major, minor or patch change.

## [Unreleased]

## [0.1.0] - 2026-10-23

### Added

- PowerShell module `InPlaceUpgrade` with `Invoke-IpuPreCheck` and `Invoke-IpuPostCheck`.
- Scripts `Invoke-PreUpgradeCheck.ps1` and `Invoke-PostUpgradeCheck.ps1` in `scripts/`, which run the checks and return the result as an exit code (0 = Pass, 1 = Fail or the check couldn't run, 2 = Warning). The release zip contains them next to the module.
- Snapshot of the server (operating system, domain membership, volumes, pending restart, services, roles and features, applications, listening ports, NIC teams, licensing, Azure metadata), saved in the pre-check report as the baseline for the post-check.
- Pre-upgrade checks PRE-001 to PRE-009 and post-upgrade checks POST-001 to POST-008, see [docs/checks.md](docs/checks.md).
- JSON reports in `%ProgramData%\InPlaceUpgrade`, a folder that the tool creates with access for administrators and SYSTEM only, and a color-coded console summary.
- Repository scaffolding: build script, Pester tests with code coverage, PSScriptAnalyzer rules including Windows PowerShell 4.0 compatibility, CI on Windows Server 2022 and 2025, architecture decision records, a contributing guide, a security policy, issue templates and code owners.
- Release workflow that publishes the zip with a SHA-256 checksum and signed build provenance.
- Description of the report format in [docs/report.md](docs/report.md).

[Unreleased]: https://github.com/PECRE93/In-place-upgrade/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/PECRE93/In-place-upgrade/releases/tag/v0.1.0
