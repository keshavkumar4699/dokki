# ADR 0008: drive.appdata scope

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §9.2, §0 (A6), §16 (R4)

## Context

Drive sync needs an OAuth scope. `drive.appdata` keeps the app folder hidden from the user's Drive UI entirely and grants access only to our own app folder. `drive.file` creates a visible folder the user can browse, but also one a user (or a shoulder-surfer sharing the account) can see and accidentally delete or move.

## Decision

Use `https://www.googleapis.com/auth/drive.appdata` (assumption A6). Layout under `appDataFolder/v1/` with keyring.bin, optional manifest.bin, opaque blobs `b_<uuid>.bin`, and per-device log segments `l_<dev>_<seq>.bin`. `appProperties` carry routing metadata only — `{blobId, envVer, keyEpoch, ctSha256, size}` — treated as public, never semantics. Uploaded MIME type is always `application/octet-stream`.

## Consequences

- Invisibility is the privacy-preserving default: nothing visible to a shoulder-surfer or a family member sharing the account.
- Minimal privilege: access only to our own app folder.
- `drive.appdata` is a sensitive OAuth scope: production use requires Google's app verification (privacy policy, demo video, justification) — schedule risk R4, start 8 weeks before Phase 7 ships; fallback is v1.0 offline-only, sync in v1.1.
- Downside: the user cannot manually back up or inspect the folder.

## Alternatives rejected

- **`drive.file`:** user-visible folder; leaks folder name + file count; user can accidentally delete or move files.
- **Full drive scope:** violates least privilege and the privacy requirement.
