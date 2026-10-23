# 0001. Record architecture decisions

- Status: Accepted
- Date: 2026-10-23

## Context

The tool runs on production servers right before and after an in-place upgrade, and several people will maintain it over time. Decisions such as which PowerShell version to support or how the baseline is stored have long-lived consequences. Without a record of why they were made, they are easily undone by accident or argued about again.

## Decision

We record architecturally significant decisions as architecture decision records (ADRs), as described by Michael Nygard in [Documenting architecture decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):

- One Markdown file per decision in `docs/adr`, named `NNNN-short-title.md` and numbered in sequence.
- Each ADR has a status, a date and the sections Context, Decision and Consequences ([template](template.md)).
- An ADR is proposed in a pull request and accepted when that pull request is merged.
- Accepted ADRs aren't rewritten. A changed decision gets a new ADR, and the old one is marked as superseded.

A decision is significant when it affects the structure of the code, the report or baseline format, compatibility with the servers, or how the tool is built and released.

## Consequences

- New maintainers and reviewers can find the reasoning behind the design.
- Changing a recorded decision takes a short write-up in addition to the code change.
