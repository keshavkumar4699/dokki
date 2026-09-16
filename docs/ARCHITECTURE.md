# Privacy-Focused Document Vault — Technical Architecture (v0.1, Pre-Implementation)

**Status:** Proposal for review. No substantial implementation until sign-off.
**Scope:** Flutter/Dart, Android-first. Offline-first. Optional user-owned Google Drive sync with client-side encryption.

---

## 0. Assumptions and Open Decisions

I have made the following assumptions. Each one is a lever that materially changes cost and design, so please confirm or correct before Phase 0 begins.

| # | Assumption | Why it matters | If wrong |
|---|---|---|---|
| A1 | `minSdk = 26` (Android 8.0), `targetSdk` current | Keystore AES-GCM, `StrongBox` at 28, `setUserAuthenticationParameters` at 30 | Below 26 forces a weaker key story and a fallback path |
| A2 | Multi-device sync is a **v1.x** goal, not v1.0 | Conflict machinery is ~30% of total complexity | If v1.0, Phase 7 moves earlier and Phases 4/8 slip |
| A3 | A **recovery passphrase is mandatory** before sync can be enabled | Without it, device loss = permanent data loss | If optional, we must ship a very loud irreversible-loss warning |
| A4 | Single user per vault (no sharing, no multi-tenant) in v1 | Removes key-sharing / re-encryption-for-recipient design | Sharing needs per-object key wrapping from day one |
| A5 | APK size budget allows OpenCV **only** from Phase 8, via ABI-split App Bundle | OpenCV adds ~20–40 MB per ABI | If budget is tight, Phase 8 needs a smaller CV kernel set written by hand |
| A6 | Drive scope will be `drive.appdata` (see §9.2) | Invisible, opaque, minimal privilege | `drive.file` if you want user-visible backup folders |
| A7 | No server component, ever, in v1 | No push notifications for sync, polling only | A relay server changes sync design substantially |
| A8 | Export output leaves the encrypted vault when the user shares it | This is intentional and unavoidable | Needs explicit UX warning, not an architecture change |

**Deliberate deviations from the brief**, flagged for approval:

1. The brief says an export record stores "source version ID" (singular). A single ID cannot represent an ID front+back export or a 12-page PDF. I model export sources as a **join table** (`export_record_sources`). See §6.
2. The brief implies edit history stores only outputs. I additionally store a declarative **edit recipe** per version. This costs a JSON column and buys re-materialization of evicted versions, future non-destructive editing, and far smaller sync payloads. See §10.3.
3. I recommend splitting the codebase into **local Dart packages**, not one package with folders. This is stricter than the brief's folder-tree request and is justified in §14.

---

## 1. Architecture Overview

### 1.1 The three ideas the whole system rests on

Everything else is detail. These three decisions are the ones that are expensive to reverse.

**Idea 1 — One shape for all five entry types.**
`PHOTO`, `ID`, `SIGNATURE`, `THUMBPRINT`, `DOCUMENT` are not five aggregates. They are one aggregate (`VaultEntry`) containing `Asset`s, where each asset carries a **role** (`PRIMARY`, `ID_FRONT`, `ID_BACK`, `PAGE`) and an **ordinal**. A photo is one asset with role `PRIMARY`. An ID is one or two assets with roles `ID_FRONT`/`ID_BACK`. A document is N assets with role `PAGE` and increasing ordinals.

The per-type rules (how many assets, which roles, whether ordering is meaningful) live in an `EntryTypeSpec` policy object, not in the schema and not in `if` statements scattered through the code. Adding `BUSINESS_CARD` or `CERTIFICATE` later is a new enum value plus a new spec. No migration, no domain rewrite.

**Idea 2 — Binaries are immutable and content-sealed; only pointers move.**
Every version's bytes are written once, encrypted once, and never modified. The "current version" is a pointer on the asset. Editing appends a new version and moves the pointer. Deleting a version never rewrites another one.

This collapses an entire category of problems. Cloud blobs become immutable too, which means the Device A v7 / Device B v8 conflict is never a byte-merge problem: both versions exist as distinct immutable objects, and the only thing in conflict is a pointer. Pointer conflicts are tractable. Byte conflicts are not.

**Idea 3 — Metadata syncs as an append-only operation log, never as a snapshot.**
Each device writes only to its own log segments in Drive. Devices never write to each other's files, so there are **zero file-level write conflicts** in the cloud. Merging happens locally by replaying every device's log against a deterministic reducer. Conflicts are detected semantically, during replay, using causality (hybrid logical clocks), not wall-clock timestamps.

Snapshot sync ("upload the DB, download the DB") loses updates silently and cannot be fixed later. This decision must be made now.

### 1.2 Secondary principles

- **Plaintext never enters the Dart heap at full resolution.** Decryption, decoding, and heavy pixel work happen in Kotlin. Dart receives previews, metadata, and file handles.
- **One envelope format for local-at-rest and cloud.** The sync engine uploads the exact bytes already on disk. It never decrypts anything, never needs a user-authenticated key, and therefore works correctly in a background WorkManager job.
- **Failures are values, not exceptions.** Domain and application layers return `Result<T, VaultFailure>`. Each infrastructure module has exactly one place where third-party exceptions are converted.
- **Every layer is testable with zero Android.** The domain package has no Flutter dependency. The sync engine is tested against a fake cloud provider that simulates 429s, partial writes, clock skew, and byte corruption.

### 1.3 What the architecture explicitly does not try to do

- It does not protect data on a rooted or malware-compromised device while the vault is unlocked.
- It does not prevent a hostile cloud from *withholding* updates (freshness/rollback by omission). It detects tampering and reordering, not silence. See §8.7.
- It does not guarantee exact export file sizes. It guarantees `maxBytes` as a hard constraint that may fail, and `targetBytes` as best effort.
- It does not attempt deduplication of identical documents across devices in v1 (a naive content-addressed scheme would leak the presence of known documents).

---

## 2. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION  (app/lib/features)                   │
│   Flutter widgets · Riverpod providers · GoRouter                           │
│   Knows: view models, ExportRequest builders, failure → message mapping     │
│   Forbidden: sqlite, dart:io paths, crypto, googleapis, image codecs        │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │ calls use cases, watches streams
┌───────────────────────────────▼─────────────────────────────────────────────┐
│                       APPLICATION LAYER  (vault_app_core)                   │
│   Use cases / orchestration · EditSession · UnlockSession · SyncController  │
│   Transaction boundaries · progress + cancellation · Result mapping         │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │ depends on interfaces only
┌───────────────────────────────▼─────────────────────────────────────────────┐
│                          DOMAIN LAYER  (vault_domain)                       │
│   Pure Dart. Zero I/O. Zero Flutter.                                        │
│   Entities: VaultEntry · Asset · AssetVersion · DocumentPage · ExportRecord  │
│   Policies: EntryTypeSpec · VersionRetentionPolicy · ConflictResolutionPolicy│
│   Value objects: ExportRequest · ImageOp · Quad · HybridLogicalClock         │
│   Failures: sealed VaultFailure                                             │
│   PORTS (interfaces): EntryRepository · BlobStore · CryptoEngine ·           │
│            ImageProcessor · PdfComposer · CloudProvider · KeyManager ·       │
│            ThumbnailProvider · ExportEngine · Clock · IdGenerator            │
└───────────────────────────────▲─────────────────────────────────────────────┘
                                │ implements ports  (dependency inversion)
┌───────────────────────────────┴─────────────────────────────────────────────┐
│                           INFRASTRUCTURE LAYER                              │
│                                                                             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌───────────────────┐   │
│  │vault_        │ │vault_storage │ │vault_imaging │ │vault_export       │   │
│  │persistence   │ │              │ │              │ │                   │   │
│  │Drift +       │ │Encrypted     │ │ImageOp →     │ │Pipeline · size    │   │
│  │SQLCipher     │ │blob store    │ │native / dart │ │solver · layout    │   │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └────────┬──────────┘   │
│         │                │                │                  │              │
│  ┌──────▼────────────────▼────────────────▼──────────────────▼──────────┐   │
│  │                        vault_crypto                                  │   │
│  │   KeyManager · Envelope v1 · streaming AEAD · key epochs · KDF       │   │
│  └──────────────────────────────┬───────────────────────────────────────┘   │
│                                 │                                           │
│  ┌──────────────┐ ┌─────────────▼────────┐ ┌──────────────────────────┐     │
│  │vault_sync    │ │ platform_android     │ │vault_pdf                 │     │
│  │engine: queue │ │ Kotlin plugin:       │ │PdfComposer impl          │     │
│  │HLC · merge · │ │ Keystore · StrongBox │ │(pdf pkg behind port)     │     │
│  │conflicts     │ │ Tink AEAD · Argon2id │ └──────────────────────────┘     │
│  │  ▲ CloudProvider port                 │ OpenCV (Ph.8) · WorkManager │     │
│  │  │                                    └──────────────────────────────┘   │
│  │  └── vault_drive  (googleapis impl)   ◄── the ONLY package that knows    │
│  └──────────────┘                            Google Drive exists            │
└─────────────────────────────────────────────────────────────────────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │  App-private storage      │   Google Drive appDataFolder
                    │  /data/data/<pkg>/        │   ┌───────────────────────┐
                    │   vault.db  (SQLCipher)   │   │ b_<uuid>.bin  (blobs) │
                    │   blobs/<uuid>  (Env v1)  │──▶│ l_<dev>_<seq>.bin(log)│
                    │   thumbs/<uuid> (Env v1)  │   │ m_keyring.bin         │
                    │   tmp/  (export scratch)  │   │ (opaque names only)   │
                    └───────────────────────────┘   └───────────────────────┘
```

### 2.1 Data flow: "user crops a document page"

```
Widget → CropPageUseCase(pageAssetId, Quad)
  → EntryRepository.loadAsset()                      [Drift, decrypted metadata]
  → BlobStore.openRead(currentVersion.blobId)        [returns handle, NOT bytes]
  → ImageProcessor.apply(handle, [PerspectiveOp, CropOp])
        → Kotlin: decrypt-stream → decode → transform → encode → encrypt-stream
        → returns new blobId + dimensions + plaintext hash
  → AssetVersion.derive(parent, recipe)              [pure domain]
  → EntryRepository.commitVersion(...)               [single Drift transaction:
                                                      insert version, move pointer,
                                                      enqueue sync op, apply retention]
  → VersionRetentionPolicy.evictable(graph, pins) → BlobStore.evict(...)
  → ThumbnailProvider.invalidate(assetId)
  → stream emits updated AssetView → widget rebuilds
