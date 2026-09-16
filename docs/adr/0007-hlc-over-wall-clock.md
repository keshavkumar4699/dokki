# ADR 0007: HLC over wall clock

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §9.4, §19 (M4)

## Context

Conflict resolution needs an ordering. Wall-clock `updatedAt` fails on clock skew, timezone changes, manual clock adjustment, devices booting to 1970, and two edits in the same millisecond. Last-writer-wins on wall time silently discards the newer edit, and the bug is undiagnosable because the timestamps look plausible. Wall time also cannot distinguish "B edited after seeing A's change" from "B edited without knowing about A".

## Decision

Use hybrid logical clocks: `hlc = (physicalMillis, logicalCounter, deviceId)`. On send/local events and receive, the standard HLC update rules apply. Total order compares pt, then lc, then deviceId (deterministic tiebreak). For genuine concurrency detection, each mutable field carries the HLC of the last write it observed; if neither side's write observed the other's, the writes are concurrent and a conflict is raised. Wall time is displayed to humans and never used for decisions.

## Consequences

- Deterministic tiebreak: every device picks the same provisional conflict winner with zero extra round trips (§9.5).
- HLC stays close enough to wall time to be human-readable in a future conflict UI.
- HLCs are stored in sortable TEXT form `<48-bit-ms-hex>:<16-bit-counter-hex>:<deviceIdShort>`.
- Requires injected `Clock`/`IdGenerator`/`RandomSource` from day one (§13.2) so tests are deterministic.

## Alternatives rejected

- **Wall-clock last-writer-wins:** wrong under skew and indistinguishable from concurrency; silently discards newer edits.
- **Vector clocks per device:** correct causality but no deterministic single winner without extra coordination and no human-readable time.
- **Server-assigned sequence:** there is no server component (A7).
