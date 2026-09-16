# Privacy Policy — dokki

_Last updated: 2026-09-16 · Applies to the dokki Android application._

## The short version

**dokki is designed so that we cannot read your documents, and neither can
anyone who hosts your backups.** Your documents are encrypted on your
device with keys that never leave it. We run no servers, collect no
analytics, and show no ads.

## What dokki stores on your device

- Documents you import (photos, IDs, signatures, thumbprints, document
  pages), stored encrypted with AES-256-GCM.
- A SQLCipher-encrypted database of document metadata (titles, notes,
  tags — themselves additionally encrypted inside it).
- Encryption keys, held by the Android Keystore (hardware-backed on
  supported devices) and wrapped by your PIN and recovery passphrase.

## What leaves your device, and when

**Only if you explicitly enable Google Drive sync**, dokki stores a backup
in your own Google Drive, in the hidden `appDataFolder`:

- Encrypted blobs (AES-256-GCM). Google sees ciphertext, never content.
- Encrypted operation logs describing your edits. Also ciphertext.
- An encrypted keyring, openable only with your recovery passphrase.
- Opaque random filenames. No titles, types, or semantics in file names,
  properties, or MIME types.

Residual information Google necessarily sees as the storage provider:
file counts, sizes, and timestamps — never contents or metadata.

**If you export a document and share it**, the exported file (optionally
PDF/JPEG/PNG) leaves the app unencrypted through Android's share sheet, to
the app you choose. This is the only flow in which document content
leaves the device in the clear, and it happens only when you ask for it.

## What dokki never collects

- No analytics, telemetry, or crash reporting SDKs.
- No advertising identifiers.
- No accounts other than your own Google sign-in for Drive sync.
- No location, contacts, or clipboard contents (clipboard values are
  cleared after 30 seconds).

## Permissions

- **Camera / Photos** — to capture and import documents you choose.
- **Google account (drive.appdata scope)** — only if you enable sync;
  grants access solely to the hidden app folder in your Drive.

## Deletion

Deleting an entry removes it locally (after a safety delay) and from
Drive when your other devices have caught up. Removing the app deletes
all local data. Your recovery passphrase is the only way to restore a
Drive backup onto a new device; if you lose it, the backup is
unrecoverable by anyone, including us.

## Contact

This policy covers the dokki application only, not Google Drive's own
policies. Questions: open an issue on the project repository.