```

Note what the widget never sees: file paths, keys, bytes, SQL, blob IDs.

---

## 3. Module Boundaries

| Package | Owns | May depend on | Must never import |
|---|---|---|---|
| `vault_domain` | Entities, value objects, policies, ports, failures | *(nothing but `meta`, `collection`)* | Flutter, dart:io, drift, googleapis, any codec |
| `vault_app_core` | Use cases, sessions, orchestration, transaction scripts | `vault_domain` | Any concrete infra package, Flutter widgets |
| `vault_crypto` | Envelope format, `KeyManager`, KDF params, key epochs, rotation | `vault_domain`, `platform_android` | drift, googleapis, image libs |
| `vault_persistence` | Drift DB, DAOs, migrations, `*Repository` impls | `vault_domain`, `vault_crypto` | googleapis, image libs, Flutter widgets |
| `vault_storage` | Encrypted blob CRUD, atomic writes, temp/GC, thumbnails cache | `vault_domain`, `vault_crypto` | drift, googleapis |
| `vault_imaging` | `ImageOp` execution, decode specs, `EdgeDetector` port + impls | `vault_domain`, `vault_crypto`, `platform_android` | drift, googleapis, pdf |
| `vault_pdf` | `PdfComposer` implementation | `vault_domain`, `vault_imaging` | drift, googleapis |
| `vault_export` | Pipeline, size solver, layout engine, `ExportEngine` impl | `vault_domain`, `vault_imaging`, `vault_pdf`, `vault_storage` | drift (writes go through a repo port), googleapis |
| `vault_sync` | Queue, scheduler, backoff, HLC, log replay, conflict detection | `vault_domain`, `vault_crypto` | googleapis, drift concretes |
| `vault_drive` | `CloudProvider` implementation for Google Drive | `vault_domain`, `vault_sync` (port only) | drift, image libs, Flutter widgets |
| `platform_android` | Kotlin: Keystore, StrongBox, Tink, Argon2id, OpenCV, WorkManager, FLAG_SECURE | Flutter plugin API | *(no Dart business logic at all)* |
| `app` | Widgets, Riverpod wiring, GoRouter, DI composition root | everything | *(nothing forbidden, but see §3.1)* |

### 3.1 The one place everything meets

`app/lib/bootstrap/composition_root.dart` is the **only** file allowed to import concrete infrastructure. It constructs the object graph and hands ports to Riverpod providers. If a second file starts importing `vault_drive`, the boundary has been breached.

### 3.2 How the boundary is enforced

Folder conventions get violated. Compiler errors do not. Because `vault_domain` is a separate package that does not list `drift` or `googleapis` in its `pubspec.yaml`, **a developer physically cannot import them**. That is the entire reason for the package split, and it is worth the extra `pubspec.yaml` files.

Enforcement stack:
1. Package-level `pubspec.yaml` dependency allowlists (compile-time, hard).
2. `custom_lint` / `import_lint` rules for intra-package rules like "no `Ref` in `application/`" (CI, soft).
3. A CI script that greps `app/lib/features/**` for forbidden imports (`drift`, `googleapis`, `dart:io`, `package:crypto`) and fails the build.

---

## 4. Dependency Direction

```
          app  (Flutter)
            │
            ▼
      vault_app_core
            │
            ▼
      vault_domain   ◄──────── ALL arrows point here. It points at nothing.
            ▲
            │ (implements)
   ┌────────┼────────┬──────────┬──────────┬──────────┐
vault_    vault_   vault_    vault_     vault_     vault_
persistence storage imaging   export     sync       crypto
                                 │          │          │
                              vault_pdf  vault_drive  platform_android
```

Rules:

1. **Dependencies point inward.** Infrastructure depends on domain. Domain depends on nothing.
2. **Domain defines the interface; infrastructure names itself after it.** `CloudProvider` is a domain port; `GoogleDriveCloudProvider` is a `vault_drive` class. The domain has no idea Google exists.
3. **No sibling infrastructure dependencies except where listed.** `vault_persistence` must not call `vault_sync`. If persistence needs to enqueue a sync op, it calls a domain port (`SyncQueuePort`) that `vault_sync` implements.
4. **Cycles are a build failure**, not a code review comment. Dart's package system enforces this automatically.
5. The application layer orchestrates across ports; the domain layer never does I/O, not even through a port it defined. Entities are data + rules. Ports are called by use cases.

---

## 5. Domain Model

### 5.1 Entity graph

```
VaultEntry (aggregate root)
  ├─ id, type, title, note, tags[], createdAt, updatedAt, hlc, originDevice, deletedAt
  └─ assets: List<Asset>
        ├─ id, entryId, role, ordinal, currentVersionId, deletedAt, hlc
        └─ versions: List<AssetVersion>
              ├─ id, assetId, parentVersionId, kind(ORIGINAL|DERIVED), seq
              ├─ blobId (null ⇒ evicted), recipe, recipeDeterministic
              ├─ width, height, mime, plaintextSha256
              └─ createdAt, hlc, originDevice, evictedAt

ExportRecord (separate aggregate)
  ├─ id, entryId, requestSnapshot, resultMetrics, artifactBlobId?, retainArtifact
  └─ sources: List<(versionId, ordinal)>

Conflict (separate aggregate)
  └─ id, entityKind, entityId, localState, remoteState, provisionalWinner, resolvedAt
```

### 5.2 Core types

```dart
enum EntryType { photo, id, signature, thumbprint, document }

enum AssetRole { primary, idFront, idBack, page }

/// Declares the shape rules for a type. Adding a type = adding a spec.
final class EntryTypeSpec {
  final EntryType type;
  final Set<AssetRole> allowedRoles;
  final Map<AssetRole, ({int min, int max})> cardinality; // max = -1 ⇒ unbounded
  final bool ordinalIsMeaningful;       // true only for DOCUMENT
  final bool supportsCoordinatedEdit;   // true for ID
}

/// Examples
// photo      : {primary: (1,1)},                 ordinal irrelevant
// id         : {idFront: (1,1), idBack: (0,1)},  ordinal irrelevant, coordinated
// signature  : {primary: (1,1)}
// thumbprint : {primary: (1,1)}
// document   : {page: (1,-1)},                   ordinal meaningful
```

`EntryTypeSpec` is validated on every mutation by `EntryInvariants.check(entry, spec)`. The five specs live in one file, `entry_type_specs.dart`, roughly 40 lines.

### 5.3 Versions

```dart
enum VersionKind { original, derived }

final class AssetVersion {
  final VersionId id;
  final AssetId assetId;
  final VersionId? parentVersionId;   // null iff kind == original
  final VersionKind kind;
  final int seq;                       // monotonic per asset, gap-tolerant
  final BlobId? blobId;                // null ⇒ binary evicted, row retained
  final EditRecipe? recipe;            // ops applied to parent
  final bool recipeDeterministic;      // false for ML ops ⇒ cannot re-materialize
  final ImageMeta meta;                // w, h, mime, plaintextSha256, byteSize
  final Hlc createdHlc;
  final DeviceId originDevice;
  final DateTime? evictedAt;

  bool get isOriginal => kind == VersionKind.original;
  bool get isMaterialized => blobId != null;
  bool get canRematerialize => !isMaterialized && recipeDeterministic;
}
```

**`EditRecipe`** is the crucial addition. It is a serializable list of declarative ops:

```dart
sealed class ImageOp { const ImageOp(); }
final class CropOp        extends ImageOp { final RectN rect; }        // normalised 0..1
final class PerspectiveOp extends ImageOp { final Quad quad; }         // normalised
final class RotateOp      extends ImageOp { final int quarterTurns; }
final class BrightnessOp  extends ImageOp { final double delta; }      // -1..1
final class ContrastOp    extends ImageOp { final double factor; }
final class ExposureOp    extends ImageOp { final double ev; }
final class SharpenOp     extends ImageOp { final double amount; }
final class DenoiseOp     extends ImageOp { final DenoiseStrength s; }
final class ResizeOp      extends ImageOp { final int? w, h; final FitMode fit; }
final class FilterOp      extends ImageOp { final FilterId id; }
final class BackgroundOp  extends ImageOp { final BackgroundSpec spec; } // non-deterministic
```

Storing coordinates **normalised to 0..1** rather than pixels means a recipe recorded against a 4000px original still applies correctly to a 1000px preview. This is what makes live preview-then-commit possible without a second code path.

Detection is separate from application. `EdgeDetector.detect(handle) → Quad` is a port; the `Quad` it returns becomes a `PerspectiveOp`. Replacing OpenCV with a better model later changes detection quality but does not invalidate a single stored recipe.

### 5.4 Invariants (enforced in domain, asserted in tests, backed by DB constraints)

| # | Invariant | Enforced by |
|---|---|---|
| I1 | Exactly one `ORIGINAL` version per asset, forever | Partial unique index + `EntryInvariants` |
| I2 | An `ORIGINAL` version's `blobId` is never null and never changes | `BlobStore.evict` rejects originals; DB `CHECK` |
| I3 | `asset.currentVersionId` references an existing, materialized version of that same asset | FK + domain check on every commit |
| I4 | Every `DERIVED` version has a non-null `parentVersionId` | DB `CHECK` + domain |
| I5 | Every export record references ≥1 existing version row | FK `ON DELETE RESTRICT` |
| I6 | Within an entry, `(role, ordinal)` is unique among non-deleted assets | Partial unique index |
| I7 | A `DOCUMENT`'s page ordinals form a contiguous 0..n-1 sequence after any reorder | Reorder use case is transactional |
| I8 | Sync never replaces a causally-newer local state with an older remote one without recording a `Conflict` | Merge reducer + simulation tests |
| I9 | `retained-versions(asset) ≤ 1 original + 1 current + 3 derived + pinned` | `VersionRetentionPolicy` |
| I10 | A pinned version is never evicted | Eviction query joins `version_pins` |

### 5.5 Sessions (application layer, not domain)

- **`UnlockSession`** — holds the in-memory master key handle for the duration of an unlocked app session. Owns the auto-lock timer, clears on background/timeout, and is the single object the crypto layer asks "are we unlocked?".
- **`EditSession`** — accumulates `ImageOp`s against one or more assets, renders previews at reduced resolution, and commits atomically. For `ID` coordinated editing, one `EditSession` spans `ID_FRONT` and `ID_BACK` and commits both new versions in one DB transaction, so the pair never diverges halfway.

---

## 6. Database Schema

**Engine:** SQLite via **Drift**, with the whole file encrypted by **SQLCipher** (`sqlcipher_flutter_libs`). Full-database encryption means indexes, WAL, temp B-trees, and freelist pages are all covered. Column-level encryption alone leaks through all of those.

**Additional column-level encryption** is applied to `title`, `note`, and `tags` on top of SQLCipher. Rationale: those fields are the highest-value plaintext in the DB (`"Passport - Renewal 2027"` is more sensitive than a UUID), and this gives defence in depth if the DB key is ever weaker than the file key, and lets us sync those fields as opaque blobs without a second encryption path.

**Conventions:** IDs are UUIDv7 TEXT (time-ordered, good index locality). Timestamps are INTEGER epoch-millis UTC. Enums are TEXT, never INTEGER ordinals (renumbering an enum is a silent data corruption bug). HLCs are TEXT in sortable form `<48-bit-ms-hex>:<16-bit-counter-hex>:<deviceIdShort>`.

### 6.1 Core tables

```sql
-- ── Device & app metadata ────────────────────────────────────────────────
CREATE TABLE devices (
  id             TEXT    PRIMARY KEY,           -- UUIDv4, generated on install
  label          TEXT,                          -- user-facing, e.g. "Pixel 7a"
  is_self        INTEGER NOT NULL DEFAULT 0,
  created_at     INTEGER NOT NULL,
  last_seen_hlc  TEXT,
  last_synced_at INTEGER
);
CREATE UNIQUE INDEX ux_devices_self ON devices(is_self) WHERE is_self = 1;

CREATE TABLE app_meta (
  key   TEXT PRIMARY KEY,                       -- schema_version, active_key_epoch,
  value BLOB NOT NULL                           -- install_id, op_schema_version, ...
);

-- ── Key management ───────────────────────────────────────────────────────
CREATE TABLE key_epochs (
  epoch              INTEGER PRIMARY KEY,       -- monotonic, starts at 1
  created_at         INTEGER NOT NULL,
  retired_at         INTEGER,                   -- NULL = active
  wrap_alg           TEXT    NOT NULL,          -- 'KEYSTORE_AES_GCM_V1'
  wrapped_mk_device  BLOB    NOT NULL,          -- MK wrapped by Keystore KEK
  wrapped_mk_recovery BLOB,                     -- MK wrapped by Argon2id(passphrase)
  kdf_params_json    TEXT,                      -- {alg, m, t, p, salt} for recovery
  keystore_alias     TEXT    NOT NULL,
  strongbox          INTEGER NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX ux_key_epoch_active ON key_epochs(retired_at) WHERE retired_at IS NULL;

-- ── Vault ────────────────────────────────────────────────────────────────
CREATE TABLE vault_entries (
  id             TEXT    PRIMARY KEY,
  type           TEXT    NOT NULL,              -- PHOTO|ID|SIGNATURE|THUMBPRINT|DOCUMENT
  title_enc      BLOB,                          -- Envelope-v1 sealed, K_meta
  note_enc       BLOB,
  tags_enc       BLOB,                          -- sealed JSON array
  created_at     INTEGER NOT NULL,
  updated_at     INTEGER NOT NULL,
  updated_hlc    TEXT    NOT NULL,
  origin_device  TEXT    NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
  deleted_at     INTEGER,                       -- soft delete; tombstone row also written
  sync_state     TEXT    NOT NULL DEFAULT 'LOCAL_ONLY',
  CHECK (type IN ('PHOTO','ID','SIGNATURE','THUMBPRINT','DOCUMENT'))
);
CREATE INDEX ix_entries_type_live   ON vault_entries(type) WHERE deleted_at IS NULL;
CREATE INDEX ix_entries_updated     ON vault_entries(updated_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX ix_entries_hlc         ON vault_entries(updated_hlc);

CREATE TABLE assets (
  id                 TEXT    PRIMARY KEY,
  entry_id           TEXT    NOT NULL REFERENCES vault_entries(id) ON DELETE CASCADE,
  role               TEXT    NOT NULL,          -- PRIMARY|ID_FRONT|ID_BACK|PAGE
  ordinal            INTEGER NOT NULL DEFAULT 0,
  current_version_id TEXT    REFERENCES asset_versions(id)
                             ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED,
  created_at         INTEGER NOT NULL,
  updated_at         INTEGER NOT NULL,
  updated_hlc        TEXT    NOT NULL,
  origin_device      TEXT    NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
  deleted_at         INTEGER,
  CHECK (role IN ('PRIMARY','ID_FRONT','ID_BACK','PAGE')),
  CHECK (ordinal >= 0)
);
-- Invariant I6: no duplicate page ordering, and at most one of each singleton role
CREATE UNIQUE INDEX ux_assets_slot ON assets(entry_id, role, ordinal)
  WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX ux_assets_singleton ON assets(entry_id, role)
  WHERE deleted_at IS NULL AND role IN ('PRIMARY','ID_FRONT','ID_BACK');
CREATE INDEX ix_assets_entry ON assets(entry_id, ordinal) WHERE deleted_at IS NULL;

CREATE TABLE asset_versions (
  id                    TEXT    PRIMARY KEY,
  asset_id              TEXT    NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  parent_version_id     TEXT    REFERENCES asset_versions(id) ON DELETE RESTRICT,
  kind                  TEXT    NOT NULL,       -- ORIGINAL | DERIVED
  seq                   INTEGER NOT NULL,       -- monotonic per asset
  blob_id               TEXT    REFERENCES blobs(id) ON DELETE RESTRICT,
  recipe_json           TEXT,                   -- List<ImageOp>, NULL for ORIGINAL
  recipe_schema_version INTEGER NOT NULL DEFAULT 1,
  recipe_deterministic  INTEGER NOT NULL DEFAULT 1,
  width                 INTEGER NOT NULL,
  height                INTEGER NOT NULL,
  mime                  TEXT    NOT NULL,
  plaintext_sha256      BLOB    NOT NULL,
  plaintext_size        INTEGER NOT NULL,
  created_at            INTEGER NOT NULL,
  created_hlc           TEXT    NOT NULL,
  origin_device         TEXT    NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
  evicted_at            INTEGER,                -- binary reclaimed; row retained forever
  CHECK (kind IN ('ORIGINAL','DERIVED')),
  CHECK (kind = 'ORIGINAL' OR parent_version_id IS NOT NULL),   -- I4
  CHECK (kind = 'DERIVED'  OR (blob_id IS NOT NULL AND evicted_at IS NULL))  -- I2
);
CREATE UNIQUE INDEX ux_version_original ON asset_versions(asset_id) WHERE kind='ORIGINAL'; -- I1
CREATE UNIQUE INDEX ux_version_seq      ON asset_versions(asset_id, seq);
CREATE INDEX ix_versions_asset          ON asset_versions(asset_id, created_at DESC);
CREATE INDEX ix_versions_blob           ON asset_versions(blob_id);
CREATE INDEX ix_versions_live           ON asset_versions(asset_id) WHERE evicted_at IS NULL;

-- Retention pins. Explicit rows make the eviction query a simple anti-join.
CREATE TABLE version_pins (
  version_id TEXT    NOT NULL REFERENCES asset_versions(id) ON DELETE CASCADE,
  reason     TEXT    NOT NULL,   -- EXPORT_RETAINED|SYNC_PENDING|CONFLICT|USER|REMOTE_REF
  ref_id     TEXT    NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  PRIMARY KEY (version_id, reason, ref_id)
);
CREATE INDEX ix_pins_version ON version_pins(version_id);
```

### 6.2 Binary storage tables

```sql
CREATE TABLE blobs (
  id                TEXT    PRIMARY KEY,        -- opaque UUIDv4; also the filename
  storage_class     TEXT    NOT NULL,           -- ASSET|THUMBNAIL|EXPORT|SYNC_LOG
  rel_path          TEXT    NOT NULL,           -- 'blobs/ab/<uuid>' (2-char fan-out)
  envelope_version  INTEGER NOT NULL DEFAULT 1,
  key_epoch         INTEGER NOT NULL REFERENCES key_epochs(epoch) ON DELETE RESTRICT,
  wrapped_dek       BLOB    NOT NULL,           -- duplicate of file header, for recovery
  ciphertext_size   INTEGER NOT NULL,
  plaintext_size    INTEGER NOT NULL,
  ciphertext_sha256 BLOB    NOT NULL,           -- integrity + upload idempotency
  local_state       TEXT    NOT NULL,           -- PRESENT|EVICTED|REMOTE_ONLY|CORRUPT
  created_at        INTEGER NOT NULL,
  last_verified_at  INTEGER,
  CHECK (storage_class IN ('ASSET','THUMBNAIL','EXPORT','SYNC_LOG'))
);
CREATE UNIQUE INDEX ux_blobs_path ON blobs(rel_path);
CREATE INDEX ix_blobs_state ON blobs(local_state, storage_class);

CREATE TABLE thumbnails (
  id               TEXT    PRIMARY KEY,
  version_id       TEXT    NOT NULL REFERENCES asset_versions(id) ON DELETE CASCADE,
  size_class       TEXT    NOT NULL,            -- S(128) | M(384) | L(1024)
  blob_id          TEXT    NOT NULL REFERENCES blobs(id) ON DELETE RESTRICT,
  width            INTEGER NOT NULL,
  height           INTEGER NOT NULL,
  created_at       INTEGER NOT NULL,
  last_accessed_at INTEGER NOT NULL,
  CHECK (size_class IN ('S','M','L'))
);
CREATE UNIQUE INDEX ux_thumb_slot ON thumbnails(version_id, size_class);
CREATE INDEX ix_thumb_lru ON thumbnails(last_accessed_at);
```

### 6.3 Export tables

```sql
CREATE TABLE export_records (
  id                     TEXT    PRIMARY KEY,
  entry_id               TEXT    NOT NULL REFERENCES vault_entries(id) ON DELETE RESTRICT,
  request_json           TEXT    NOT NULL,      -- full ExportRequest, replayable
  request_schema_version INTEGER NOT NULL,
  -- denormalised for list/filter without parsing JSON. Intentional, not over-normalised.
  format                 TEXT    NOT NULL,      -- JPEG|PNG|WEBP|PDF
  layout                 TEXT,                  -- SINGLE|SIDE_BY_SIDE|VERTICAL|GRID
  paper_size             TEXT,                  -- A4|A5|LETTER|CUSTOM|NULL
  out_width              INTEGER,
  out_height             INTEGER,
  dpi                    INTEGER,
  quality                INTEGER,
  target_bytes           INTEGER,
  max_bytes              INTEGER,
  actual_bytes           INTEGER,
  page_count             INTEGER,
  status                 TEXT    NOT NULL,      -- SUCCESS|FAILED|CANCELLED
  failure_code           TEXT,
  warnings_json          TEXT,                  -- e.g. ["TARGET_SIZE_MISSED"]
  duration_ms            INTEGER,
  artifact_blob_id       TEXT    REFERENCES blobs(id) ON DELETE SET NULL,
  retain_artifact        INTEGER NOT NULL DEFAULT 0,
  artifact_expires_at    INTEGER,
  created_at             INTEGER NOT NULL,
  origin_device          TEXT    NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
  CHECK (status IN ('SUCCESS','FAILED','CANCELLED'))
);
CREATE INDEX ix_exports_entry  ON export_records(entry_id, created_at DESC);
CREATE INDEX ix_exports_recent ON export_records(created_at DESC);
CREATE INDEX ix_exports_expiry ON export_records(artifact_expires_at)
  WHERE artifact_blob_id IS NOT NULL;

-- Deviation from brief: an export may have many sources (ID front+back, N pages)
CREATE TABLE export_record_sources (
  export_id  TEXT    NOT NULL REFERENCES export_records(id) ON DELETE CASCADE,
  ordinal    INTEGER NOT NULL,
  version_id TEXT    NOT NULL REFERENCES asset_versions(id) ON DELETE RESTRICT,  -- I5
  PRIMARY KEY (export_id, ordinal)
);
CREATE INDEX ix_export_src_version ON export_record_sources(version_id);
```

Note the asymmetry the brief asked for: `export_records` rows are **never** capacity-limited, while `artifact_blob_id` is nullable and expirable. History is cheap; retained binaries are not.

### 6.4 Sync tables

```sql
CREATE TABLE sync_queue (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  op_type         TEXT    NOT NULL,   -- UPLOAD_BLOB|DOWNLOAD_BLOB|APPEND_LOG|
                                      -- FETCH_LOG|DELETE_REMOTE|VERIFY_REMOTE
  target_kind     TEXT    NOT NULL,   -- BLOB|LOG_SEGMENT|KEYRING
  target_id       TEXT    NOT NULL,
  idempotency_key TEXT    NOT NULL,
  priority        INTEGER NOT NULL DEFAULT 100,   -- lower runs first
  state           TEXT    NOT NULL DEFAULT 'PENDING',
  attempts        INTEGER NOT NULL DEFAULT 0,
  next_attempt_at INTEGER NOT NULL,
  last_error_code TEXT,
  last_error_at   INTEGER,
  resume_token    TEXT,               -- Drive resumable session URI
  bytes_done      INTEGER NOT NULL DEFAULT 0,
  bytes_total     INTEGER,
  lease_owner     TEXT,               -- worker/isolate id
  lease_expires_at INTEGER,
  created_at      INTEGER NOT NULL,
  CHECK (state IN ('PENDING','INFLIGHT','DONE','FAILED','DEAD'))
);
CREATE UNIQUE INDEX ux_sync_idem  ON sync_queue(idempotency_key);
CREATE INDEX ix_sync_ready ON sync_queue(state, next_attempt_at, priority);
CREATE INDEX ix_sync_lease ON sync_queue(lease_expires_at) WHERE state = 'INFLIGHT';

CREATE TABLE cloud_objects (
  blob_id           TEXT    PRIMARY KEY REFERENCES blobs(id) ON DELETE RESTRICT,
  remote_id         TEXT,              -- Drive fileId, NULL until first upload
  remote_name       TEXT    NOT NULL,  -- opaque: 'b_<uuid>.bin'
  remote_size       INTEGER,
  remote_checksum   TEXT,              -- Drive-reported, advisory only
  ciphertext_sha256 BLOB    NOT NULL,  -- ours, authoritative
  key_epoch         INTEGER NOT NULL,
  state             TEXT    NOT NULL,  -- LOCAL_ONLY|UPLOADING|UPLOADED|
                                       -- REMOTE_ONLY|MISSING|TAMPERED
  uploaded_at       INTEGER,
  verified_at       INTEGER,
  CHECK (state IN ('LOCAL_ONLY','UPLOADING','UPLOADED','REMOTE_ONLY','MISSING','TAMPERED'))
);
CREATE UNIQUE INDEX ux_cloud_remote ON cloud_objects(remote_id) WHERE remote_id IS NOT NULL;
CREATE UNIQUE INDEX ux_cloud_name   ON cloud_objects(remote_name);

CREATE TABLE sync_log_segments (
  device_id    TEXT    NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
  seq          INTEGER NOT NULL,
  remote_id    TEXT,
  remote_name  TEXT    NOT NULL,       -- 'l_<devShort>_<seq>.bin'
  blob_id      TEXT    REFERENCES blobs(id) ON DELETE RESTRICT,
  op_count     INTEGER NOT NULL DEFAULT 0,
  hlc_low      TEXT,
  hlc_high     TEXT,
  sealed_at    INTEGER,                -- NULL = still being appended to locally
  uploaded_at  INTEGER,
  applied_at   INTEGER,                -- NULL = fetched but not yet replayed
  PRIMARY KEY (device_id, seq)
);
CREATE INDEX ix_segments_unapplied ON sync_log_segments(applied_at) WHERE applied_at IS NULL;

CREATE TABLE sync_cursor (
  device_id        TEXT PRIMARY KEY REFERENCES devices(id) ON DELETE CASCADE,
  last_applied_seq INTEGER NOT NULL DEFAULT 0,
  last_applied_hlc TEXT
);

CREATE TABLE conflicts (
  id                  TEXT    PRIMARY KEY,
  entity_kind         TEXT    NOT NULL,  -- ASSET_CURRENT|ENTRY_FIELD|ASSET_SET|PAGE_ORDER
  entity_id           TEXT    NOT NULL,
  local_state_json    TEXT    NOT NULL,
  remote_state_json   TEXT    NOT NULL,
  provisional_winner  TEXT    NOT NULL,  -- LOCAL|REMOTE
  detected_at         INTEGER NOT NULL,
  detected_hlc        TEXT    NOT NULL,
  resolved_at         INTEGER,
  resolution          TEXT,              -- KEEP_LOCAL|KEEP_REMOTE|KEEP_BOTH|AUTO
  resolved_by_device  TEXT REFERENCES devices(id) ON DELETE SET NULL
);
CREATE INDEX ix_conflicts_open ON conflicts(entity_kind, entity_id) WHERE resolved_at IS NULL;

CREATE TABLE tombstones (
  entity_kind   TEXT    NOT NULL,        -- ENTRY|ASSET|VERSION|EXPORT
  entity_id     TEXT    NOT NULL,
  deleted_hlc   TEXT    NOT NULL,
  origin_device TEXT    NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
  purge_after   INTEGER NOT NULL,        -- deleted_at + TOMBSTONE_TTL (default 180d)
  PRIMARY KEY (entity_kind, entity_id)
);
CREATE INDEX ix_tombstones_purge ON tombstones(purge_after);
```

### 6.5 Deletion behaviour

| Relationship | Rule | Why |
|---|---|---|
| `assets → vault_entries` | `ON DELETE CASCADE` | Only fires during GC purge; normal delete is a tombstone |
| `asset_versions → assets` | `ON DELETE CASCADE` | Same |
| `asset_versions → asset_versions` (parent) | `ON DELETE RESTRICT` | Lineage must not be orphaned |
| `assets.current_version_id → asset_versions` | `RESTRICT`, deferred | Invariant I3; deferred breaks the insert cycle |
| `export_record_sources → asset_versions` | `ON DELETE RESTRICT` | **Invariant I5.** This is why eviction soft-deletes |
| `export_records.artifact_blob_id → blobs` | `ON DELETE SET NULL` | Artifact is disposable; the record is not |
| `*_versions.blob_id → blobs` | `ON DELETE RESTRICT` | Blob rows are never hard-deleted while referenced |
| `cloud_objects → blobs` | `ON DELETE RESTRICT` | Never lose the remote pointer while the blob exists |

**Two-stage deletion is the rule everywhere.** Stage 1 is a tombstone + `deleted_at`, immediate and reversible, synced to peers. Stage 2 is a purge job that runs after `purge_after`, hard-deletes rows, and reclaims files. Never skip to stage 2, or a peer that has been offline for a week will resurrect the entry on next sync.

### 6.6 Migration strategy

1. **Drift schema versions** with generated snapshots (`drift_dev schema dump` → `schema/drift_schema_vN.json`) and generated step-by-step migrators. Every version bump commits a new snapshot.
2. **Additive-only by default.** New columns are nullable or have defaults. Never rename a column; add the new one, backfill, deprecate the old one two releases later. Never reuse a dropped column's name.
3. **Enums are TEXT.** Adding a value is free. Unknown values encountered from a newer peer are preserved verbatim and rendered as "unknown", never coerced.
4. **Data migrations are separate from schema migrations.** Long-running backfills (re-thumbnailing, key rewrapping) are idempotent jobs in a `migration_jobs` table, resumable across app kills. A schema migration must never take more than a second or two, or users will kill the app mid-migration.
5. **Migration tests are mandatory**, one per step: open a real DB at `vN`, seed representative rows, migrate, assert schema + data. `drift_dev` generates the test harness.
6. **The sync op-log schema version is independent** of the DB schema version, and stored in `app_meta.op_schema_version`. A v1.2 device must be able to read v1.5 log segments. See §9.6.

### 6.7 On not over-normalising

`export_records` deliberately denormalises `format`, `dpi`, `quality`, and friends out of `request_json`. The full request is the source of truth for replay; the columns exist so the export-history list can sort and filter with one indexed query instead of parsing thousands of JSON blobs. I have not created lookup tables for formats, paper sizes, or filters; those are closed enums in code and belong there.


---

## 7. File-Storage Model

### 7.1 On-disk layout

```
/data/data/<package>/                          (app-private, no external storage, ever)
├── databases/
│   └── vault.db                               SQLCipher, WAL mode
├── files/
│   ├── blobs/
│   │   ├── 0a/0a3f1c8e-...-9b2d               Envelope v1 sealed asset bytes
│   │   ├── 0a/0a7e...                         2-char hex fan-out from the UUID
│   │   └── f3/f3c1...
│   ├── thumbs/
│   │   └── 4c/4c19...                         Envelope v1 sealed, same format
│   ├── logs/
│   │   └── l_a91f_0000012.bin                 Sealed, pending-upload log segments
│   └── keyring/
│       └── keyring.bin                        Sealed keyring backup (local copy)
└── cache/
    └── export_tmp/                            Scratch; cleared on launch and on lock
```

**No file extensions. No human-readable names. No directory named after a document type.** A filename is a UUIDv4 and nothing else. The fan-out directory is derived from the UUID's first two hex characters purely to avoid tens of thousands of entries in one directory on older filesystems.

`getFilesDir()` and `getCacheDir()` only. Never `getExternalFilesDir()`, never MediaStore, never a `.nomedia`-guarded public folder. App-private storage is the only thing the Android sandbox actually protects.

`android:allowBackup="false"` and `android:fullBackupContent` excluding everything. Auto Backup would otherwise ship the encrypted blobs to Google's servers under a key we do not control the lifecycle of, and, worse, it would ship them without our envelope versioning. If cloud backup is wanted, it is our sync engine, not Android's.

### 7.2 Envelope v1 format

Every sealed file on disk and every blob in Drive uses the same byte format. This is the single most important interoperability decision in the storage layer: **because the local file and the cloud blob are byte-identical, sync never decrypts anything.**

```
┌─ HEADER (authenticated, fixed + variable) ──────────────────────────────┐
│ magic          5B   "PVLT1"                                             │
│ envelope_ver   1B   0x01                                                │
│ alg_id         1B   0x01 = AES-256-GCM-HKDF-STREAMING, 256 KiB chunks   │
│ flags          1B   bit0 = compressed-before-encryption                 │
│ key_epoch      4B   big-endian uint32                                   │
│ purpose        1B   1=ASSET 2=THUMB 3=EXPORT 4=LOG 5=KEYRING            │
│ wrapped_dek_len 2B                                                      │
│ wrapped_dek    var  DEK sealed under K_<purpose> of this epoch          │
│ stream_salt    16B  random, HKDF salt for the streaming key             │
│ header_tag     16B  AES-GCM tag over all preceding header bytes, DEK    │
└─────────────────────────────────────────────────────────────────────────┘
┌─ BODY: STREAM chunks ───────────────────────────────────────────────────┐
│ chunk[0]  ... chunk[n]                                                  │
│   each: 256 KiB plaintext → ciphertext + 16B tag                        │
│   nonce = 7B random prefix (from header) || 4B BE counter || 1B final   │
│   AAD   = header_tag || counter || final_flag                           │
└─────────────────────────────────────────────────────────────────────────┘
```

Why each piece exists:

- **`header_tag` covers the whole header**, so `alg_id`, `key_epoch`, and `flags` cannot be downgraded by an attacker who can write to the file. Without it, an attacker flips `alg_id` to a weaker algorithm we support in a future version.
- **Chunked streaming** keeps peak memory at ~256 KiB regardless of a 60 MB scan. Single-shot AES-GCM on a 60 MB file means a 60 MB plaintext buffer plus a 60 MB ciphertext buffer, which OOMs a 2 GB device.
- **The counter in the nonce** prevents chunk reordering. **The final-chunk flag** prevents truncation, which is otherwise an undetectable attack against naive chunked schemes.
- **`key_epoch` in the header** makes key rotation possible without re-encrypting file bodies. Rotation rewraps DEKs only.
- **`wrapped_dek` per file** means compromising one DEK compromises one file.

This is the [STREAM construction (Hoang–Reyhanitabak–Rogaway)](https://eprint.iacr.org/2015/189), which is what Tink's `AES256_GCM_HKDF_4KB`/`StreamingAead` implements. **We use Tink's implementation via the Kotlin bridge; we do not write our own.** The format above documents what Tink produces plus our header, so the format is auditable and re-implementable.

### 7.3 Write path (atomic, crash-safe)

```
1. Generate blobId (UUIDv4) and DEK (32B from SecureRandom).
2. Open tmp file at blobs/<fanout>/<uuid>.part
3. Stream plaintext → Tink StreamingAead → tmp, computing SHA-256 of ciphertext.
4. fsync(tmp); fsync(parent dir).
5. Insert `blobs` row (state = PRESENT) inside the same DB transaction as the
   `asset_versions` insert and the `assets.current_version_id` update.
6. rename(tmp → final)   [atomic on ext4/f2fs]
7. Commit DB transaction.
8. If the process dies between 6 and 7: an orphan file with no DB row. The
   startup GC sweep finds files with no matching `blobs.rel_path` and deletes them.
   If it dies between 5 and 6: a DB row with no file. Startup GC marks it CORRUPT
   and the version is flagged unavailable.
```

Orphan-in-both-directions reconciliation runs on every cold start, bounded to 200 ms, resuming across launches. Never trust that the last shutdown was clean.

### 7.4 Read path

The `BlobStore` port deliberately does **not** expose `Future<Uint8List> read(BlobId)`. That signature invites someone to pull a 60 MB decoded bitmap into the Dart heap.

```dart
abstract interface class BlobStore {
  /// Returns an opaque native-side handle. Bytes stay in Kotlin.
  Future<Result<BlobHandle, VaultFailure>> openRead(BlobId id);

  /// Streaming write with progress + cancellation.
  Future<Result<BlobRef, VaultFailure>> write(
    Stream<List<int>> source, {
    required StorageClass storageClass,
    required int expectedSize,
    ProgressSink? progress,
    CancellationToken? cancel,
  });

  /// Small payloads only (<256 KiB): keyring, log segments, encrypted titles.
  Future<Result<Uint8List, VaultFailure>> readSmall(BlobId id, {int maxBytes});

  /// Verify AEAD tags end-to-end without materialising plaintext.
  Future<Result<void, VaultFailure>> verify(BlobId id);

  Future<Result<void, VaultFailure>> evict(BlobId id);   // rejects ORIGINAL-backed
  Future<Result<void, VaultFailure>> purge(BlobId id);   // GC only
}
```

`BlobHandle` is passed to `ImageProcessor`, which is also native. Full-resolution plaintext therefore exists only in Kotlin `DirectByteBuffer`s, which we zero explicitly after use.

### 7.5 Thumbnails

Three size classes: `S` = 128 px longest edge (grid), `M` = 384 px (list/hero), `L` = 1024 px (preview before opening the editor). Generated lazily on first request, encrypted with the same envelope under `K_thumb`, tracked in `thumbnails` with an LRU column.

Thumbnails are **encrypted too.** A 128 px thumbnail of an Aadhaar card is still an image of an Aadhaar card, and "it's only a thumbnail" is exactly how vaults leak. They are also fully regenerable, so the LRU cache can be capped (default 250 MB) and evicted freely.

The UI asks `ThumbnailProvider.request(versionId, SizeClass.s)` and receives a `Stream<ThumbnailState>` (`loading` → `ready(ImageProvider)` / `failed`). It has no idea whether that came from cache, from a fresh decode, or from a downsampled re-decode of a 40 MP original.

### 7.6 Storage accounting and pressure

A `StorageBudget` service reports: originals, derived versions, thumbnails, retained export artifacts, sync scratch. When `getUsableSpace()` drops below a floor (default 300 MB), the app: (1) evicts thumbnails LRU, (2) drops expired export artifacts, (3) refuses new imports with `InsufficientStorage` **before** starting a write rather than failing halfway. Checking free space after writing 40 MB is how you end up with corrupt partial blobs.

---

## 8. Encryption and Key-Management Architecture

### 8.1 Key hierarchy

```
                    ┌───────────────────────────────────────┐
                    │   Android Keystore (TEE / StrongBox)  │
                    │   alias: vault.kek.<epoch>            │
                    │   AES-256-GCM, non-exportable,        │
                    │   setUserAuthenticationRequired(true)  │
                    └──────────────────┬────────────────────┘
                                       │ unwraps (requires biometric/credential)
   PIN ──Argon2id(m=64MiB,t=3,p=2)──┐  │
                                    ▼  ▼
                          KEK = HKDF-SHA256(
                              ikm  = keystore_unwrap_secret ,
                              salt = argon2id(pin, pin_salt) ,
                              info = "vault/kek/v1/<epoch>" )
                                       │
                                       ▼ AES-GCM unwrap
                    ┌──────────────────────────────────────┐
                    │      MASTER KEY  (MK, 256-bit)       │
                    │      random, never persisted raw     │
                    └──────────────────┬───────────────────┘
                                       │ HKDF-SHA256(MK, info=...)
        ┌──────────────┬───────────────┼───────────────┬──────────────┐
        ▼              ▼               ▼               ▼              ▼
     K_db          K_files          K_thumb         K_meta         K_cloud
  (SQLCipher     (wraps asset     (wraps thumb    (title/note   (wraps log +
   raw key)       DEKs)            DEKs)           columns)      keyring DEKs)
        │              │
        │              ▼  per-file random DEK, wrapped, stored in header + DB
        │         ┌──────────┐ ┌──────────┐ ┌──────────┐
        │         │  DEK_1   │ │  DEK_2   │ │  DEK_n   │
        │         └──────────┘ └──────────┘ └──────────┘

  RECOVERY PATH (independent, for device replacement):
     recovery passphrase ──Argon2id(m=256MiB,t=4,p=2, 16B salt)──▶ KEK_recovery
     KEK_recovery ──AES-GCM unwrap──▶ MK        (blob stored locally AND in Drive)
```

### 8.2 The rules this design encodes

**The PIN is never a key, and never the only factor.** A 6-digit PIN has ~20 bits of entropy. An attacker with the DB file and a GPU cracks it in seconds if the PIN alone protects anything. Here the PIN's Argon2id output is only the **HKDF salt**; the actual key material comes from the Keystore, which is hardware-bound, non-exportable, and rate-limited by the TEE. An attacker who extracts the database gets nothing without the device's secure element. An attacker who has the device but not the PIN gets nothing because the Keystore secret alone is insufficient. Both are required.

**The recovery passphrase is a genuine password**, enforced at ≥ 6 Diceware words or equivalent, run through Argon2id with a memory cost high enough (256 MiB) to make offline cracking expensive. It is the only thing standing between a stolen Drive dataset and plaintext, so it cannot be a PIN.

**Per-file DEKs make rotation cheap.** Rotating MK means: generate MK', unwrap each DEK with the old `K_files`, rewrap with the new one, update `blobs.wrapped_dek` and file headers. That is a metadata-only pass over a few thousand short rows. Rotating without per-file DEKs would mean re-encrypting and re-uploading every blob, which nobody ever actually does, which means rotation never happens.

**No key ever crosses the method channel.** The Kotlin side holds MK in a `SecretKey` bound to a native-side session object; Dart holds only an opaque session token. `KeyManager` in Dart exposes `unlock()`, `lock()`, `isUnlocked`, `rotate()` and nothing that returns bytes.

### 8.3 Keystore configuration

```kotlin
KeyGenParameterSpec.Builder("vault.kek.$epoch",
        KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
    .setKeySize(256)
    .setRandomizedEncryptionRequired(true)
    .setUserAuthenticationRequired(true)
    .setUserAuthenticationParameters(0,                       // 0 = per-use auth
        KeyProperties.AUTH_BIOMETRIC_STRONG or KeyProperties.AUTH_DEVICE_CREDENTIAL)
    .setInvalidatedByBiometricEnrollment(true)
    .setIsStrongBoxBacked(strongBoxAvailable)                  // API 28+, with fallback
    .build()
```

`setIsStrongBoxBacked(true)` throws `StrongBoxUnavailableException` on most devices, so the builder is attempted twice and the outcome is recorded in `key_epochs.strongbox`. `setInvalidatedByBiometricEnrollment(true)` means adding a new fingerprint invalidates the key, which is correct security-wise and a support nightmare unless the recovery passphrase path exists. This is why A3 (mandatory recovery passphrase) is not negotiable.

**Devices with no secure lock screen** cannot use auth-bound Keystore keys. Policy: the app refuses to create a vault until a device lock is set, with a clear explanation. Falling back to a software-only key would silently downgrade every user's security to "PIN-derived", which is the failure mode this whole design exists to avoid.

### 8.4 Plaintext lifetime

| Where | Policy |
|---|---|
| MK | Kotlin `SecretKey` in a session object. Zeroed and released on lock, on `onStop` after the auto-lock timeout, and on `onTrimMemory(TRIM_MEMORY_UI_HIDDEN)` |
| DEKs | Unwrapped per operation, held for the duration of one stream, zeroed in a `finally` |
| Image plaintext | Native `DirectByteBuffer`s, explicitly zeroed after encode. Never a Dart `Uint8List` at full resolution |
| Preview bitmaps | Dart heap, but downsampled (≤ 1024 px). Accepted risk, bounded |
| Export output | `cache/export_tmp/`, sealed while at rest, decrypted only into the share intent's stream. Swept on every launch and on lock |
| SQLCipher | `PRAGMA cipher_memory_security = ON`, key passed as raw bytes and zeroed after `sqlite3_key` |

Dart offers no reliable memory zeroing (strings are immutable, the GC copies). That is precisely why key material lives in Kotlin.

### 8.5 Anti-leak measures

- `FLAG_SECURE` on the vault activity, plus `setRecentsScreenshotEnabled(false)` on API 33+. Applied always, not conditionally, because "only on sensitive screens" is a bug waiting to happen when a new screen is added.
- A logging facade (`VaultLog`) with a compile-time `kReleaseMode` guard and a `SensitiveValue<T>` wrapper whose `toString()` returns `***`. Key types, `BlobId`, `Uint8List`, and `ImageMeta` all wrap. A CI lint rejects raw `print`, `debugPrint`, and `log` outside the facade.
- No crash reporter in v1. When one is added, it must run through a scrubber and must never capture the file path, the entry title, or any `SensitiveValue`.
- Clipboard: any copied value is cleared after 30 s, and OCR/text export is out of scope for v1.
- `android:excludeFromRecents` is *not* used (it breaks navigation); `FLAG_SECURE` handles the screenshot concern.

### 8.6 Key rotation

Rotation is a first-class operation from day one because retrofitting it is impossible.

```
1. Generate MK' and a new Keystore alias vault.kek.<epoch+1>.
2. Insert key_epochs row (epoch+1), wrapped under both device and recovery KEKs.
3. Mark it active; mark the old epoch retired_at = now (both readable).
4. Enqueue a rewrap job: for each blob where key_epoch < active,
     unwrap DEK with K_files(old) → rewrap with K_files(new) → rewrite the
     file header in place (header is fixed-size except wrapped_dek, so we
     write a new header + copy body, then atomic rename) → update blobs row.
   Resumable, idempotent, batched, runs on charge+idle.
5. Rekey SQLCipher via PRAGMA rekey (this one does rewrite the whole DB;
   it is small, so acceptable).
6. When zero blobs reference the old epoch, delete the old Keystore alias.
```

Old epochs stay readable until the rewrap completes, so rotation is never a cliff. Triggers: user-initiated, passphrase change, suspected compromise, or a scheduled policy.

### 8.7 Threat model

| # | Threat | Protected? | Mechanism / limitation |
|---|---|---|---|
| T1 | **Stolen phone, locked** | **Yes** | Blobs + DB encrypted; MK needs Keystore (hardware, rate-limited) *and* PIN. Android FBE adds a second layer |
| T2 | **Stolen phone, unlocked and app open** | **No** | Nothing can protect an unlocked vault on an unlocked device. Mitigated by short auto-lock (default 60 s background), lock on screen-off, `FLAG_SECURE` |
| T3 | **Malicious app, no root** | **Yes** | Android sandbox isolates `/data/data/<pkg>`. No exported components, no content provider, no external storage, `allowBackup=false`. Share intents use a scoped `FileProvider` with per-URI grants |
| T4 | **Malicious app with root / compromised OS** | **No** | Out of scope. Root can read our memory while unlocked. We do add root/emulator/debugger *detection* as a warning signal in Phase 9, not as a defence |
| T5 | **Stolen Google Drive files** | **Yes** | Every blob is AES-256-GCM sealed under a key never sent to Google. Filenames opaque, `appProperties` carry no semantics. Residual leak: object count, sizes, timestamps, activity pattern |
| T6 | **Compromised Google account** | **Yes (confidentiality)** / **Partial (availability + freshness)** | Attacker gets ciphertext only. They *can* delete blobs (denial of service) and *can* withhold newer segments (freshness attack, see below). They cannot forge a valid blob without a key |
| T7 | **Database extraction (adb, backup, forensics)** | **Yes** | SQLCipher full-file encryption; key not in the DB or in `SharedPreferences`. Leaks: row counts and file sizes, via the file's length |
| T8 | **Local blob file extraction** | **Yes** | Envelope v1 AEAD; header authenticated; no filename semantics |
| T9 | **Lost encryption key (Keystore wiped, biometric re-enrolled, app data cleared)** | **Yes, if enrolled** | Recovery passphrase unwraps MK from the recovery blob stored locally + in Drive. **If neither the device key nor the passphrase survives, the data is permanently unrecoverable and we will not pretend otherwise** |
| T10 | **Device replacement** | **Yes** | New device: sign in to Drive → download keyring blob → enter recovery passphrase → unwrap MK → rewrap under the new device's Keystore → replay log segments → lazily fetch blobs |
| T11 | **Sync conflict / concurrent edits** | **Yes** | Immutable blobs + HLC causality + `conflicts` table. Nothing is overwritten or discarded silently (§9.5) |
| T12 | **Maliciously modified cloud blob** | **Yes (detect)** | GCM tag fails → `DecryptionFailed`, object marked `TAMPERED`, never surfaced as content. Chunk counter + final flag block reorder and truncation. `ciphertext_sha256` cross-check before decrypt |
| T13 | **Rollback / freshness attack** (serving an older *valid* segment, or withholding a new one) | **Partial** | We store `last_applied_seq` per device locally and refuse to go backwards, so replaying old segments is rejected. We **cannot** detect pure withholding by a hostile cloud. Documented limitation; a signed monotonic head would need a server we do not have |
| T14 | **Shoulder surfing / screenshots by another app** | **Partial** | `FLAG_SECURE` blocks screenshots and most screen capture; an accessibility-service-abusing app or a physical camera is out of scope |
| T15 | **Supply-chain (malicious dependency)** | **Partial** | Pinned versions, `pubspec.lock` committed, a small allowlist of deps, license + provenance review per dep (§15), no dep with network access inside the crypto or storage packages |
| T16 | **Coercion / rubber-hose** | **No** | Explicitly out of scope. No duress PIN, no hidden volume, in v1 |

**We do not invent cryptography.** Primitives: AES-256-GCM, HKDF-SHA256, Argon2id, SHA-256, `SecureRandom`. Constructions: Tink's `StreamingAead`, SQLCipher, Android Keystore. Every one is a published, reviewed, widely deployed design.


---

## 9. Google Drive Sync Architecture

### 9.1 The domain port

The domain knows about a `CloudProvider`, not about Google. `vault_drive` is the only package that has ever heard of `googleapis`. Adding Dropbox, WebDAV, or a self-hosted S3 later is a new package implementing the same port.

```dart
abstract interface class CloudProvider {
  String get providerId;                                    // 'google_drive'

  Future<Result<CloudAuthState, VaultFailure>> authState();
  Future<Result<void, VaultFailure>> ensureAuthorized();

  Future<Result<RemoteObject, VaultFailure>> put(
    String opaqueName,
    Stream<List<int>> ciphertext, {
    required int totalBytes,
    Map<String, String> routingProps = const {},            // NON-SENSITIVE ONLY
    String? resumeToken,
    ProgressSink? progress,
    CancellationToken? cancel,
  });

  Future<Result<Stream<List<int>>, VaultFailure>> get(String remoteId, {ByteRange? range});
  Future<Result<List<RemoteObject>, VaultFailure>> list({String? namePrefix, String? pageToken});
  Future<Result<void, VaultFailure>> delete(String remoteId);
  Future<Result<CloudQuota, VaultFailure>> quota();
}
```

Note that `put` takes a **ciphertext stream**. The port's type signature makes it impossible to hand plaintext to a cloud provider. That is a deliberate use of the type system as a security control.

### 9.2 Drive layout and scope

**Scope: `https://www.googleapis.com/auth/drive.appdata`.**

| | `drive.appdata` | `drive.file` |
|---|---|---|
| Visibility | Hidden from the user's Drive UI entirely | A visible folder the user can browse |
| Privilege | Access only to our own app folder | Access to files our app creates/opens |
| Leakage | Nothing visible to a shoulder-surfer or a family member sharing the account | Folder name + file count visible |
| Downside | User cannot manually back up or inspect | User can accidentally delete or move files |
| Quota | Counts against the user's Drive quota | Same |

I recommend `appdata` because invisibility is the privacy-preserving default, and because a user who can see the folder can also delete it by accident. **Risk to verify:** `drive.appdata` is a sensitive OAuth scope and production use requires Google's app verification, which takes weeks and needs a privacy policy, a demo video, and a justification. This is a schedule risk, not a design risk, but it must be started early (Phase 7 minus 8 weeks).

```
appDataFolder/
├── v1/
│   ├── keyring.bin                  MK wrapped under KEK_recovery + epoch metadata
│   ├── manifest.bin                 (optional bootstrap hint; opaque)
│   ├── blobs/
│   │   ├── b_3f2a...c91.bin         Envelope v1, byte-identical to local file
│   │   └── b_a017...4de.bin
│   └── logs/
│       ├── l_a91f_0000001.bin       device a91f, segment 1
│       ├── l_a91f_0000002.bin
│       └── l_7c33_0000001.bin       device 7c33, segment 1
```

**`appProperties` carry routing metadata only:** `{blobId, envVer, keyEpoch, ctSha256, size}`. Nothing else. Not the entry type, not a title, not a page count, not a MIME type. Google can read `appProperties`; treat them as public. All semantics live inside the encrypted log segments.

Uploaded MIME type is always `application/octet-stream`, which is also what an opaque blob should be.

### 9.3 Why an operation log, not a snapshot

```
   ✗ SNAPSHOT SYNC                          ✓ APPEND-ONLY LOG
   Device A uploads db.enc                   Device A writes ONLY  l_a91f_*
   Device B uploads db.enc  ← overwrites     Device B writes ONLY  l_7c33_*
   A's last hour is gone. Silently.          Neither can clobber the other.
                                             Merge = replay both locally.
```

Each device appends `SyncOp` records to its own current segment, seals the segment at 256 KiB or 5 minutes, uploads it, and starts a new one. Segments are **immutable once uploaded**, so upload is idempotent (re-uploading identical bytes under the same name is a no-op we detect by `ciphertext_sha256`).

```dart
sealed class SyncOp {
  final Hlc hlc;
  final DeviceId origin;
  final int opSchemaVersion;
}
final class UpsertEntryOp     extends SyncOp { /* id, type, sealed title/note, ... */ }
final class UpsertAssetOp     extends SyncOp { /* id, entryId, role, ordinal */ }
final class AddVersionOp      extends SyncOp { /* id, assetId, parentId, blobId, meta, recipe */ }
final class SetCurrentOp      extends SyncOp { /* assetId, versionId */ }
final class ReorderPagesOp    extends SyncOp { /* entryId, [assetId] in order */ }
final class EvictVersionOp    extends SyncOp { /* versionId  (binary only) */ }
final class TombstoneOp       extends SyncOp { /* entityKind, entityId */ }
final class ResolveConflictOp extends SyncOp { /* conflictId, resolution */ }
```

Replay is a deterministic reducer: `(state, ops sorted by HLC) → state`. Two devices that have seen the same set of segments arrive at byte-identical state. That property is what makes the sync engine testable.

### 9.4 Causality: hybrid logical clocks, never wall clock

Wall-clock `updatedAt` for conflict resolution fails on clock skew, on timezone changes, on manual clock adjustment, and on the very common case of two edits in the same millisecond. Use HLC:

```
hlc = (physicalMillis, logicalCounter, deviceId)

