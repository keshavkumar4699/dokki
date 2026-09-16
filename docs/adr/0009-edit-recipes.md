# ADR 0009: Edit recipes

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §5.3, §10.3, §0 (deviation 2)

## Context

The brief implies edit history stores only outputs. Storing only rendered outputs means an evicted version's binary is gone for good, sync payloads carry full binaries per edit, and future non-destructive editing has no way to replay what was done.

## Decision

Store a declarative edit recipe per version: a serializable list of normalized `ImageOp`s (Crop, Perspective, Rotate, Brightness, Contrast, Exposure, Sharpen, Denoise, Resize, Filter, Background) recorded against the parent version, with a `recipeDeterministic` flag (false for ML ops). Coordinates are normalized 0..1, so a recipe recorded against a 4000 px original applies correctly to a 1000 px preview. Detection is separate from application: `EdgeDetector.detect(handle) → Quad` feeds a `PerspectiveOp`, so swapping detection models never invalidates stored recipes.

## Consequences

- Evicted deterministic versions can be re-materialized from the original on demand (§10.3) — "up to 3 previous versions" is a storage limit, not a history limit.
- Far smaller sync payloads: the op list is tiny compared to a new binary.
- Future non-destructive editing reuses the same op machinery.
- Costs one JSON column (`recipe_json`) plus a schema version; non-deterministic recipes refuse re-materialization with `VersionNotRematerializable`.
- This is deliberate deviation #2 from the brief, flagged for approval (§0).

## Alternatives rejected

- **Outputs only (as the brief implies):** evicted versions are unrecoverable; every edit syncs a full binary; re-materialization is impossible.
- **Storing pixel-space coordinates:** recipes break when applied at a different resolution.
- **Replaying edits by re-running UI actions:** UI is not a stable, testable serialization of intent.
