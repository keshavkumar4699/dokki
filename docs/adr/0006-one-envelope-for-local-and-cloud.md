# ADR 0006: One envelope for local and cloud

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §7.2, §1.2

## Context

The vault stores sealed files locally (app-private storage) and uploads blobs to Google Drive. Two separate formats would require the sync engine to decrypt and re-encrypt at the boundary, which would demand a user-authenticated key in background jobs.

## Decision

Every sealed file on disk and every blob in Drive uses the same byte format: Envelope v1 (header with magic "PVLT1", version, `alg_id`, key epoch, purpose, wrapped DEK, stream salt, authenticated `header_tag`; body of 256 KiB AEAD chunks with counter + final-flag in the nonce). The sync engine uploads the exact bytes already on disk. It never decrypts anything and never needs a user-authenticated key.

## Consequences

- Sync works correctly in a background WorkManager job without the user present (§9.7).
- The cloud port's `put` takes a ciphertext stream; the type system makes handing plaintext to a cloud provider impossible (§9.1).
- The header is authenticated, so `alg_id`/`key_epoch` cannot be downgraded by a writer who can modify the file.
- A `RecordingCloudProvider` test asserts no plaintext ever reaches the cloud port.

## Alternatives rejected

- **Separate local and cloud formats:** requires decrypt/re-encrypt at the sync boundary and a key in background jobs.
- **Single-shot AES-GCM:** OOMs on 60 MB files; naive hand-rolled chunking without counter/final-flag allows reorder and truncation (M8).
- **Custom crypto:** rejected in principle; the format documents what Tink's `StreamingAead` produces plus our header.
