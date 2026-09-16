# ADR 0002: Per-file DEKs

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §7.2, §8.1, §19 (M9)

## Context

Every sealed file on disk and every blob in Drive needs an encryption key. The naive option is to encrypt files directly under the master key (MK). Rotating the MK then requires decrypting and re-encrypting every byte of a multi-gigabyte vault and re-uploading all of it — so in practice rotation never happens, and a compromised key stays compromised for the life of the install.

## Decision

Every file gets a fresh per-file DEK (32 B from SecureRandom), wrapped under a purpose-scoped key derived from MK (K_files for assets, K_thumb for thumbnails, K_cloud for log + keyring). The wrapped DEK is stored in the envelope header and duplicated in the `blobs` table for recovery. Rotation rewraps DEKs only — a metadata-only pass over a few thousand short rows.

## Consequences

- Key rotation (§8.6) becomes cheap, resumable, and idempotent; file bodies are untouched.
- Compromising one DEK compromises one file, not the vault.
- The envelope header carries `key_epoch`, so a file always names the epoch whose key can open it.
- Rotation is a first-class operation from day one, not retrofitted.

## Alternatives rejected

- **Encrypt everything directly under MK:** rotation is effectively impossible in practice (full re-encrypt + re-upload of the whole vault).
- **One global data key:** same rotation problem, and a single compromise exposes all files.
- **Re-encrypting blobs on rotation:** never actually gets executed; the rewrapped-DEK pass does.
