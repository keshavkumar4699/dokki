# dokki

A privacy-focused document vault for `PHOTO`, `ID`, `SIGNATURE`, `THUMBPRINT`, and `DOCUMENT` entries. Everything is encrypted client-side at rest (SQLCipher database, AES-256-GCM sealed blobs, hardware-backed Android Keystore keys) and optionally synced to the user's own Google Drive in the same encrypted envelope — the cloud never sees plaintext or even semantic metadata. Offline-first, Android-first, Flutter/Dart, designed as a pub workspace of 12 local packages with compiler-enforced boundaries.

## Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — full technical architecture (v0.1).
- [THREAT_MODEL.md](docs/THREAT_MODEL.md) — threat table and key hierarchy, extracted from ARCHITECTURE.md §8.7.
- [adr/](docs/adr/) — architecture decision records 0001–0010, one page each.

## Status

Phases 0–9 of §17 are implemented and running end to end on Android, Phase 2 with the real Keystore path and Phase 4 with the real native image pipeline:

| Layer | State |
|---|---|
| `vault_domain` | Complete: entities, specs, invariants, version graph, retention, ports, sealed failures. 83 tests. |
| `vault_persistence` | Complete schema (§6) over Drift; partial unique indexes and I3 triggers; `EntryRepository`, `KeyEpochRepository`, `SyncStateRepository`, `ThumbnailIndex`. 28 DB tests incl. constraint rejections. |
| `vault_crypto` | Envelope v1 cipher (STREAM framing, tamper matrix), `CryptoEngine`, `KeyManagerImpl` over the Keystore bridge, plus the dev-only `DartKeyManager`/`DartEnvelopePrimitive` fallback. Phase 9: full `rotate()` (verify-then-wrap MK' under a new epoch) + `rewrapDek` + `EnvelopeHeaderRewriter` (header-only rewrite per §8.6). 36 tests. |
| `vault_app_core` (Phase 9) | `KeyRotationJob`: batch rewrap of every retired-epoch blob header, resumable by construction (the epoch-scoped query skips finished blobs; a kill mid-job resumes next launch). 2 end-to-end rotation tests (rotate → rewrap → bytes open under the new epoch; wrong PIN stores nothing). |
| `vault_storage` | `FileBlobStore` (atomic `.part`→rename, fan-out layout, sealed), `KeyringFile` (§7.1, the pre-unlock keyring), `ThumbnailCache` (S/M/L, LRU budget). 16 tests. |
| `vault_imaging` | `NativeImageProcessor` + `NativeRasterEngine` over the Kotlin pipeline (sealed in, sealed out; bitmaps stay native), with `DartImageProcessor`/`DartRasterEngine` as fallback and test oracle (crop/rotate/resize/tone/filters, normalised coordinates, deterministic re-materialization). Phase 8: `EdgeDetectorImpl` over the `detectDocument` channel method; perspective + denoise execute natively. 23 tests. |
| `vault_app_core` | `UnlockSession` (auto-lock), create/add/reorder/delete, `CommitEdit` (retention + post-commit purge), switch/re-materialize versions. 32 tests. |
| `platform_android` | Kotlin: Keystore-bound KEK (StrongBox → TEE fallback, auth-bound), Argon2id (argon2kt), HKDF, per-chunk AES-256-GCM session, BiometricPrompt device-credential gate, `FLAG_SECURE`, device-lock probe. Phase 8 CV kernels (hand-written, no OpenCV): DLT homography + bilinear warp, bilateral denoise, document-quad detector (Otsu ? largest component ? convex hull ? 4-corner reduction); 8 JVM tests. Image pipeline (dokki/vault_imaging): streaming envelope decrypt → `inSampleSize` decode → EXIF bake → op pipeline → encode → streaming envelope seal, plus a native raster registry for the export size solver; rasters are dropped on lock. |
| `vault_export` | `ExportEngineImpl` (§11.3: validate → resolve → raster/pdf → size-solve → encode/compose → seal → record), `LayoutEngine`, `SizeSolver` (quality search + downscale rounds, `maxBytes` hard / `targetBytes` best-effort; the PDF path searches JPEG quality then effective DPI), quick/configured/Export-Again use cases, artifact retention + expiry GC, four built-in presets. 43 tests. |
| `vault_pdf` | `PdfComposerImpl` over `package:pdf`: exact mm placement from `PlacedCell`s, per-image decode → effective-DPI downsample → colour → JPEG at the probed quality, zero `/Info` metadata. 13 tests. |
| `app` | Onboarding (PIN + mandatory recovery passphrase), lock gate, vault grid with type filters and search, add via camera/gallery, entry detail (pages/sides, rotate, Enhance auto-crop (Phase 8), history, add page/back, delete), export sheet with presets + "all pages (PDF)" scope + history + share (neutral filenames), settings. Motion system (`core_ui/motion.dart`): staggered entrances, press feedback, fade-through gate transitions, hero cover grid→detail, optimistic rotate preview, PIN "verifying" wave; honours the OS reduce-motion setting. Adaptive vector launcher icon and matching splash. 4 widget tests. |
| `vault_sync` | Segment codec (JSONL, unknown-op preservation, `minReaderVersion` halt), `SegmentSealer` (256 KiB / 5 min), `SyncExecutor` (leases, full-jitter backoff, queue-wide pause on 429, dead-letter), `MergeReducer` (lineage-aware pointer arbitration, deterministic fork winner, tombstone-vs-edit, idempotent replay), `SyncEngine` (seal → upload → fetch → replay → download). 26 tests. |
| `vault_drive` | `GoogleDriveCloudProvider` over `googleapis` (drive.appdata, opaque names, routing-only `appProperties`, name-idempotent upload), `GoogleDriveAuth`, §9.7 error classification. 11 tests over an in-memory Drive backend. |
| `vault_app_core` (sync) | `SyncController` (`SyncQueuePort`: debounced kicks, pause-on-429, status stream) + `SyncSetup` (keyring upload/restore, §9.9). 7 + new tests. |

### Security posture of the current build

On a device with a secure lock screen the app uses `KeyManagerImpl` over the Kotlin bridge: a random device secret is sealed by an auth-bound Android Keystore AES-GCM key (`vault.kek.<epoch>`, StrongBox when available), and `KEK = HKDF(device_secret, salt = Argon2id(PIN))` wraps the master key — the PIN is a salt, never the key (§8.2). The recovery passphrase wraps the same master key under Argon2id(m = 256 MiB). SQLCipher is keyed with `K_db = HKDF(MK)` and the open **fails closed** unless `PRAGMA cipher_version` answers. Verified on the API 36 emulator: every blob is an Envelope-v1 file, the database header is ciphertext, and a grep of the app directory for fixture content finds nothing.

The keyring (wrapped keys + KDF parameters) lives in `files/vault/keyring/keyring.json` because it has to be readable *before* the database can be opened; `key_epochs` is a mirror kept for the `blobs.key_epoch` foreign key.

If the Kotlin channel is unavailable (tests, a host without the plugin), the composition root falls back to the dev-only `DartKeyManager` (PIN-derived key in software — architecture mistake M1) and Settings shows a red "Development build: software keys" card. A vault created under one backend is not opened by the other; `wrap_alg` records which one made it. Screenshots are blocked by `FLAG_SECURE` always; debug builds can allow capture for UI review with `adb shell settings put global dokki_allow_capture 1`.

Phase 9 hardening: key rotation works end to end (Settings → Rotate encryption keys: new master key under a new epoch, every blob header rewrapped, SQLCipher rekeyed; old epochs stay readable until the job finishes). Settings shows an amber warning when root/emulator/test-key signals are detected (T4, advisory only). Google Drive traffic is certificate-pinned to the four GTS roots (`network_security_config.xml`, SPKI digests computed from pki.goog). Clipboard values are cleared after 30 s (`core_ui/clipboard.dart`). `AnalyticsPort` ships as an allowlist with a no-op backend — no analytics SDK in v1.

Deviation from §8.3: the Keystore key is auth-bound with a 30 s validity window rather than per-use (`setUserAuthenticationParameters(0, …)`), so one device-credential prompt covers unwrapping every epoch; both factors remain mandatory.

The composition root probes `dokki/vault_imaging` at boot and falls back to the Dart reference pipeline when the plugin is absent (tests, non-Android hosts); both backends implement the same ports, so callers cannot tell which ran.

### Deviations from ARCHITECTURE.md

- `assets.current_version_id` has no `REFERENCES` clause: drift's codegen rejects the `assets ↔ asset_versions` cycle. Invariant I3 is enforced by the `trg_assets_current_*` triggers instead, which are stricter (same asset, materialized, not deletable while current).
- `BlobRef` carries `keyEpoch`, `wrappedDek`, `plaintextSha256`; `NewAsset`/`VersionCommit` carry the `BlobRef` so the `blobs` row is written from real header data in the same transaction.
- `EnvelopePurpose.meta` (6) added for `title_enc`/`note_enc`/`tags_enc`.
- `sync_log_ops` table added as the durable pre-seal buffer of the local op log.
- `ThumbnailIndex` port added so the thumbnail cache never touches the database directly.
- Sync op-log *emission* happens inside `EntryRepositoryImpl` transactions (§10.5): every mutation appends its op and kicks the `SyncQueuePort` after commit.
- The keyring is a JSON file outside the database (see above); the doc's `keyring.bin` sealed copy is the cloud form (Phase 7).
- `KeyManager.deriveDbKey()` and `importKeyring(pin:)` were added to the port: SQLCipher needs raw bytes, and a bootstrap needs a new PIN to wrap under.
- `VaultEntrySummary.coverVersionId` (the first live asset's current version) is part of the list read model, so the grid renders thumbnails from one query and follows rotations/reorders live.
- `RasterEngine` port added (prepare/encode over a `BlobHandle`) so the export pipeline never holds a bitmap in Dart; `ExportSourceResolver` port added so the engine resolves evicted versions through the re-materialization use case without importing `vault_app_core`.
- Export artifacts are sealed blobs (`StorageClass.exportArtifact`) shared through a swept `ShareCache` with neutral filenames (`dokki-<id8>.<ext>`); the share sheet is the only place plaintext leaves the vault (A8).
- **Envelope v1 revision (Phase 9):** the body-chunk AAD anchors to the immutable `stream_salt`, not the `header_tag`. The documented format made §8.6 rotation impossible (rewriting the header invalidates every chunk's AAD — found by the rotation end-to-end test). The header tag still authenticates the header; the salt anchors the body. Pre-release format change, no migration (no shipped users).
- `AddVersionOp` carries the blob-row fields (`blobKeyEpoch`, `blobWrappedDekBase64`, `blobCiphertextSha256`, `blobCiphertextSize`): the receiver's FK demands a `blobs` row before the version row, and the file may not be downloaded for days.
- Pointer arbitration (`ASSET_CURRENT`) uses **lineage** to tell a fast-forward from a fork: if our pointer is an ancestor of the incoming version, the remote saw our state. This replaces §9.4's full observed-HLC causality for v1; `ENTRY_FIELD`, `PAGE_ORDER` and `ASSET_SET` conflicts are simplified to LWW-by-HLC (loser state survives in the op log). Deterministic convergence (P5/P6) is unaffected.
- Segment payloads are JSONL (named fields, unknown-op preserving) behind a codec seam, not CBOR; §9.6's forward-compat rules are honoured either way.
- Drive uploads rely on the googleapis library's resumable handling plus name-idempotent retries; manual `resume_token` plumbing is deferred.
- `BackgroundOp` stays refused in v1 (no ML background removal); the op type exists in recipes and non-deterministic versions are correctly marked and never re-materialized (Phase 3 handling, tested). A manual corner editor is the documented follow-up to a failed auto-detect.
- Background `SyncWorker` is **not shipped in v1** (R15 accepted): sync runs on app open, after every commit (debounced kick), and on demand. A headless WorkManager job cannot open the SQLCipher database without the user-auth-bound Keystore key — that is the design working as intended, not a bug.

## Development

```powershell
flutter pub get                                   # at repo root (pub workspace)
flutter analyze --fatal-infos
dart run tool/check_boundaries.dart               # forbidden-import CI gate
cd packages/vault_persistence; dart run build_runner build   # after editing tables/DAOs
flutter test                                      # per package under packages/, and in app/
cd app; flutter run                               # Android device or emulator (minSdk 26)
```

Each package under `packages/` is its own Dart package. Dependency direction is enforced by package `pubspec.yaml` allowlists (compile-time) and the boundary checker in CI.
