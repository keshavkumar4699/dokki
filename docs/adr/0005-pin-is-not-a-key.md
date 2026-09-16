# ADR 0005: PIN is not a key

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §8.2, §19 (M1)

## Context

A 6-digit PIN carries ~20 bits of entropy. If the PIN (even Argon2id-stretched) alone protects the vault, an attacker with the extracted DB and blobs runs the full keyspace in under a minute — 10^6 candidates is simply not a large number. That failure is unrecoverable: you cannot re-key data that is already exfiltrated.

## Decision

The PIN is never a key, and never the only factor. Its Argon2id output (m=64 MiB, t=3, p=2) is used only as the HKDF salt. The actual key material comes from a non-exportable, hardware-backed, TEE-rate-limited Android Keystore key (`setUserAuthenticationRequired(true)`, StrongBox where available). Both factors are required and neither is sufficient: an attacker with the database gets nothing without the device's secure element; an attacker with the device gets nothing without the PIN.

## Consequences

- Offline PIN cracking against extracted data is infeasible.
- Devices with no secure lock screen cannot use auth-bound keys; the app refuses to create a vault until a device lock is set — no software-only fallback.
- Biometric re-enrolment invalidates the Keystore key (`setInvalidatedByBiometricEnrollment(true)`), which is correct security-wise; the mandatory recovery passphrase (A3) is what makes this survivable.

## Alternatives rejected

- **PIN-derived encryption key:** cracked in seconds on a laptop/GPU regardless of KDF iterations.
- **Software-only key fallback:** silently downgrades every user's security to "PIN-derived".
- **Keystore key alone (no PIN):** possession of the unlocked device is sufficient.