send/local-event:  pt = max(lastPt, now());
                   lc = (pt == lastPt) ? lastLc + 1 : 0
receive(remote):   pt = max(lastPt, remote.pt, now());
                   lc = ... (standard HLC update)
Total order: compare pt, then lc, then deviceId (deterministic tiebreak).
Causality:   a → b  iff  hlc(a) < hlc(b) AND a was observed before b.
```

HLC gives a total order for deterministic tiebreaking **and** stays close enough to wall time to be human-readable in a future conflict UI. For genuine concurrency detection, each mutable field also carries the HLC of the last write it observed; if neither side's write observed the other's, the writes are concurrent and a conflict is raised.

### 9.5 Conflict model

Because blobs are immutable, the "Device A v7 / Device B v8" scenario decomposes cleanly:

```
Offline:
  Device A: original → v5 → v6 → v7   (A sets current = v7)
  Device B: original → v5 → v6 → v8   (B sets current = v8)

After sync, the merged version graph is:

                    original
                       │
                      v5
                       │
                      v6
                     ╱    ╲
                   v7      v8            ← BOTH exist. Both blobs uploaded.
                                            Nothing was deleted.
Conflict is ONLY over the pointer: assets.current_version_id.
```

The merge reducer:

```
for each SetCurrentOp on asset X:
  if remote.hlc causally-after local.hlc      → apply remote (fast-forward)
  if local.hlc  causally-after remote.hlc     → keep local, no-op
  if concurrent:
      → insert `conflicts` row (ASSET_CURRENT, X, local=v7, remote=v8)
      → provisional winner = higher HLC, tiebreak deviceId  [deterministic:
        every device picks the SAME winner without communicating]
      → PIN both v7 and v8  (reason = CONFLICT)  ⇒ exempt from eviction
      → set current = provisional winner, flag asset as `hasOpenConflict`
