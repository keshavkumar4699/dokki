# ADR 0004: Package-not-folder boundaries

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §14.1, §3.2, §16 (R17)

## Context

The brief asks for a folder tree that does not become `screens/widgets/services`. A folder convention is enforced by discipline, and discipline degrades at 2 a.m. before a release. Risk R17 scores this 16 (L4 x I4): team drift past architectural boundaries under deadline pressure.

## Decision

Split the codebase into local Dart packages (vault_domain, vault_app_core, vault_crypto, vault_persistence, vault_storage, vault_imaging, vault_pdf, vault_export, vault_sync, vault_drive, platform_android, app) in a pub workspace. Because `vault_domain/pubspec.yaml` does not list `drift` or `googleapis`, importing them is a build error, not a review comment. Boundaries are compiler-enforced (compile-time, hard), backed by `tool/check_boundaries.dart` in CI and lint rules for intra-package rules (soft).

## Consequences

- ~11 extra pubspec.yaml files, a workspace tool, and slower initial setup — judged worth paying given the app's failure modes are "a key leaked into a log" and "the UI reached into SQLite".
- `app/lib/bootstrap/composition_root.dart` is the only file allowed to import concrete infrastructure.
- Dependencies point inward; cycles are a build failure.
- CI gate fails on any planted forbidden import (acceptance criterion §18).

## Alternatives rejected

- **Single package with folders (`lib/domain`, `lib/infrastructure`):** works, but fails open instead of failing closed; ships faster at the cost of discipline-based enforcement.
