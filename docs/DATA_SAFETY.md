# Play Store Data Safety — draft answers

_Source: the implementation itself (docs/ARCHITECTURE.md §8.7, §15.9;
PRIVACY.md). Every answer below is verifiable in code._

## Data collection and security

| Question | Answer | Grounding |
|---|---|---|
| Does the app collect user data? | **No.** No analytics, no telemetry, no crash reporting SDK (§15.9). | `AnalyticsPort` is a no-op; no Firebase/Amplitude/Mixpanel dependency exists. |
| Is data shared with third parties? | **No**, except storage on the user's *own* Google Drive **if the user explicitly enables sync**, and only as AES-256-GCM ciphertext with opaque names. | `vault_drive` writes sealed blobs only; the plaintext-assertion test (`RecordingCloudProvider`) guards it. |
| Is data encrypted in transit? | **Yes.** Sync payloads are ciphertext (client-side encryption); transport additionally uses HTTPS with certificate pinning to the GTS roots. | Envelope v1; `network_security_config.xml`. |
| Is data encrypted at rest? | **Yes.** SQLCipher database + AES-256-GCM sealed files; keys are hardware-bound where available. | Phase 2 (§8). |
| Can users request deletion? | **Yes.** In-app delete (two-stage, then purge); uninstall removes all local data. | §6.5 two-stage deletion. |

## Data types (Play form)

- **Photos and videos** — "Collected? No (stored on-device only; optionally
  backed up to the user's own Google Drive as ciphertext, user-enabled)."
- **Documents** — same as above.
- **Personal info (titles/notes the user types)** — same as above; those
  fields carry an extra encryption layer even inside the database.
- **App activity** — not collected.
- **Device or other IDs** — not collected; the sync device id is a random
  UUID kept on-device and inside encrypted logs only.

## Notes for review

- The Google sign-in (`drive.appdata`) is used solely to write the user's
  own encrypted backup to their own hidden app folder; the scope is the
  narrowest available and needs OAuth app verification before release (R4).
- Exported files leave the app only through the system share sheet, at the
  user's explicit action, with a warning in the UI (A8).