```

Deterministic tiebreak matters more than which value wins. If Device A picks v7 and Device B picks v8, they never converge and will ping-pong forever. Highest-HLC-then-deviceId guarantees both reach the same answer with zero extra round trips.

Conflict classes and their policies:

| Class | Example | Policy |
|---|---|---|
| `ASSET_CURRENT` | Both set a different current version | Both preserved + pinned; deterministic provisional winner; user can change it |
| `ENTRY_FIELD` | Both renamed the entry | Last-writer-wins by HLC, **loser value retained** in the conflict row so nothing is lost |
| `ASSET_SET` | A added page 5, B deleted page 5 | Delete-wins only if the delete is causally after the add; otherwise conflict, page kept |
| `PAGE_ORDER` | Both reordered a document | Deterministic winner by HLC; the losing order is stored for manual restore |
| `TOMBSTONE_VS_EDIT` | A deleted the entry, B edited it | **Edit wins by default**, tombstone downgraded to a conflict. Deleting someone's edit silently is worse than an unexpected undelete |

The `conflicts` table and `ResolveConflictOp` exist from Phase 7 even though the manual-resolution UI is Phase 11+. The data model must record conflicts from day one or the eventual UI has nothing to show.

### 9.6 Forward compatibility of the log

A v1.2 device will encounter ops written by a v1.6 device. Rules:

1. Every op carries `opSchemaVersion`.
2. Ops are serialised with an extensible encoding (CBOR or protobuf, **not** hand-rolled JSON with positional assumptions).
3. **Unknown op types are preserved verbatim and skipped, never dropped.** The segment is re-persisted locally so that a later app upgrade can replay it correctly. Dropping unknown ops turns an old device into a silent data-loss machine.
4. Unknown fields on known ops are retained and echoed back on any re-emission.
5. A `minReaderVersion` field lets a future breaking change halt old devices with `SyncRequiresUpgrade` instead of corrupting state.

### 9.7 Queue, retry, and scheduling

```dart
final class RetryPolicy {
  static const base = Duration(seconds: 2);
  static const cap  = Duration(hours: 6);
  static const maxAttempts = 12;
  // Full jitter (AWS): sleep = random(0, min(cap, base * 2^attempt))
}
```

Full jitter, not plain exponential backoff. Plain backoff makes every device in a rate-limited state retry in lockstep, which is how a 429 becomes a sustained 429.

Error classification drives behaviour:

| Drive condition | Class | Action |
|---|---|---|
| `403 userRateLimitExceeded` / `429` | Throttled | Back off with jitter; honour `Retry-After`; pause the whole queue, not just this op |
| `5xx` | Transient | Retry with backoff |
| Network unreachable | Transient | Park queue, register a connectivity listener, resume on reconnect |
| `401` | Auth | Refresh token once; if that fails → `SyncAuthRequired`, surface to user, stop |
| `403 storageQuotaExceeded` | Terminal-ish | Stop uploads, surface `CloudQuotaExceeded`, keep downloads running |
| `404` on a known `remote_id` | Remote deleted | Mark `cloud_objects.state = MISSING`; if we hold the blob, re-upload; if not, mark the version unavailable and raise a conflict |
| Ciphertext hash mismatch | Integrity | Mark `TAMPERED`, quarantine, never decrypt, alert |

**Leases** (`lease_owner`, `lease_expires_at`) stop a foreground sync and a WorkManager job from processing the same op. Claiming an op is a conditional `UPDATE ... WHERE state='PENDING' AND ...` inside a transaction.

**Scheduling:** `WorkManager` with `NetworkType.UNMETERED` (configurable), `requiresBatteryNotLow`, and a periodic 6-hour cadence plus an expedited one-shot after user edits. Because uploads move already-sealed bytes, the background worker never needs MK and therefore never needs the user to be present. This is the payoff from §7.2.

### 9.8 Upload, download, and interruption

**Upload:** files under 5 MB use simple upload; larger use Drive's resumable protocol. The session URI goes into `sync_queue.resume_token` **before** the first byte is sent, so a crash mid-upload resumes rather than restarts. On resume, query the session for the committed byte offset and continue.

**Download:** stream to `files/tmp/<uuid>.part`, verify `ciphertext_sha256` against `cloud_objects`, then verify the AEAD tags via `BlobStore.verify`, then atomically rename into `blobs/`. A partially downloaded file is never visible under a real blob path, so an interrupted download can never be mistaken for a corrupt blob.

**Deletion and GC:** `TombstoneOp` marks the entity deleted everywhere. A remote blob is only deleted from Drive when (a) its tombstone is older than `TOMBSTONE_TTL` (180 days) and (b) every device in `devices` has a `sync_cursor` past the tombstone's HLC. If a device has been silent for longer than a configured horizon, the user is asked to forget it explicitly. Deleting a blob a peer still references is unrecoverable; waiting is free.

### 9.9 Bootstrap on a new device

```
1. Sign in to Google, grant drive.appdata.
2. list('v1/') → find keyring.bin. If absent, this is a fresh vault.
3. Download keyring.bin → prompt for recovery passphrase → Argon2id → unwrap MK.
4. Generate a device Keystore KEK; rewrap MK under it; write key_epochs locally.
5. Register this device (new deviceId) and append a DeviceJoinedOp.
6. list('v1/logs/') → download ALL segments → replay in HLC order → full metadata.
7. Blobs download lazily: thumbnails first (small, makes the grid usable in
   seconds), then originals on demand or on a background "download all" toggle.
```

Step 7 is what makes restore feel fast. Downloading 4 GB of originals before showing anything is technically simpler and a terrible experience.

---

## 10. Version and History Model

### 10.1 The graph

Versions form a tree per asset (a DAG after a sync conflict merge, though in practice always a tree with at most one fork point). The `ORIGINAL` is the root and is permanent.

```
       ORIGINAL (seq 0)           permanent, never evicted, never modified
          │
         v1 (seq 1)               evicted  — blobId NULL, row + recipe retained
          │
         v2 (seq 2)               retained (history slot 1)
          │
         v3 (seq 3)               retained (history slot 2), PINNED by export E7
          │
         v4 (seq 4)               retained (history slot 3)
          │
         v5 (seq 5)   ◄── asset.current_version_id
```

### 10.2 Retention policy as a replaceable object

```dart
abstract interface class VersionRetentionPolicy {
  /// Pure function. No I/O. Trivially testable, trivially swappable.
  Set<VersionId> selectEvictable(VersionGraph graph, PinSet pins);
}

final class KeepOriginalCurrentAndNPolicy implements VersionRetentionPolicy {
  const KeepOriginalCurrentAndNPolicy({this.historyDepth = 3});
  final int historyDepth;

  @override
  Set<VersionId> selectEvictable(VersionGraph g, PinSet pins) {
    final protected = <VersionId>{
      g.original.id,                      // never
      g.currentId,                        // never
      ...pins.pinned,                     // export-retained, sync-pending, conflict, user
    };
    final candidates = g.derived
        .where((v) => v.isMaterialized && !protected.contains(v.id))
        .sortedByDescending((v) => v.seq);          // newest history first
    return candidates.skip(historyDepth).map((v) => v.id).toSet();
  }
}
```

The number 3 appears in exactly one place, as a constructor default. Changing the policy to "keep 10", "keep by age", "keep by total bytes", or "keep everything on Pro tier" is a new class and a DI change. The brief asked for this to be changeable later without architectural surgery; a pure function behind an interface is how.

### 10.3 Eviction is soft, and why that is not optional

**Eviction deletes the binary. It never deletes the row.**

```sql
UPDATE asset_versions SET blob_id = NULL, evicted_at = ? WHERE id = ?;
-- then BlobStore.purge(oldBlobId)
```

If the row were deleted, `export_record_sources.version_id` (FK `RESTRICT`) would block the delete, and working around that block is how projects end up with orphaned export history and a broken "Export Again". Keeping the row costs ~200 bytes and preserves:

- Invariant I5 (every export references a real version).
- The lineage chain (`parent_version_id` never dangles).
- The **edit recipe**, which means an evicted deterministic version can be **re-materialized** from the original on demand:

```dart
Future<Result<BlobId, VaultFailure>> rematerialize(VersionId id) async {
  final chain = graph.pathFromOriginal(id);     // [original, v1, v2, ...]
  if (chain.any((v) => !v.recipeDeterministic)) {
    return Err(VersionNotRematerializable(id));  // e.g. an ML background removal
  }
  return imageProcessor.applyChain(originalHandle, chain.expand((v) => v.recipe!));
}
```

So "up to 3 previous versions" is a *storage* limit, not a *history* limit. The user sees their full edit history; the older entries just take a moment to recompute. That is a materially better product than three versions and a cliff, and it comes for free from storing recipes.

### 10.4 Pin sources

| Reason | Set when | Cleared when |
|---|---|---|
| `EXPORT_RETAINED` | An export with `retain_artifact = 1` uses the version | The artifact expires or is deleted |
| `SYNC_PENDING` | A blob has a `sync_queue` row not yet `DONE` | The upload completes |
| `CONFLICT` | The version is a side of an open `ASSET_CURRENT` conflict | The conflict is resolved |
| `USER` | The user explicitly stars a version | The user unstars |
| `REMOTE_REF` | A peer's log references it and that peer has not confirmed eviction | All peers pass the eviction HLC |

Pins are rows, so eviction is one indexed anti-join rather than five special cases scattered through the code.

### 10.5 Commit semantics

Every version commit is one Drift transaction:

```
BEGIN
  INSERT asset_versions (new derived version)
  UPDATE assets SET current_version_id = <new>, updated_hlc = <hlc>
  INSERT sync_queue  (UPLOAD_BLOB for the new blob)
  INSERT sync_log op (AddVersionOp + SetCurrentOp)
  -- retention runs here, inside the same transaction:
  UPDATE asset_versions SET blob_id=NULL, evicted_at=? WHERE id IN (<evictable>)
  DELETE FROM version_pins WHERE ... (expired)
