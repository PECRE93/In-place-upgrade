# 0004. Versioning, changelog and releases

- Status: Accepted
- Date: 2026-10-23

## Context

The tool runs on production servers during maintenance windows. A pre-check report must still be usable by the post-check if the tool was updated in between. Operators need to know which version produced a report, and what changed between versions.

## Decision

### Source control

- `main` is always releasable. Work happens on short-lived branches (`feature/...`, `fix/...`, `docs/...`) that are merged through pull requests with a passing CI build and a review.
- Commit messages are written in the imperative ("Add POST-009 for scheduled tasks") and reference the issue, if there is one.

### Version numbers

The module follows [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html). `ModuleVersion` in `InPlaceUpgrade.psd1` is the single source of truth, and every report records the version that wrote it (`ToolVersion`).

- **Major**: breaking changes. Removing or renaming a public command or parameter, changing the report so that existing consumers break, or changing the snapshot so that baselines from the previous version can't be read. The last case also bumps `SnapshotSchemaVersion`; the post-check refuses baselines with a different schema version.
- **Minor**: backward-compatible functionality, such as new checks, new snapshot sections or new parameters. The post-check can use a baseline from an older minor version; checks that need a section the baseline lacks are skipped.
- **Patch**: bug fixes, wording, and changes to the defaults in `Settings.psd1` that don't change what is checked.
- While the version is 0.x, the interface may still change between minor versions.

### Changelog

- `CHANGELOG.md` follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/). Every pull request that changes behavior adds a line under **Unreleased**, in the group Added, Changed, Deprecated, Removed, Fixed or Security.
- A test fails if the manifest version has no section in the changelog.

### Releases

1. In a pull request, set `ModuleVersion`, rename **Unreleased** to `[x.y.z] - YYYY-MM-DD`, add a new empty **Unreleased** section and update the compare links at the bottom of the changelog.
2. After the merge, tag the merge commit `vx.y.z` and push the tag.
3. The release workflow checks that the tag matches `ModuleVersion`, runs the analyzer and the tests, and publishes a GitHub release with `InPlaceUpgrade-x.y.z.zip` and the changelog section as release notes.

A published release is never changed; a fix gets a new patch version.

## Consequences

- Every report can be traced to a tagged version, its changelog entry and its code.
- Updating the tool between the pre- and post-check is safe within the same major version.
- A release takes a small reviewed pull request and a tag.
