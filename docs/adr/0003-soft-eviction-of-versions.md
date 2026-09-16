# ADR 0003: Soft eviction of versions

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §10.3, §19 (M5)

## Context

Version retention keeps only a bounded set of binaries materialized (original + current + 3 derived + pinned). Evicting older binaries must not destroy export history or version lineage. `export_record_sources.version_id` is a foreign key (`ON DELETE RESTRICT`) to `asset_versions`, and `parent_version_id` links the lineage chain.

## Decision

Eviction deletes the binary, never the row: `UPDATE asset_versions SET blob_id = NULL, evicted_at = ?`. Rows cost ~200 bytes and survive forever, preserving invariant I5 (every export references a real version), the lineage chain, and the stored edit recipe. A deterministic evicted version can be re-materialized from the original on demand by replaying its recipe chain.

## Consequences

- "Up to 3 previous versions" is a storage limit, not a history limit: the user's visible history is unlimited; older entries take a moment to recompute.
- No orphaned export history, no broken "Export Again".
- Non-deterministic recipes (e.g. ML background removal) cannot be re-materialized and fail with `VersionNotRematerializable`.
- Blob purge happens only after commit, so a crash leaves harmless orphan files, not dangling DB rows.

## Alternatives rejected

- **Hard-deleting version rows:** either fails on the FK constraint (and someone "fixes" it by dropping the constraint) or cascades and destroys export history; lineage develops dangling `parent_version_id` pointers.
- **Keeping all binaries:** violates the storage budget; originals on a 40 MP camera fill devices.