COMMIT
-- only AFTER commit: BlobStore.purge(<evicted blob ids>)
```

Purging files after commit, never before, means a crash leaves orphan files (harmless, swept by GC) rather than DB rows pointing at deleted files (a broken vault).

For **coordinated ID edits**, `EditSession.commit()` produces both the front and back versions inside one transaction. Either both new versions exist or neither does.

---

## 11. Export Architecture

### 11.1 `ExportRequest`

```dart
final class ExportRequest {
  final ExportSource source;
  final OutputFormat format;              // jpeg | png | webp | pdf
  final RasterSpec? raster;               // null for pure-PDF pass-through
  final QualitySpec quality;
  final PageLayoutSpec? page;             // required iff format == pdf
  final ColorSpec color;                  // background fill, grayscale, bw
  final Map<String, Object?> extensions;  // forward-compat bag
  final int requestSchemaVersion;
}

/// Sealed — new export shapes are new subtypes, not new nullable fields.
sealed class ExportSource {}
final class SingleVersionSource  extends ExportSource { final VersionId versionId; }
final class IdPairSource         extends ExportSource { final VersionId? front, back; }
final class DocumentPagesSource  extends ExportSource { final List<VersionId> pages; }
final class CurrentOfEntrySource extends ExportSource { final EntryId entryId; }  // quick export

final class RasterSpec {
  final int? width, height;               // at most one may be null ⇒ aspect-preserved
  final DimensionUnit unit;               // px | mm | inch
  final int? dpi;                         // required when unit != px
  final FitMode fit;                      // contain | cover | stretch | pad
  final ResampleFilter filter;            // lanczos | bilinear | nearest
}

final class QualitySpec {
  final int? quality;                     // 1..100, encoder-specific
  final int? targetBytes;                 // best effort
  final int? maxBytes;                    // HARD constraint; failure is a failure
  final int minQualityFloor;              // default 40, don't produce mush
  final bool allowDownscale;              // if quality floor is hit, may we shrink?
}

final class PageLayoutSpec {
  final PaperSize paper;                  // a4 | a5 | letter | legal | custom(w,h,unit)
  final Orientation orientation;
  final EdgeInsetsMm margins;
  final double spacingMm;
  final LayoutMode layout;                // single | sideBySide | vertical | grid(r,c)
  final CellFit cellFit;                  // fitCell | fillCell | actualSize
  final bool centerContent;
}
```

`CurrentOfEntrySource` is what makes **quick export** a one-liner: open an entry, tap Export, and the engine resolves current versions for whatever asset shape that entry has. No editor, no configuration, one call.

### 11.2 `ExportResult`

```dart
final class ExportResult {
  final ExportId id;
  final BlobId? artifactBlobId;          // sealed in cache/export_tmp
  final Uri? shareUri;                   // FileProvider content:// with a scoped grant
  final OutputFormat format;
  final int actualBytes;
  final int outWidth, outHeight;
  final int? effectiveDpi;
  final int pageCount;
  final int appliedQuality;              // what the size solver actually landed on
  final List<ExportWarning> warnings;    // targetSizeMissed, qualityFloorReached,
                                         // upscaledBeyondSource, sourceEvicted,
                                         // aspectRatioAdjusted
  final Duration duration;
}
```

`warnings` is doing real work here. "We produced a 210 KB file when you asked for 200 KB" is a warning, not a failure, and the UI must be able to say so honestly.

### 11.3 Pipeline

```
ExportRequest
  │
  ├─▶ [1] Validate            ─ dimensions > 0, ≤ 20000 px, margins < paper,
  │                             pages exist, format/layout compatible
  │                             → InvalidExportDimensions | UnsupportedFormat
  ├─▶ [2] ResolveSource       ─ VersionId → materialized blob
  │                             evicted + deterministic → rematerialize
  │                             evicted + not deterministic → fall back to current
  │                                                          + SourceEvicted warning
  ├─▶ [3] Decode (native)     ─ decode at the smallest sufficient scale.
  │                             A 4000×3000 source for a 600×400 output decodes
  │                             at 1/4 via inSampleSize. Never decode full then shrink.
  ├─▶ [4] RasterPipeline      ─ apply recipe ops if not baked, resample, colour,
  │                             background fill, rotate
  ├─▶ [5] Layout (pdf only)   ─ pure geometry: paper → margins → cells → placement
  │                             Deterministic, unit-tested, zero pixels involved
  ├─▶ [6] Encode              ─ JPEG/PNG/WebP encoder, or PdfComposer
  ├─▶ [7] SizeSolver          ─ iterate toward targetBytes / maxBytes (§11.4)
  ├─▶ [8] Seal & record       ─ write sealed artifact, insert export_records +
  │                             export_record_sources, pin sources if retained
  └─▶ ExportResult
```

Steps 1, 2, 5 are pure Dart and unit-testable without a device. Steps 3, 4, 6 run in Kotlin. Step 7 orchestrates.

The entire pipeline runs off the platform thread with `ProgressSink` and `CancellationToken` threaded through every stage. Cancellation is checked between stages and between size-solver iterations; a cancelled export deletes its scratch file and records `status = CANCELLED`.

### 11.4 Size targeting, honestly

Compression cannot hit an exact byte count. The contract:

```dart
sealed class SizeOutcome {}
final class SizeMet         extends SizeOutcome { final int bytes; }
final class SizeApproximate extends SizeOutcome { final int bytes, target; }   // warning
final class SizeUnattainable extends SizeOutcome { final int bestBytes, floor; } // failure
```

Algorithm for lossy formats:

```
1. Encode at requested (or default 85) quality. If within tolerance → done.
2. Binary search quality in [minQualityFloor, 100], max 7 probes.
   Each probe is an encode-to-count, not an encode-to-disk.
3. If the floor is reached and still over maxBytes:
     - allowDownscale ? scale by sqrt(target/actual)*0.95 and restart (max 3 rounds)
     - else → SizeUnattainable → ExportFailure.sizeUnattainable
4. targetBytes: return the closest result ≤ target, with SizeApproximate if
   outside ±10%.
   maxBytes:    a result > maxBytes is a hard FAILURE, never silently returned.
```

PNG is lossless, so `maxBytes` on PNG can only be met by downscaling or by reducing to a palette. If neither is allowed, the request fails immediately at validation with a clear message rather than after 20 seconds of futile iteration.

PDF size control: downsample embedded images to the effective DPI needed for the target paper size (a 4000 px image on an A4 page at 300 DPI needs ~2480 px; anything beyond that is pure waste), then apply JPEG quality search per image, then optionally drop to grayscale.

### 11.5 Layout engine

Pure geometry, no pixels, fully unit-testable:

```dart
final class LayoutEngine {
  List<PlacedCell> layout(PageLayoutSpec spec, List<Size> contentSizes);
}
final class PlacedCell { final int pageIndex; final RectMm frame; final int contentIndex; }
```

A side-by-side ID on A4 with 10 mm margins and 8 mm spacing is arithmetic. Testing it requires no image, no PDF library, no device. This is why the layout step is separated from the composition step: the part most likely to have off-by-one bugs is the part easiest to test in isolation.

`PdfComposer` then takes `List<PlacedCell>` plus image handles and emits bytes. Swapping the PDF library changes `PdfComposer` and nothing else.

### 11.6 Presets without touching the core model

```dart
abstract interface class ExportPreset {
  String get id;
  String get displayName;
  bool appliesTo(EntryType type);
  ExportRequest build(ExportContext ctx);
}
```

Presets are a registry. "Aadhaar front+back A4", "Passport photo 35×45 mm @ 300 DPI", "Email-friendly 200 KB JPEG", "Print-quality PDF" are all `ExportPreset` implementations that emit an ordinary `ExportRequest`. The core domain never changes. A future passport-photo generator becomes a preset plus one new `ImageOp`, not a new subsystem.

### 11.7 Export history vs artifact retention

Two independent lifecycles, as the brief requires:

- **`export_records`**: unbounded, never auto-deleted. Cheap (a few hundred bytes). This is what powers "Export Again".
- **Artifacts**: opt-in (`retain_artifact`), with an expiry (`artifact_expires_at`, default 7 days), swept by GC, and holding a `EXPORT_RETAINED` pin on their source versions while alive.

"Export Again" resolves the source through a strategy:

```
exact version materialized      → use it
exact version evicted, det.     → rematerialize, use it
exact version evicted, non-det. → use asset's CURRENT version + SourceChanged warning
version row missing entirely    → MissingVersion failure (should be impossible, I5)
```

The user is always told which one happened. Silently exporting a different image than the one in the history record is the kind of bug that destroys trust in a document app.


---

## 12. Error-Handling Strategy

### 12.1 Failures are values

```dart
sealed class Result<T, E> { const Result(); }
final class Ok<T, E>  extends Result<T, E> { final T value; const Ok(this.value); }
final class Err<T, E> extends Result<T, E> { final E error; const Err(this.error); }
```

A hand-rolled 40-line `Result` with `map`, `flatMap`, `fold`, and `getOrElse`, not a functional-programming package. We need four methods, not a category theory library, and a dependency in `vault_domain` is a dependency in everything.

### 12.2 The failure hierarchy

```dart
sealed class VaultFailure {
  String get code;                 // stable, loggable, never localised: 'ASSET_CORRUPT'
  bool get isRetryable;
  Object? get cause;               // original exception, never surfaced to UI
  StackTrace? get trace;
}

// ── Asset & data ───────────────────────────────────────────────────────
final class InvalidAsset          extends VaultFailure { final String reason; }
final class CorruptFile           extends VaultFailure { final BlobId blobId; }
final class UnsupportedFormat     extends VaultFailure { final String mime; }
final class MissingVersion        extends VaultFailure { final VersionId id; }
final class VersionNotRematerializable extends VaultFailure { final VersionId id; }
final class EntryInvariantViolated extends VaultFailure { final String invariant; }

// ── Crypto ─────────────────────────────────────────────────────────────
final class EncryptionFailed      extends VaultFailure {}
final class DecryptionFailed      extends VaultFailure { final BlobId? blobId;
                                                         final bool tamperSuspected; }
final class KeyUnavailable        extends VaultFailure { final KeyUnavailableReason r; }
   // reasons: vaultLocked | keystoreInvalidated | biometricChanged |
   //          noDeviceLock | hardwareFailure
final class KeyRotationFailed     extends VaultFailure { final int fromEpoch, toEpoch; }

// ── Storage ────────────────────────────────────────────────────────────
final class InsufficientStorage   extends VaultFailure { final int neededBytes, availableBytes; }
final class StorageIoFailure      extends VaultFailure { final String op; }
final class DatabaseFailure       extends VaultFailure { final String op; }
final class MigrationFailed       extends VaultFailure { final int from, to; }

// ── Export ─────────────────────────────────────────────────────────────
final class InvalidExportDimensions extends VaultFailure { final String constraint; }
final class SizeUnattainable        extends VaultFailure { final int bestBytes, maxBytes; }
final class PdfGenerationFailed     extends VaultFailure { final int? pageIndex; }
final class ImageProcessingFailed   extends VaultFailure { final String opId; }

// ── Sync ───────────────────────────────────────────────────────────────
final class SyncAuthRequired      extends VaultFailure {}
final class SyncTransportFailure  extends VaultFailure { final int? httpStatus; }
final class CloudRateLimited      extends VaultFailure { final Duration? retryAfter; }
final class CloudQuotaExceeded    extends VaultFailure { final int? usedBytes, limitBytes; }
final class RemoteObjectMissing   extends VaultFailure { final String remoteId; }
final class RemoteObjectTampered  extends VaultFailure { final String remoteId; }
final class VersionConflict       extends VaultFailure { final ConflictId id; }
final class SyncRequiresUpgrade   extends VaultFailure { final int minVersion; }

// ── Lifecycle ──────────────────────────────────────────────────────────
final class OperationCancelled    extends VaultFailure {}
final class OperationInterrupted  extends VaultFailure { final String resumeToken; }
final class AuthenticationFailed  extends VaultFailure { final int attemptsRemaining; }
```

Because these are sealed, `switch` on a failure is exhaustive and the compiler tells us when a new failure type has no handling. That is the whole point of sealing.

### 12.3 One boundary per module

`try/catch` is **not** scattered. Each infrastructure package has exactly one translator:

```dart
// vault_persistence/lib/src/error_boundary.dart — the ONLY try/catch in the package
Future<Result<T, VaultFailure>> guardDb<T>(String op, Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on SqliteException catch (e, s) {
    return Err(switch (e.extendedResultCode) {
      787 || 1811 => EntryInvariantViolated._fk(op, e, s),   // FK constraint
      2067        => EntryInvariantViolated._unique(op, e, s),
      13          => InsufficientStorage._db(e, s),          // SQLITE_FULL
      11 || 26    => DatabaseFailure._corrupt(op, e, s),
      _           => DatabaseFailure._(op, e, s),
    });
  }
}
```

Analogous `guardCrypto`, `guardIo`, `guardDrive`, `guardNative`. A CI lint flags any `catch` outside a file named `error_boundary.dart`.

### 12.4 What each layer does

| Layer | Responsibility |
|---|---|
| Infrastructure | Catch the library exception, classify it, return `Err(VaultFailure)`. Never rethrow, never swallow |
| Domain | Return `Err` for rule violations. **Throws only for programmer errors** (a violated precondition is an `AssertionError`, not a `Result`) |
| Application | Compose `Result`s, decide retry vs surface, attach recovery actions, log the `code` (never the cause's message, which may contain a path) |
| Presentation | Exhaustive `switch` on `VaultFailure` → localised message + action. **Never** shows `e.toString()` |

### 12.5 Recovery actions

A failure that the user cannot act on is a dead end. Each failure maps to a `RecoveryAction`:

```dart
sealed class RecoveryAction {}
final class RetryNow          extends RecoveryAction {}
final class RetryLater        extends RecoveryAction { final Duration after; }
final class Reauthenticate    extends RecoveryAction {}
final class FreeUpSpace       extends RecoveryAction { final int neededBytes; }
final class RestoreFromCloud  extends RecoveryAction { final BlobId blobId; }
final class UseCurrentVersion extends RecoveryAction { final VersionId fallback; }
final class ContactSupport    extends RecoveryAction { final String diagnosticCode; }
final class NoActionPossible  extends RecoveryAction { final String explanation; }
```

`CorruptFile` on a blob that exists in Drive is `RestoreFromCloud`, and that is an entirely automatic self-heal. Designing for it now costs one field.

### 12.6 Isolate and native boundaries

`VaultFailure` subclasses are plain data and are `SendPort`-transferable, so an isolate can return `Result` directly instead of a stringified exception. `cause` and `trace` are dropped at the isolate boundary (they are not always transferable) and logged on the far side before sending.

`PlatformException` from Kotlin carries a stable `code` string that maps 1:1 onto a `VaultFailure` in a single `guardNative` translator. Kotlin never sends a message intended for a human.

---

## 13. Testing Architecture

### 13.1 The pyramid

```
        ┌─────────────────────────────────────────────┐
        │  Instrumented (androidTest)         ~20     │  Keystore, StrongBox,
        │  Real hardware required                     │  FLAG_SECURE, WorkManager
        ├─────────────────────────────────────────────┤
        │  Integration (flutter_test + real db) ~120  │  DB migrations, blob round
        │  In-memory SQLCipher, temp dirs             │  trips, export end-to-end
        ├─────────────────────────────────────────────┤
        │  Simulation                          ~40    │  Two virtual devices +
        │  Deterministic, seeded, no I/O              │  fake Drive, scripted chaos
        ├─────────────────────────────────────────────┤
        │  Unit + property                    ~500    │  Domain, policies, layout,
        │  Pure Dart, zero Flutter, <5s total         │  size solver, HLC, reducer
        └─────────────────────────────────────────────┘
