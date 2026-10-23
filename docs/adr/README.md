# Architecture decision records

An architecture decision record (ADR) captures one significant decision: its context, the decision and its consequences. [ADR-0001](0001-record-architecture-decisions.md) explains why and how we use them.

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
| [0002](0002-windows-powershell-module.md) | Implement the tool as a Windows PowerShell module | Accepted |
| [0003](0003-snapshot-baseline-and-declarative-checks.md) | Snapshot, baseline and declarative checks | Accepted |
| [0004](0004-versioning-and-releases.md) | Versioning, changelog and releases | Accepted |

## Adding an ADR

1. Copy [template.md](template.md) to `NNNN-short-title.md`, using the next free number.
2. Fill it in with status **Proposed** and open a pull request. The review is the discussion.
3. When the pull request is merged, set the status to **Accepted** and add the ADR to the table above.

Accepted ADRs aren't rewritten. To change a decision, write a new ADR and mark the old one **Superseded by ADR-NNNN**.
