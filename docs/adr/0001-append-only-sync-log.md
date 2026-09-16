# ADR 0001: Append-only sync log

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §9.3, §1.1 (Idea 3), §19 (M3)

## Context

Multi-device sync needs a shared state channel. Snapshot sync ("upload the DB, download the DB") means the second upload overwrites the first device's entire session: Device A's last hour is gone, silently, with no way to recover it later. This decision must be made now, before any sync data exists.

## Decision

Metadata syncs as an append-only operation log. Each device writes only to its own log segments in Drive (`l_<dev>_<seq>.bin`), sealing a segment at 256 KiB or 5 minutes and uploading it. Devices never write to each other's files, so there are zero file-level write conflicts in the cloud. Merging happens locally by replaying every device's log against a deterministic reducer: `(state, ops sorted by HLC) → state`. Two devices that have seen the same set of segments arrive at byte-identical state.

## Consequences

- Cloud-side write conflicts cannot exist by construction.
- Replay is testable: commutativity and idempotence are property-tested (P5, P6).
- Unknown op types from newer peers are preserved verbatim and skipped, never dropped (§9.6).
- Blob uploads remain idempotent; log segments are immutable once uploaded.

## Alternatives rejected

- **Snapshot sync:** loses updates silently and cannot be fixed later; migrating users off it is close to impossible because the history needed to reconstruct was never recorded.
- **Shared mutable log files:** reintroduces file-level write conflicts in the cloud.