```

The bottom tier must run in under five seconds or nobody will run it.

### 13.2 Determinism is a testability requirement

Three things are injected everywhere, from Phase 0, with no exceptions:

```dart
abstract interface class Clock { DateTime now(); }
abstract interface class IdGenerator { String newId(); }
abstract interface class RandomSource { void fill(Uint8List out); }
```

`DateTime.now()`, `Uuid().v7()`, and `Random.secure()` are banned outside the composition root; a CI lint enforces it. Without this, HLC tests are flaky, sync simulations are unreproducible, and "it failed once in CI" becomes unfixable. Retrofitting injected clocks into a finished codebase is miserable; doing it on day one is free.

### 13.3 Invariant / property tests

Using `glados` (or hand-rolled generators, which are fine and have no dependency cost). A generator produces a random but *valid* sequence of domain operations; the test asserts the invariants hold after every step.

```dart
Glados(any.operationSequence).test('all invariants hold after any operation sequence',
    (ops) {
  var vault = Vault.empty();
  for (final op in ops) {
    vault = vault.apply(op);
    expect(I1_exactlyOneOriginal(vault), isTrue);
    expect(I2_originalBytesUnchanged(vault), isTrue);
    expect(I3_currentPointsAtLiveVersion(vault), isTrue);
    expect(I5_exportsReferenceRealVersions(vault), isTrue);
    expect(I6_noDuplicatePageOrdinals(vault), isTrue);
    expect(I9_retentionBoundRespected(vault), isTrue);
  }
});
```

Named property tests, mapping directly onto the brief's list:

| Property | Statement |
|---|---|
| P1 | For any op sequence, the original version's `plaintextSha256` and `blobId` are unchanged from creation |
| P2 | `asset.currentVersionId` always resolves to a materialized version of that asset |
| P3 | Every `export_record` resolves ≥1 version row |
| P4 | Page ordinals of any document are a permutation of `0..n-1` |
| P5 | For any pair of divergent op logs, `replay(A ∪ B) == replay(B ∪ A)` (commutativity) |
| P6 | Replay is idempotent: `replay(ops + ops) == replay(ops)` |
| P7 | Merge never reduces the set of materialized versions except via an explicit `EvictVersionOp` |
| P8 | For any retention policy run, `original ∈ retained ∧ current ∈ retained ∧ pins ⊆ retained` |
| P9 | `decrypt(encrypt(x)) == x` for any byte length 0..8 MiB, including exact chunk boundaries |
| P10 | For any single-bit mutation of any sealed file, decryption fails |

P5 and P6 are the two properties that make sync trustworthy. If replay is commutative and idempotent, devices converge. If it is not, no amount of manual testing will find the cases where they do not.

### 13.4 Crypto tests

- **Known-answer tests** against NIST GCM vectors and RFC 9106 Argon2id vectors. If our wrapper is misusing the primitive, KATs catch it.
- **Tamper matrix**: for each region (magic, `alg_id`, `key_epoch`, `wrapped_dek`, `header_tag`, chunk 0 ciphertext, chunk 0 tag, chunk N tag), flip one bit and assert `DecryptionFailed(tamperSuspected: true)`.
- **Truncation**: remove the final chunk, remove the final tag, truncate mid-chunk → all must fail, none may return partial plaintext.
- **Reorder**: swap chunk 1 and chunk 2 → must fail.
- **Boundary sizes**: 0, 1, 255 KiB, 256 KiB exactly, 256 KiB + 1, 10 MiB, 60 MiB.
- **Nonce uniqueness**: 10⁶ seals under one DEK, assert no repeated nonce.
- **Key rotation**: seal under epoch 1, rotate to 2, assert old blobs still readable during and after; kill the process mid-rewrap and assert resumption.
- **Negative**: reject a downgraded `alg_id`, reject an unknown `envelope_version`, reject a `key_epoch` we have no key for (with `KeyUnavailable`, not `DecryptionFailed`).

### 13.5 The sync simulation harness

This is the single most valuable test artifact in the project and it is built in Phase 7, day one.

```dart
final sim = SyncSimulator(seed: 42)
  ..addDevice('A')
  ..addDevice('B')
  ..cloud = FakeCloudProvider(
      latency: LatencyModel.jittery(50, 400),
      failureRate: 0.15,
      failures: [Http429(retryAfter: 2), Http500(), PartialWrite(0.4),
                 ByteCorruption(1), ObjectVanished()],
      clockSkew: Duration(minutes: -37),   // B's clock is wrong. On purpose.
  );

sim.run([
  OnDevice('A', CreateEntry(type: document, pages: 3)),
  Sync('A'),
  Partition(['A'], ['B']),                          // go offline
  OnDevice('A', EditPage(0, [CropOp(...)])),        // → v7
  OnDevice('B', EditPage(0, [BrightnessOp(...)])),  // → v8
  Heal(),
  SyncAll(), SyncAll(),                             // two rounds to quiesce
]);

expect(sim.device('A').state, equals(sim.device('B').state));   // convergence
expect(sim.conflicts, hasLength(1));
expect(sim.allVersionBlobs, containsAll(['v7', 'v8']));         // nothing lost
expect(sim.device('A').conflicts.single.provisionalWinner,
       equals(sim.device('B').conflicts.single.provisionalWinner)); // deterministic
```

Scenarios in the suite: offline→online, three-way divergence, delete-vs-edit, upload interrupted at 40% then resumed, duplicate upload of an identical blob, download of a corrupted blob, a device that is 6 months stale, quota exhaustion mid-sync, a peer running a newer op schema, and clock running backwards.

### 13.6 Test doubles

| Port | Fake |
|---|---|
| `BlobStore` | `InMemoryBlobStore` with injectable corruption, full-disk, and slow-IO modes |
| `CloudProvider` | `FakeCloudProvider` (above). Also `RecordingCloudProvider` to assert we never send plaintext |
| `ImageProcessor` | `DeterministicImageProcessor`: applies ops to a tiny synthetic image, exact results |
| `PdfComposer` | `StructuralPdfComposer`: records placements without generating bytes |
| `KeyManager` | `TestKeyManager` with fixed keys, plus `FlakyKeyManager` for `KeyUnavailable` paths |
| `Clock` / `RandomSource` | `FakeClock` (advanceable), `SeededRandom` |

There is one test that exists purely as a security assertion: `RecordingCloudProvider` fails the suite if any byte handed to `put()` decodes as a valid JPEG/PNG/PDF header, or if any `appProperties` value matches an entry title from the fixture set.

### 13.7 Export testing without brittle goldens

JPEG encoders are not byte-reproducible across platform versions, so byte-exact golden files will fail on a different device and teach the team to ignore failures. Instead:

- **Structural assertions**: dimensions, format magic bytes, page count, file size band, EXIF absence.
- **Perceptual assertions**: SSIM ≥ 0.95 against a reference render, which catches "the image is upside down" and "the crop was ignored" without breaking on encoder revisions.
- **Layout goldens are byte-exact** because `LayoutEngine` emits pure numbers. `PlacedCell` lists serialise to JSON and compare exactly.
- **Size-solver tests** use a synthetic encoder with a known size curve, so the search algorithm is tested independently of any real codec.

### 13.8 Coverage targets and CI gates

| Package | Line coverage | Notes |
|---|---|---|
| `vault_domain` | 95% | Pure logic, no excuse |
| `vault_crypto` | 95% | Plus the full KAT + tamper matrix passing |
| `vault_sync` | 90% | Plus all simulation scenarios green |
| `vault_export` | 85% | Layout and solver at 95% |
| `vault_persistence` | 80% | Plus every migration step tested |
| `app` | 40% | UI, tested later, mostly by widget tests |

CI gates: format, analyze (fatal-infos), custom boundary lints, unit + property (< 60 s), integration, simulation, and a nightly instrumented run on two real devices (one low-end API 26, one current).

---

## 14. Folder Structure

### 14.1 Why packages instead of folders

The brief asks for a folder tree that does not become `screens/widgets/services`. Folders alone cannot deliver that, because a folder convention is enforced by discipline, and discipline degrades at 2 a.m. before a release. A **package** boundary is enforced by the compiler: if `vault_domain/pubspec.yaml` does not list `drift`, then `import 'package:drift/drift.dart'` in that package is a build error, not a code review comment.

The cost is real: ~11 extra `pubspec.yaml` files, a workspace tool, and slower initial setup. Given that this app's failure modes are "a key leaked into a log" and "the UI reached into SQLite", I judge the cost worth paying. Dart 3.6+ **pub workspaces** (`resolution: workspace`) reduce the overhead substantially compared to the old Melos-only approach.

If you would rather ship faster, the fallback is a single package with `lib/domain`, `lib/infrastructure`, etc., plus `import_lint` rules. It works; it just fails open instead of failing closed.

### 14.2 The tree

```
document_vault/
├── pubspec.yaml                         # workspace root
├── melos.yaml                           # or pub workspace config
├── analysis_options.yaml                # shared strict lints
├── tool/
│   ├── check_boundaries.dart            # CI: forbidden-import scanner
│   └── gen_schema_snapshot.sh
├── docs/
│   ├── ARCHITECTURE.md                  # this document
│   ├── THREAT_MODEL.md
│   ├── adr/                             # one file per decision, numbered
│   │   ├── 0001-append-only-sync-log.md
│   │   ├── 0002-per-file-deks.md
│   │   └── 0003-soft-eviction-of-versions.md
│   └── schema/drift_schema_v1.json
│
├── packages/
│   │
│   ├── vault_domain/                    # PURE. No Flutter. No I/O. The centre.
│   │   └── lib/
│   │       ├── vault_domain.dart        # the only public export surface
│   │       └── src/
│   │           ├── entries/             # VaultEntry, EntryType, EntryTypeSpec,
│   │           │                        # EntryInvariants
│   │           ├── assets/              # Asset, AssetRole, DocumentPageOrder
│   │           ├── versions/            # AssetVersion, VersionGraph, EditRecipe,
│   │           │                        # VersionRetentionPolicy, PinSet
│   │           ├── imaging/             # ImageOp (sealed), Quad, RectN, ImageMeta,
│   │           │                        # DecodeSpec, FilterId
│   │           ├── export/              # ExportRequest/Result/Preset, RasterSpec,
│   │           │                        # QualitySpec, PageLayoutSpec, PlacedCell
│   │           ├── sync/                # SyncOp (sealed), Hlc, Conflict, Tombstone,
│   │           │                        # SyncState, RetryPolicy
│   │           ├── security/            # KeyEpoch, LockState, SensitiveValue<T>
│   │           ├── ports/               # ALL interfaces live here, one file each
│   │           │   ├── entry_repository.dart
│   │           │   ├── blob_store.dart
│   │           │   ├── crypto_engine.dart
│   │           │   ├── key_manager.dart
│   │           │   ├── image_processor.dart
│   │           │   ├── edge_detector.dart
│   │           │   ├── pdf_composer.dart
│   │           │   ├── export_engine.dart
│   │           │   ├── thumbnail_provider.dart
│   │           │   ├── cloud_provider.dart
│   │           │   ├── sync_queue_port.dart
│   │           │   └── clock.dart        # Clock, IdGenerator, RandomSource
│   │           ├── failures/            # sealed VaultFailure + RecoveryAction
│   │           └── result.dart
│   │
│   ├── vault_app_core/                  # use cases; depends only on vault_domain
│   │   └── lib/src/
│   │       ├── entries/                 # CreateEntry, ImportAsset, DeleteEntry...
│   │       ├── editing/                 # EditSession, CommitEdit, CoordinatedIdEdit
│   │       ├── versions/                # SwitchCurrentVersion, RestoreVersion
│   │       ├── exporting/               # QuickExport, ConfiguredExport, ExportAgain
│   │       ├── documents/               # AddPage, ReorderPages, SelectPages
│   │       ├── security/                # UnlockSession, ChangePin, RotateKeys
│   │       ├── sync/                    # SyncController, EnableSync, ResolveConflict
│   │       └── settings/
│   │
│   ├── vault_crypto/
│   │   └── lib/src/{envelope,key_manager,kdf,rotation,error_boundary.dart}
│   ├── vault_persistence/
│   │   └── lib/src/{database,tables,daos,repositories,migrations,error_boundary.dart}
│   ├── vault_storage/
│   │   └── lib/src/{blob_store,paths,gc,thumbnails,budget,error_boundary.dart}
│   ├── vault_imaging/
│   │   └── lib/src/{native_processor,dart_processor,decode,detectors,error_boundary.dart}
│   ├── vault_pdf/
│   │   └── lib/src/{composer,fonts,error_boundary.dart}
│   ├── vault_export/
│   │   └── lib/src/{pipeline,layout_engine,size_solver,encoders,presets,recorder}
│   ├── vault_sync/
│   │   └── lib/src/{queue,scheduler,hlc,log_segments,replay,merge,conflicts,backoff}
│   ├── vault_drive/
│   │   └── lib/src/{drive_provider,auth,resumable_upload,mapping,error_boundary.dart}
│   │
│   └── platform_android/                # Flutter plugin, Kotlin-heavy
│       ├── lib/src/                     # thin Dart method-channel wrappers
│       └── android/src/main/kotlin/.../
│           ├── keystore/                # KeystoreKek, StrongBoxProbe, BiometricGate
│           ├── crypto/                  # TinkStreamingAead, Argon2idBridge
│           ├── imaging/                 # Decoder, OpPipeline, (Phase 8) OpenCvOps
│           ├── security/                # FlagSecure, RootSignals
│           └── work/                    # SyncWorker (WorkManager)
│
└── app/
    ├── lib/
    │   ├── main.dart
    │   ├── bootstrap/
    │   │   ├── composition_root.dart    # the ONLY file importing concrete infra
    │   │   ├── providers.dart           # Riverpod providers over ports
    │   │   └── app_lifecycle.dart       # auto-lock, FLAG_SECURE, memory pressure
    │   ├── routing/                     # GoRouter config + lock-gate redirect
    │   ├── l10n/
    │   ├── core_ui/                     # design tokens, shared widgets (PHASE 11)
    │   └── features/                    # each: presentation/ + view_models/ only
    │       ├── vault_list/
    │       ├── entry_detail/
    │       ├── capture_import/
    │       ├── editor/
    │       ├── export/
    │       ├── document_pages/
    │       ├── sync_settings/
    │       ├── conflict_resolution/
    │       ├── app_lock/
    │       └── settings/
    └── test/
```

### 14.3 Why each major folder exists

| Folder | Reason it exists |
|---|---|
| `packages/vault_domain/src/ports/` | One file per interface, all in one place, so "what can infrastructure do?" is answerable by `ls`. Ports scattered next to their entities get duplicated |
| `packages/vault_domain` has **no** `services/` | Services are where business logic goes to become untestable. Behaviour lives on entities and in named policies |
| `vault_app_core` separate from `vault_domain` | The domain must stay free of orchestration and transactions. Use cases need both, so they get their own package |
| `vault_crypto` separate from `vault_storage` | Crypto is auditable in isolation. Mixing it with file IO means an audit has to read the file-management code too |
| `vault_drive` separate from `vault_sync` | The brief's rule 7. The sync engine must be testable and shippable with zero Google dependencies |
| `vault_pdf` separate from `vault_export` | The brief's rule 9. Swapping the PDF library must not touch pipeline logic |
| `platform_android` has zero Dart logic | Kotlin is where plaintext and keys live. Keeping decisions out of it means the security-critical code is small and reviewable |
| `app/lib/features/*` contain only presentation | The brief's rule 6. If a feature folder ever grows a `repository.dart`, the boundary has failed |
| `app/lib/core_ui/` | Deliberately empty until Phase 11. Visual design is explicitly out of scope now |
| `docs/adr/` | The brief's rule 16. Every major decision gets a numbered, dated, one-page rationale |

---

## 15. Major Dependencies and Rationale

Every entry below answers: why, alternatives, maturity, maintenance risk, security implications, license. Anything not on this list needs the same analysis before it is added.

### 15.1 Persistence

**`drift` + `sqlite3_flutter_libs` + `sqlcipher_flutter_libs`**

- **Why:** Type-safe DAOs generated from Dart table definitions, compile-time-checked queries, first-class migration tooling with schema snapshots, transaction support, and streaming queries that drive the UI reactively. The brief's rule 10 (centralise persistence, no scattered raw SQL) is exactly what Drift delivers.
- **Alternatives:** `sqflite` (raw SQL everywhere, no migration tooling, rule 10 violated by default). `Isar` (fast, but a NoSQL model that fits our relational data badly, and its maintenance status has been unstable). `ObjectBox` (fast, commercial licensing considerations). `Realm` for Flutter (deprecated by MongoDB). `floor` (thin, low activity). Hand-rolled repository over `sqflite` (we would reimplement Drift, worse).
- **Maturity:** Drift is 6+ years old, heavily used, actively maintained by Simon Binder, excellent documentation.
- **Maintenance risk:** **Medium-low.** Effectively a single-maintainer project, which is the main concern. Mitigated by the fact that Drift generates ordinary SQLite; an escape hatch to raw `sqlite3` exists and the schema would survive.
- **Security:** Drift itself stores nothing; SQLCipher provides page-level AES-256. We must verify at runtime that the cipher is actually active (`PRAGMA cipher_version` non-empty) and **fail closed** if it is not, because a misconfigured SQLCipher silently writes a plaintext database.
- **License:** Drift MIT. SQLCipher Community Edition BSD-style (Zetetic). Acceptable for a commercial closed-source app; attribution required.

### 15.2 State management and navigation

**`flutter_riverpod`** — **Why:** compile-time-safe dependency injection, no `BuildContext` needed for reads, testable with `ProviderContainer` overrides, and `AsyncValue` models loading/error/data without a bespoke state class per screen. Confined to `app/`; no domain package imports it. **Alternatives:** `bloc` (more ceremony, excellent for complex flows, also a fine choice), `provider` (weaker typing), `signals` (young), plain `InheritedWidget` (too manual at this scale). **Maturity:** high, large ecosystem. **Risk:** low-medium; Riverpod has had breaking API rewrites between majors, so we pin and budget for one migration. **Security:** none directly, but a provider holding a decrypted buffer would be a leak, so `SensitiveValue` types are lint-enforced never to be provider state. **License:** MIT.

**`go_router`** — **Why:** declarative routes, deep links, and a `redirect` hook that gives us a single choke point for the lock gate ("if vault is locked and the route is not `/unlock`, redirect"). **Alternatives:** Navigator 2.0 raw (far too much boilerplate), `auto_route` (codegen, powerful, heavier). **Maturity:** high, maintained by the Flutter team. **Risk:** low. **Security:** the redirect gate is a security control; it gets its own tests. **License:** BSD-3.

### 15.3 Cryptography

**Google Tink (Java/Android), via `platform_android`**

- **Why:** `StreamingAead` (`AES256_GCM_HKDF_1MB`) is precisely the chunked-AEAD construction we need for large files, implemented by cryptographers, with nonce management and the STREAM framing handled correctly. Writing this ourselves is the highest-risk code in the project.
- **Alternatives:** Hand-rolled chunked GCM over JCA (we would be inventing framing, which the brief forbids in spirit). `libsodium` via `flutter_sodium`/FFI (secretstream is also excellent; adds an NDK build and a large binary; a genuinely reasonable alternative if Tink's status is a concern). Conscrypt directly (primitives only, no streaming construction). `pointycastle` in pure Dart (far too slow for 60 MB files and puts key material in the Dart heap — rejected).
- **Maturity:** high; used widely inside Google.
- **Maintenance risk:** **Medium — verify before committing.** My information on Tink's current maintenance cadence may be out of date. Before Phase 2, check the repository's recent activity and release history. If it has gone dormant, the fallback is libsodium `crypto_secretstream_xchacha20poly1305_*`, which is an equally sound construction with a different primitive; the envelope format's `alg_id` byte exists so this swap does not break existing files.
- **Security:** it *is* the security. Pin the version, verify checksums, review changelogs before upgrading.
- **License:** Apache 2.0.

**Argon2id** — via Tink/BouncyCastle or a small dedicated native binding. **Why:** the brief requires a proper KDF; Argon2id is the current recommendation (RFC 9106) and resists GPU/ASIC cracking far better than PBKDF2. **Alternatives:** scrypt (fine, older), PBKDF2-HMAC-SHA256 (weak against GPUs at any reasonable iteration count on mobile, rejected), bcrypt (password-length limits, not a KDF). **Params:** PIN path m=64 MiB/t=3/p=2; recovery passphrase path m=256 MiB/t=4/p=2, calibrated on a low-end device to stay under ~1.5 s and stored per-user in `kdf_params_json` so they can be raised later. **License:** CC0/Apache depending on the binding.

**`crypto` (Dart)** — SHA-256 for non-secret hashing (ciphertext digests, integrity checks) only. Never for key derivation. Dart team, BSD-3, zero risk.

### 15.4 Google Drive

**`googleapis` + `googleapis_auth` + `google_sign_in`** — **Why:** official generated Drive v3 client, official OAuth. **Alternatives:** raw `http` against the REST API (we would hand-write resumable upload, pagination, and error parsing; tempting for bundle size since `googleapis` is enormous, but error-prone). `google_sign_in` is effectively required on Android for the Credential Manager flow. **Maturity:** high; Dart team maintained. **Risk:** medium — `google_sign_in` went through a significant API redesign in v7 with a different Android integration path, so **verify the current API shape before Phase 7** rather than trusting any example older than a few months. **Security:** OAuth tokens live in the Keystore-backed store, never in `SharedPreferences`; request the narrowest scope (`drive.appdata`); handle revocation gracefully. **License:** BSD-3. **Bundle note:** import only `googleapis/drive/v3.dart`; the package tree-shakes acceptably.

### 15.5 Imaging

**Android platform decoders (`BitmapFactory`/`ImageDecoder`) via `platform_android`** — **Why:** hardware-accelerated, memory-efficient, `inSampleSize` lets us decode a 40 MP JPEG straight to 1024 px without ever allocating the full bitmap. This is the single biggest lever on low-end-device stability. **Alternatives:** the Dart `image` package (pure Dart, portable, 10–50× slower and allocates full-resolution buffers in the Dart heap). **Decision:** native primary, `image` retained as a fallback and as the deterministic reference implementation in tests. **License:** platform (n/a) / `image` is MIT.

**OpenCV — deferred to Phase 8.** **Why eventually:** edge detection, perspective transform, and adaptive thresholding are solved problems there. **Why not now:** 20–40 MB per ABI, an NDK build, and Phases 1–7 need none of it. **Alternatives when the time comes:** `opencv_dart` (convenient, adds FFI surface), the OpenCV Android SDK linked into our own plugin (more control, smaller custom build via a module-stripped `.so`), or hand-written kernels for just the four operations we need (Canny + Hough + `getPerspectiveTransform` + `warpPerspective`), which is maybe 400 lines of Kotlin and avoids the dependency entirely. **Recommendation:** ship Phases 1–7 with manual corner adjustment only, then evaluate. **License:** OpenCV is Apache 2.0 (4.5.0+).

### 15.6 PDF

**`pdf` (DavBfr) behind `PdfComposer`** — **Why:** pure Dart, no native build, good control over page geometry and image embedding, widely used. **Alternatives:** Android's `PdfDocument` (native, limited API, poor image compression control), PDFBox-Android (large, Apache, powerful, heavier), iText (AGPL/commercial — **rejected on license grounds** for a closed-source app). **Maturity:** high. **Risk:** medium (small maintainer team); mitigated entirely by the `PdfComposer` port, which is ~5 methods. **Security:** generates locally, no network; we must ensure no metadata (author, producer, creation path) leaks document names. **License:** Apache 2.0.

**`pdfrx` or `pdfx` for rendering** — only if PDF import is added. Deferred; not a Phase 0–7 dependency.

### 15.7 Background work

**`workmanager`** — **Why:** WorkManager is the only reliable way to run periodic background work across Android's Doze and OEM battery managers. **Alternatives:** our own Kotlin `Worker` in `platform_android` calling back into a Dart isolate (more code, full control, no third-party maintenance risk). **Risk:** medium; the plugin has had periods of slow maintenance and Flutter-engine-version sensitivity around background isolates. **Recommendation:** start with the plugin, but keep the `SyncScheduler` port narrow (3 methods) so replacing it with our own Worker is a one-day job. **License:** MIT.

### 15.8 Supporting

| Package | Why | Risk | License |
|---|---|---|---|
| `freezed` + `json_serializable` + `build_runner` | Sealed classes, unions, `copyWith`, and (de)serialisation without hand-written boilerplate for ~60 value types | Low; codegen only, output is readable Dart | MIT/BSD |
| `uuid` | UUIDv4 (blob names) and UUIDv7 (index-friendly entity IDs) | Low | MIT |
| `cbor` | Op-log serialisation: compact, schema-evolvable, preserves unknown fields | Low-medium; evaluate vs `protobuf` in Phase 7 | MIT |
| `collection` | `sortedBy`, `firstWhereOrNull`, equality helpers | Nil; Dart team | BSD-3 |
| `path` / `path_provider` | Platform directory resolution | Nil | BSD-3 |
| `local_auth` | BiometricPrompt wrapper | Low; verify it surfaces `AUTH_DEVICE_CREDENTIAL` fallback | BSD-3 |
| `connectivity_plus` | Wake the sync queue on reconnect | Low | BSD-3 |
| `glados` | Property-based testing | Low; dev-only | MIT |
| `custom_lint` / `import_lint` | Boundary enforcement in CI | Low; dev-only | MIT |

### 15.9 Explicitly rejected

| Rejected | Reason |
|---|---|
| Any analytics SDK (Firebase, Amplitude, Mixpanel) | Brief's privacy requirement. A future `AnalyticsPort` with an events allowlist can be added; no SDK ships in v1 |
| Firebase Crashlytics | Ships stack traces and device metadata to Google before we have a scrubber. Revisit in Phase 9 with a scrubbing layer |
| `flutter_secure_storage` | Too coarse: no StrongBox control, no auth-bound keys, no streaming AEAD. We need a real Keystore bridge anyway, so this would be a redundant dependency in the most security-critical path |
| `flutter_rust_bridge` | Would give excellent crypto and imaging options, but adds a Rust toolchain to CI and the team. Not justified when Kotlin + Tink covers it |
| `hive` / `shared_preferences` for anything sensitive | `hive` boxes are unencrypted by default and its encryption story is weaker than SQLCipher; `shared_preferences` is plaintext XML |
| `dio` | `http` plus the `googleapis` client covers our needs; `dio` interceptors are a tempting place for someone to log request bodies |
| iText | AGPL or paid commercial license |
| Any OCR/AI SDK | Brief's rule 14 and the privacy requirement. Designed for (§17, Phase 8+) but not shipped |


---

## 16. Risk Register

Scored L (likelihood) × I (impact), each 1–5. Anything at 12+ needs a mitigation owner and a date.

| ID | Risk | L | I | Score | Mitigation | Phase |
|---|---|---|---|---|---|---|
| R1 | **Key loss → permanent data loss.** Keystore invalidated by biometric re-enrolment, factory reset, or app data clear | 4 | 5 | **20** | Mandatory recovery passphrase before any data is stored; enrolment is blocking, not a prompt. Recovery blob stored locally *and* in Drive. Periodic "verify your passphrase" reminder. Explicit irreversibility copy | 2 |
| R2 | **OOM on large images on low-end devices.** A 108 MP capture at 4 bytes/px is ~430 MB decoded | 4 | 4 | **16** | Native decode with `inSampleSize`; a hard ceiling on decoded pixels (default 40 MP, configurable down); streaming chunked crypto; no full-res bitmap ever in the Dart heap; test on a 2 GB API 26 device from Phase 4 | 4 |
| R3 | **Sync data loss from a merge bug.** Silent, discovered weeks later, unrecoverable | 3 | 5 | **15** | Immutable blobs (nothing to overwrite); append-only per-device logs; property tests P5/P6 (commutativity + idempotence); the simulation harness built before the first real sync; ship sync behind a flag to internal devices for 4 weeks | 7 |
| R4 | **Google OAuth verification delay.** `drive.appdata` is a sensitive scope needing review | 4 | 3 | **12** | Start verification 8 weeks before Phase 7 ships. Prepare the privacy policy, demo video, and scope justification in Phase 0. Fallback: ship v1.0 offline-only, sync in v1.1 | 0 |
| R5 | **Tink or `google_sign_in` API drift** breaks the build mid-phase | 3 | 4 | **12** | Verify both libraries' current state before Phase 2 and Phase 7 respectively. Pin exact versions, commit `pubspec.lock`. The envelope's `alg_id` byte makes a crypto-library swap non-breaking for existing files | 2, 7 |
| R6 | **SQLCipher silently not active**, producing a plaintext DB | 2 | 5 | **10** | Startup assertion on `PRAGMA cipher_version` plus a canary: write a known row, read the raw file, assert the plaintext does not appear. Fail closed | 2 |
| R7 | **Export size targeting frustrates users** ("I asked for 200 KB") | 4 | 2 | 8 | `maxBytes` vs `targetBytes` semantics in the API and in the UI copy; always return `actualBytes` and warnings; never claim exactness | 5 |
| R8 | **Version retention deletes something a user wanted** | 3 | 3 | 9 | Originals never deleted; recipes allow re-materialization of evicted deterministic versions; explicit user pin; clear "3 recent edits kept, originals kept forever" copy | 3 |
| R9 | **APK size** from OpenCV + googleapis + Tink pushes past store-friendly limits | 3 | 3 | 9 | App Bundle with ABI splits; OpenCV deferred to Phase 8 and re-evaluated; a size budget check in CI that fails on a >10% regression | 8 |
| R10 | **Scope creep from the "future features" list** (OCR, AI, passport photos) pulling work into v1 | 4 | 3 | 12 | Extension points are designed now and implemented never. Each has a named port and an ADR saying "deferred". Phase gates require sign-off | all |
| R11 | **Drive rate limiting** during initial upload of a large vault | 3 | 3 | 9 | Full-jitter backoff; queue-wide pause on 429; upload thumbnails first; chunked resumable uploads; a per-session byte budget | 7 |
| R12 | **Migration failure corrupts a live user's vault** | 2 | 5 | 10 | Every migration step tested against a seeded DB; automatic pre-migration DB copy (encrypted) retained until the next successful launch; migrations kept under ~1 s; long backfills moved to resumable jobs | 1+ |
| R13 | **Plaintext leaks into logs or a crash report** | 3 | 4 | 12 | `SensitiveValue<T>` wrapper with a `***` `toString`; CI lint banning raw `print`/`debugPrint`; no crash SDK in v1; the `RecordingCloudProvider` test asserting no plaintext ever reaches the cloud port | 0 |
| R14 | **Single-maintainer dependency goes dormant** (drift, pdf, workmanager) | 3 | 3 | 9 | Every one sits behind a port; each has an identified fallback (raw sqlite3, PDFBox-Android, own Worker). `pubspec.lock` committed; a vendoring plan for the worst case | all |
| R15 | **Background sync silently never runs** on aggressive OEM battery managers (Xiaomi, Oppo, Samsung) | 4 | 2 | 8 | Never rely solely on background sync; foreground sync on app open; a visible "last synced" indicator; an OEM-specific battery-optimisation prompt | 7 |
| R16 | **Coordinated ID edit leaves front and back inconsistent** after a crash | 2 | 3 | 6 | Both versions committed in one DB transaction; blob purge only post-commit | 3 |
| R17 | **Team drift past architectural boundaries** under deadline pressure | 4 | 4 | **16** | Package-level compile-time enforcement (not conventions); the `check_boundaries.dart` CI gate; ADRs required for exceptions; code review checklist derived from §19 | 0 |

---

## 17. Development Phases

Each phase lists goals, modules, dependencies, tests, acceptance criteria, and an explicit **NOT YET** list. The NOT YET lists are the most important part; they are what keeps the project from becoming a half-finished version of everything.

### Phase 0 — Architecture and project foundation

- **Goals:** Workspace, package skeletons, dependency direction enforced in CI, ADRs for the decisions in this document, determinism primitives, logging facade.
- **Modules:** `document_vault/` workspace; empty-but-wired `vault_domain`, `vault_app_core`, `vault_crypto`, `vault_persistence`, `vault_storage`, `platform_android`, `app`; `analysis_options.yaml`; `tool/check_boundaries.dart`; `docs/adr/0001–0010`; `Result`, `VaultFailure` skeleton, `Clock`/`IdGenerator`/`RandomSource`, `VaultLog`, `SensitiveValue<T>`.
- **Dependencies:** none beyond Flutter, `meta`, `collection`, dev-only lints and test tooling.
- **Tests:** `Result` combinators; `SensitiveValue.toString()` never reveals; `check_boundaries` fails on a deliberately planted bad import; the app builds and launches to a blank screen on API 26 and current.
- **Acceptance:** CI green, all boundary gates active, every ADR merged. A new contributor can read `docs/` and place a new file correctly without asking.
- **NOT YET:** any entity, any table, any screen, any crypto.

### Phase 1 — Local vault and asset model

- **Goals:** The full domain model and relational schema, in memory and on disk, with plaintext files. Prove the shape is right before adding encryption.
- **Modules:** `vault_domain/src/{entries,assets,versions}`; `EntryTypeSpec` for all five types; `EntryInvariants`; `vault_persistence` Drift tables (all of §6), DAOs, `EntryRepository` impl, migration v1 + snapshot; `vault_storage` plaintext `BlobStore` (temporary); use cases `CreateEntry`, `ImportAsset`, `AddPage`, `ReorderPages`, `DeleteEntry`.
- **Dependencies:** drift, sqlite3_flutter_libs, uuid, freezed.
- **Tests:** entity unit tests; all five type specs; invariants I1, I3, I4, I6, I7; DB constraint tests (assert the partial unique indexes actually reject bad rows); migration v0→v1; property test P4; restart-recovery test.
- **Acceptance:** can create one of each entry type, add/reorder/delete document pages, and reload correctly after a process kill. All invariants hold under the property-test generator. Zero raw SQL outside `vault_persistence`.
- **NOT YET:** encryption (files are plaintext and the DB is unencrypted, in a debug-only configuration that CI blocks from release builds), thumbnails, editing, export, sync, UI beyond a debug list.

### Phase 2 — Encrypted local storage

- **Goals:** Every byte at rest encrypted. Key hierarchy, Keystore integration, recovery passphrase, app lock.
- **Modules:** `platform_android/keystore` + `crypto` (Tink `StreamingAead`, Argon2id); `vault_crypto` envelope v1, `KeyManager`, `key_epochs`; `vault_storage` encrypted `BlobStore` + atomic write + GC sweep; SQLCipher wiring + the canary assertion; `UnlockSession`, auto-lock, `FLAG_SECURE`; recovery-passphrase enrolment flow (logic only).
- **Dependencies:** Tink, SQLCipher, `local_auth`.
- **Tests:** the full §13.4 crypto suite (KATs, tamper matrix, truncation, reorder, boundary sizes, nonce uniqueness); property P9, P10; SQLCipher canary; `KeyUnavailable` paths; instrumented Keystore + StrongBox tests on two real devices; migration of Phase-1 plaintext blobs into envelopes.
- **Acceptance:** no plaintext byte of user content exists anywhere in `/data/data/<pkg>` (verified by a test that greps the whole directory for a known fixture string). Vault unlocks with PIN + biometric; a wrong PIN never yields plaintext. Recovery passphrase round-trips MK. `adb backup` produces nothing.
- **NOT YET:** key rotation execution (the epoch schema exists, the rewrap job does not), cloud, editing.

### Phase 3 — Versioning, current/default, history

- **Goals:** The version graph, retention policy, pins, eviction, and edit recipes.
- **Modules:** `vault_domain/src/versions` complete (`VersionGraph`, `EditRecipe`, `VersionRetentionPolicy`, `PinSet`); `version_pins` DAO; `CommitVersion`, `SwitchCurrentVersion`, `RestoreVersion`, `EditSession` (including the coordinated ID path); eviction + post-commit purge; `rematerialize`.
- **Dependencies:** none new.
- **Tests:** invariants I1, I2, I8, I9, I10; property P1, P2, P8; retention with 0/1/3/4/10 versions; every pin reason blocking eviction; eviction never touching the original; export-pinned version survival; re-materialization equality (`sha256(rematerialized) == sha256(original derived)`) for deterministic chains; crash between commit and purge; coordinated ID atomicity.
- **Acceptance:** creating a 7th edit leaves exactly original + current + 3 derived materialized, with all rows intact and all lineage walkable. Switching current never deletes anything. A pinned version is never evicted under any generated op sequence.
- **NOT YET:** real image operations (recipes are applied by a stub that records ops), export, sync.

### Phase 4 — Basic image processing

- **Goals:** Real pixels. Native decode/encode, the deterministic op set, thumbnails.
- **Modules:** `platform_android/imaging` (decode with `inSampleSize`, op pipeline, encode); `vault_imaging` `NativeImageProcessor` + `DartImageProcessor` (reference); `ThumbnailProvider` + LRU; `DecodeSpec`; progress + cancellation plumbing.
- **Dependencies:** `image` (dev/reference), platform decoders.
- **Tests:** each `ImageOp` against the deterministic reference; normalised-coordinate correctness (same recipe on 4000 px and 400 px sources produces the same framing); memory ceiling test on a 40 MP fixture with a hard assert on peak RSS; cancellation mid-pipeline; thumbnail generation and invalidation; encrypted-in/encrypted-out round trip with no plaintext temp file.
- **Acceptance:** crop, rotate, resize, brightness, contrast, exposure, sharpen, and the basic filters all work end-to-end on an encrypted asset, on a 2 GB device, on a 40 MP image, without OOM. Thumbnails render a 500-item grid at 60 fps.
- **NOT YET:** edge detection, perspective correction, denoise, background removal (their `ImageOp` types exist and throw `UnsupportedOperation`).

### Phase 5 — Export engine

- **Goals:** Raster export, quick export, size solver, export history.
- **Modules:** `vault_export` pipeline, `LayoutEngine`, `SizeSolver`, encoders, `ExportRecorder`; `export_records` + `export_record_sources` DAOs; `QuickExport`, `ConfiguredExport`, `ExportAgain`; `FileProvider` share integration; artifact retention + expiry GC.
- **Dependencies:** none new.
- **Tests:** layout goldens (byte-exact JSON); size solver against a synthetic encoder with a known curve; `maxBytes` failure is a failure; `targetBytes` warnings; every `ExportSource` subtype; "Export Again" across all four source-resolution outcomes; export pinning a version and releasing it on expiry; invariant I5; SSIM assertions.
- **Acceptance:** quick export of any entry type in ≤2 taps, with no editor. A 200 KB target on a 12 MP source lands within 10% or reports why. Export history survives restart, and "Export Again" reproduces an identical result for a materialized source.
- **NOT YET:** PDF (`format == pdf` returns `UnsupportedFormat`), presets beyond a hard-coded two, multi-page layouts.

### Phase 6 — PDF and document processing

- **Goals:** PDF output, multi-page documents, paper/layout control.
- **Modules:** `vault_pdf` `PdfComposer`; `vault_export` PDF branch; grid/side-by-side/vertical layouts; page selection; PDF-specific size control (image downsampling to effective DPI).
- **Dependencies:** `pdf`.
- **Tests:** `StructuralPdfComposer` placement assertions; A4/A5/Letter/custom geometry; margins and spacing arithmetic; 100-page document generation with a peak-memory assert; page selection and ordering; PDF size targeting; metadata-leak test (no title, author, or path in the output); `PdfGenerationFailed` on a corrupt page.
- **Acceptance:** an ID exports front-only, back-only, and side-by-side on A4 with correct margins. A 50-page document exports in under 30 s on a mid-range device without OOM. Output opens correctly in three third-party readers.
- **NOT YET:** PDF import/rendering, annotations, OCR, digital signatures.

### Phase 7 — Google Drive encrypted sync

- **Goals:** The full sync engine, behind a feature flag, single-device first then multi-device.
- **Modules:** `vault_sync` (queue, scheduler, backoff, HLC, log segments, replay, merge, conflicts); `vault_drive` (`CloudProvider`, auth, resumable upload); `platform_android/work` `SyncWorker`; bootstrap-on-new-device; tombstone GC; the simulation harness.
- **Dependencies:** googleapis, googleapis_auth, google_sign_in, workmanager, connectivity_plus, cbor.
- **Tests:** the entire §13.5 scenario suite; properties P5, P6, P7; every Drive error class; resumable upload interrupted at 40%; duplicate upload idempotence; corrupted-download rejection; `RecordingCloudProvider` plaintext assertion; a 6-month-stale device; tombstone GC safety; the new-device bootstrap end-to-end.
- **Acceptance:** two real devices converge to identical state after an offline divergence, with both versions preserved and one deterministic provisional winner chosen on both. Sync survives airplane mode, process death, and a 429 storm. A wiped device restores the full vault from Drive plus the recovery passphrase. No plaintext or semantic metadata ever reaches Drive (asserted, not assumed).
- **NOT YET:** conflict-resolution UI (records only), selective sync, cross-provider, sharing, more than one cloud provider.

### Phase 8 — Advanced CV features

- **Goals:** Edge detection, perspective correction, denoise, background removal.
- **Modules:** `platform_android/imaging/OpenCvOps` or hand-written kernels; `EdgeDetector` impl; the non-deterministic `BackgroundOp` path plus the `recipeDeterministic = false` handling that Phase 3 already designed for.
- **Dependencies:** OpenCV (decision gate: measure APK impact first).
- **Tests:** detection accuracy against a labelled fixture set (target ≥90% IoU on well-lit documents); graceful degradation to manual corners; that non-deterministic versions are correctly marked and never silently re-materialized; APK size regression gate.
- **Acceptance:** auto edge detection + perspective correction on a typical document photo, with manual correction always available. APK growth within the agreed budget.
- **NOT YET:** OCR, classification, any ML model that requires uploading content anywhere.

### Phase 9 — Security hardening

- **Goals:** Close the gaps, run the review, execute rotation.
- **Modules:** the key-rotation rewrap job; root/debugger/emulator signals; certificate pinning for Drive; a scrubbed crash-reporting layer (optional); clipboard timeout; screenshot audit; `AnalyticsPort` with an events allowlist and no SDK behind it.
- **Tests:** rotation with a mid-job process kill; the full tamper matrix re-run against production builds; an R13 log-leak sweep; a dependency-vulnerability scan; an external review or at minimum a structured internal red-team against §8.7.
- **Acceptance:** every threat in §8.7 marked "Yes" is demonstrated by a test. Rotation completes on a 5 GB vault without user-visible disruption. No sensitive value appears in any release-build log.
- **NOT YET:** duress PIN, hidden vaults, self-destruct.

### Phase 10 — Testing, performance, release preparation

- **Goals:** Performance budgets met on low-end hardware, coverage gates met, release mechanics.
- **Modules:** benchmark suite; memory profiling harness; `StorageBudget` UI surface; onboarding for the recovery passphrase; Play Store data-safety declarations; the privacy policy.
- **Tests:** cold start < 2 s on API 26; 1000-entry grid scroll without jank; 50-page PDF export memory ceiling; a 4-hour soak test; battery profiling of background sync; the full matrix on 4 devices.
- **Acceptance:** all coverage gates green; all performance budgets met on the lowest-spec target device; the data-safety form is accurate; no P0/P1 bugs open.
- **NOT YET:** subscriptions, sharing, additional cloud providers, OCR, AI classification.

---

## 18. Acceptance Criteria for the Foundation (Phase 0 Exit)

Phase 0 is done when every one of these is objectively true. No partial credit.

**Structure**
1. The workspace builds with all 12 packages resolving; `flutter analyze` is clean with `fatal-infos: true`.
2. `vault_domain/pubspec.yaml` declares only `meta` and `collection`. Adding `drift` to it breaks the build (verified by a test commit, reverted).
3. `tool/check_boundaries.dart` runs in CI and fails on a planted forbidden import in each of: `vault_domain` → drift, `app/lib/features` → googleapis, `vault_sync` → googleapis.
4. `app/lib/bootstrap/composition_root.dart` is the only file in `app/` importing any `vault_*` infrastructure package, enforced by the same gate.

**Primitives**
5. `Result<T, E>` with `map`, `flatMap`, `fold`, `getOrElse`, at 100% coverage.
6. `VaultFailure` sealed hierarchy compiles with all ~30 subtypes from §12.2, each with a stable `code` string, and an exhaustive `switch` test that fails to compile if a subtype is added without handling.
7. `Clock`, `IdGenerator`, `RandomSource` ports exist with real and fake implementations, and a lint forbids `DateTime.now()`, `Random(`, and `Uuid()` outside `composition_root.dart`.
8. `VaultLog` facade exists; `print`/`debugPrint`/`dart:developer log` are lint errors outside it; `SensitiveValue<T>.toString()` returns `***` and is covered by a test.

**Documentation**
9. ADRs 0001–0010 merged, each one page, each with context/decision/consequences/alternatives-rejected, covering: append-only sync log; per-file DEKs; soft eviction; package-not-folder boundaries; PIN-is-not-a-key; one envelope for local and cloud; HLC over wall clock; `drive.appdata` scope; edit recipes; `maxBytes`/`targetBytes` semantics.
10. `docs/THREAT_MODEL.md` extracted from §8.7 and reviewed by someone other than the author.
11. This document is merged at `docs/ARCHITECTURE.md` and referenced from the README.

**CI**
12. The pipeline runs format → analyze → boundaries → unit tests, and fails the build on any one. Wall time under 4 minutes.
13. The app installs and launches on an API 26 emulator and a current physical device, showing a blank scaffold.
14. `pubspec.lock` is committed for every package; a dependency-diff check comments on any PR that adds one.

**Explicitly absent at Phase 0 exit**
15. No entity classes, no tables, no crypto, no screens. Phase 0 produces structure and rules, nothing else. If Phase 0 has shipped a `VaultEntry`, the phase boundary has already leaked.


---

## 19. The 14 Most Dangerous Architectural Mistakes

These are ordered by how expensive they are to reverse once shipped. Each one is a mistake I have deliberately designed against, and each is a code-review checklist item.

---

### M1. Deriving the file encryption key from the PIN

**Why it is fatal:** A 6-digit PIN carries ~20 bits of entropy. An attacker with the extracted database and blobs runs the full keyspace on a laptop in under a minute, regardless of how many Argon2 iterations you use, because 10⁶ candidates is simply not a large number. Every user's documents are then plaintext. This is unrecoverable: you cannot re-key data that is already exfiltrated.

**What we do instead:** The PIN's Argon2id output is used only as an HKDF salt. The actual key material comes from a non-exportable, hardware-backed, TEE-rate-limited Keystore key. Both factors are required and neither is sufficient. See §8.1–8.2.

---

### M2. Mutable cloud blobs, or overwriting a blob under the same identifier

**Why it is fatal:** The moment a cloud object can be overwritten, every concurrent edit becomes a byte-level merge problem, and byte-level merges of JPEGs are not a solvable problem. You are then forced into last-writer-wins, which silently destroys the loser's work, which is precisely what the brief forbids.

**What we do instead:** Blobs are immutable and content-sealed. A new edit is a new blob with a new ID. The Device A v7 / Device B v8 case becomes two coexisting immutable objects and one pointer to arbitrate. See §1.1 (Idea 2) and §9.5.

---

### M3. Syncing a database snapshot instead of an append-only operation log

**Why it is fatal:** Two devices uploading `vault.db.enc` means the second upload erases the first device's entire session. There is no incremental fix; the merge semantics have to be built from scratch, and by then there is production data in the broken format. Migrating users off a snapshot sync is close to impossible because the data needed to reconstruct their history was never recorded.

**What we do instead:** Each device writes only its own log segments, so cloud-side write conflicts cannot exist. Merge is a deterministic local replay with property tests proving commutativity and idempotence. See §9.3.

---

### M4. Using wall-clock timestamps to resolve conflicts

**Why it is fatal:** Phone clocks are wrong. Users change timezones, NTP corrects backwards, a device sits in a drawer with a dead battery and boots to 1970. Last-writer-wins on `updatedAt` then silently discards the *newer* edit, and the bug is undiagnosable from logs because the timestamps look plausible. It also cannot distinguish "B edited after seeing A's change" from "B edited without knowing about A", which are completely different situations requiring completely different handling.

**What we do instead:** Hybrid logical clocks for causality, with deterministic tiebreaking by `(physicalTime, counter, deviceId)`. Wall-clock time is displayed to humans and never used for decisions. See §9.4.

---

### M5. Hard-deleting version rows when evicting history

**Why it is fatal:** `export_record_sources` holds a foreign key to `asset_versions`. Deleting the row either fails (and someone "fixes" it by dropping the constraint) or cascades (and destroys export history). Either way, invariant I5 breaks, "Export Again" silently exports the wrong image, and the version lineage develops dangling `parent_version_id` pointers that corrupt the graph permanently.

**What we do instead:** Eviction nulls `blob_id` and sets `evicted_at`. The row, the lineage, and the edit recipe survive forever at a cost of ~200 bytes. Deterministic recipes then allow the binary to be regenerated on demand, so the user's *visible* history is unlimited even though *stored* history is three. See §10.3.

---

### M6. Modelling the five entry types as five aggregates

**Why it is fatal:** Five tables, five repositories, five sets of version logic, five export paths. Adding a sixth type means touching every layer. Worse, ID (two assets) and DOCUMENT (N assets) end up with genuinely different version and export code, so a bug fixed in one is not fixed in the other. The codebase stops being extensible around type three.

**What we do instead:** One aggregate, with `AssetRole` + `ordinal` covering all shapes and `EntryTypeSpec` holding the per-type rules as data. A new type is a new enum value and a ~8-line spec. See §5.2.

---

### M7. Putting `currentVersionId` on the entry instead of the asset

**Why it is fatal:** It looks natural and it silently breaks ID and DOCUMENT. The brief requires that an ID's front and back be editable independently; with a single pointer on the entry, editing the back either resets the front or requires a parallel shadow structure bolted on later. For documents it is worse: a 20-page document has 20 independent current versions. By the time this is discovered, the schema, the sync ops, and the export resolver all encode the wrong assumption.

**What we do instead:** `current_version_id` lives on `assets`. Coordinated ID editing is an application-layer transaction across two assets, not a data-model shortcut. See §5.1, §10.5.

---

### M8. Whole-file, single-shot AES-GCM

**Why it is fatal:** A 60 MB scan means a 60 MB plaintext buffer plus a 60 MB ciphertext buffer plus whatever the codec holds, on a device with 2 GB of RAM and maybe 200 MB of headroom. It OOMs. Teams then "fix" it by chunking with a hand-rolled framing scheme, which is where the real damage happens: naive chunking without a counter in the nonce allows chunk reordering, and without a final-block flag allows undetectable truncation. Both are silent integrity failures on an app whose entire value proposition is integrity.

**What we do instead:** Tink's `StreamingAead` (the STREAM construction) with 256 KiB chunks, a counter in the nonce, a final-chunk flag, and an authenticated header covering `alg_id` and `key_epoch` so the format cannot be downgraded. Peak memory is constant. See §7.2.

---

### M9. No key hierarchy, so rotation is impossible in practice

**Why it is fatal:** If the master key encrypts files directly, rotating it requires decrypting and re-encrypting every byte of a multi-gigabyte vault, then re-uploading all of it. Nobody does that. So rotation is designed, documented, and never executed, and a compromised key stays compromised for the life of the install.

**What we do instead:** Per-file DEKs wrapped under purpose-scoped keys derived from MK, with `key_epoch` in every file header. Rotation rewraps a few thousand short DEKs, a metadata-only pass that runs on charge+idle and is resumable. Bodies are untouched. See §8.1, §8.6.

---

### M10. Letting plaintext or full-resolution bitmaps into the Dart heap

**Why it is fatal:** Two problems at once. Memory: a 40 MP image decoded to ARGB is ~160 MB, and passing it over the method channel copies it, so you briefly hold two. Security: Dart offers no reliable zeroing (strings are immutable, the GC copies objects), so key material and document plaintext linger in memory indefinitely and land in heap dumps. Both of these are architectural, not tunable: once `Future<Uint8List> read(BlobId)` exists on your storage interface, someone will call it from a widget.

**What we do instead:** `BlobStore` exposes handles and streams, not byte arrays, with `readSmall` capped at 256 KiB for metadata. Decryption, decoding, and pixel work happen in Kotlin over `DirectByteBuffer`s that are explicitly zeroed. Dart sees previews under 1024 px. See §7.4, §8.4.

---

### M11. Leaking semantics through cloud filenames, properties, or MIME types

**Why it is fatal:** Encrypting the bytes and then naming the file `passport_front.jpg` defeats the entire exercise. The same applies to `appProperties: {type: "AADHAAR"}`, to a folder named `IDs/`, and to setting the upload MIME type to `image/jpeg`. Google, anyone with account access, and anyone who ever sees a file listing learns exactly what the user is storing. It is also very hard to fix retroactively, because renaming thousands of existing objects requires a migration that some devices will never run.

**What we do instead:** Names are `b_<uuid>.bin`. MIME is always `application/octet-stream`. `appProperties` carry only `{blobId, envVer, keyEpoch, ctSha256, size}` and are treated as public. All semantics live inside encrypted log segments. A test asserts that no fixture title ever appears in anything handed to the cloud port. See §9.2, §13.6.

---

### M12. Coupling export to a PDF library, or letting the UI compute layout

**Why it is fatal:** If the export result depends on widget sizes, screen density, or a `RenderRepaintBoundary`, then output differs between phones, cannot be tested headlessly, cannot run in the background, and cannot be reproduced from an export record. "Export Again" then produces a different file than the original, which for a document vault is a correctness bug, not a cosmetic one. And if PDF page geometry lives inside calls to a specific library, swapping that library means rewriting the feature.

**What we do instead:** `LayoutEngine` is pure geometry returning `List<PlacedCell>` in millimetres, unit-tested with byte-exact goldens and zero pixels involved. `PdfComposer` is a five-method port. The engine runs entirely off the UI thread and knows nothing about Flutter. See §11.3, §11.5.

---

### M13. Promising exact export file sizes

**Why it is fatal:** Lossy compression cannot hit a byte target exactly, and lossless compression cannot hit a *small* target at all. An API shaped like `export(targetSize: 200_000)` that returns `void` forces the implementation to either lie or loop forever. Users then see a 340 KB file after asking for 200 KB, with no explanation, and conclude the app is broken.

**What we do instead:** `maxBytes` is a hard constraint that fails loudly with `SizeUnattainable`; `targetBytes` is best effort and always returns `actualBytes` plus a `targetSizeMissed` warning. PNG with a `maxBytes` and no downscale permission fails at *validation*, in milliseconds, with a clear reason, rather than after twenty seconds of futile search. See §11.4.

---

### M14. Deleting a blob the moment its tombstone arrives

**Why it is fatal:** Device B has been offline for three weeks and still references version `v12`. Device A deletes the entry, the tombstone syncs, and the GC removes the blob from Drive immediately. Device B comes online, replays, and finds a dangling reference to data that no longer exists anywhere. That data is gone permanently, and the user did nothing wrong.

**What we do instead:** Two-stage deletion everywhere. Stage one is a tombstone plus `deleted_at`, immediate and reversible. Stage two purges only after the tombstone TTL has elapsed **and** every known device's `sync_cursor` has passed the tombstone's HLC. Devices silent past a horizon must be explicitly forgotten by the user. Waiting costs storage; not waiting costs data. See §6.5, §9.8.

---

### Honourable mentions (dangerous, but cheaper to fix)

- **Storing thumbnails unencrypted** because they are "just previews". A 128 px thumbnail of an ID card is an image of an ID card.
- **Scattering `try/catch`**, so a `DriveApiException` surfaces in a widget and the user sees a stack trace mentioning their file path.
- **Not injecting `Clock`/`Random`/`IdGenerator` from day one.** HLC and sync tests become flaky, and retrofitting injection into a finished codebase takes weeks.
- **Dropping unknown sync ops** from a newer peer instead of preserving and skipping them, which turns every old device into a silent data-loss machine.
- **Enabling Android Auto Backup**, which ships blobs to Google under a key lifecycle you do not control.
- **Integer enum ordinals in the schema.** Reordering the enum in Dart silently reinterprets every existing row.

---

## 20. What I Need From You Before Phase 0

I am deliberately stopping here rather than scaffolding, because several of these answers change the foundation rather than sitting on top of it.

**Decisions I need:**

1. **A1** — Confirm `minSdk 26`. Anything lower forces a software-key fallback path that weakens the entire model.
2. **A2** — Is multi-device sync a v1.0 requirement or a v1.1 one? This is the single biggest schedule variable. If v1.1, I would still build the HLC and op-log plumbing in Phase 1 (they are cheap early and impossible to retrofit) but defer Phases 7's networking.
3. **A3** — Confirm the recovery passphrase is mandatory and blocking. If it is optional, we ship a design where a biometric re-enrolment can permanently destroy a user's documents, and I want that decision made explicitly by you, not by me.
4. **A6** — `drive.appdata` (invisible) vs `drive.file` (user-visible folder). This also gates when the OAuth verification clock starts (R4).
5. **§14.1** — Multi-package workspace (compiler-enforced boundaries, more setup) or single package with lint rules (faster start, fails open). I recommend the former and will not be upset by the latter.
6. **§6** — Approve the two schema deviations: `export_record_sources` as a join table, and `EditRecipe` stored per version.

**Things worth challenging me on:** the op-log sync design is the most complex part of this architecture and carries the most risk. If sync is genuinely a "nice to have, one device, occasional backup" feature rather than a real multi-device story, a much simpler design exists (single-writer backup with a device lock), and I would rather build that than over-engineer.

Once these are settled I will produce **Phase 0 only**: the workspace, the package skeletons with enforced boundaries, `Result`, the `VaultFailure` hierarchy, the determinism ports, the logging facade, the CI boundary checker, and the first ten ADRs. No entities, no tables, no crypto, no screens.

