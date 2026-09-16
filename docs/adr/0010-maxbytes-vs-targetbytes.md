# ADR 0010: maxBytes vs targetBytes

- **Date:** 2026-09-15
- **Status:** Proposed
- **Source:** docs/ARCHITECTURE.md §11.4, §19 (M13)

## Context

Compression cannot hit an exact byte count, and lossless compression cannot hit a small target at all. An API shaped like `export(targetSize: 200_000)` that returns `void` forces the implementation to either lie or loop forever. Users then see a 340 KB file after asking for 200 KB, with no explanation, and conclude the app is broken (risk R7).

## Decision

Split the contract: `maxBytes` is a hard constraint whose violation is a failure (`SizeUnattainable`); `targetBytes` is best effort and always returns `actualBytes` plus a `targetSizeMissed` warning. The size solver encodes at requested quality, binary-searches quality in [minQualityFloor, 100] (max 7 probes), optionally downscales (max 3 rounds) if allowed, and returns `SizeMet` / `SizeApproximate` (outside ±10%) / `SizeUnattainable`. PNG with `maxBytes` and no downscale/palette permission fails at validation, in milliseconds, with a clear reason.

## Consequences

- `ExportResult.warnings` tells the truth: "210 KB when you asked for 200 KB" is a warning, not a failure.
- The UI can be honest without claiming exactness; `appliedQuality` records what the solver landed on.
- A result over `maxBytes` is never silently returned.
- PDF size control separately downsamples images to effective DPI and applies per-image quality search.

## Alternatives rejected

- **Single `targetSize` that must be met exactly:** impossible for lossy codecs and worse for lossless ones; forces lies or infinite loops.
- **Silently returning oversize files:** destroys user trust in a document app.
- **Failing the export when target is missed:** "within 10%" with a warning is the honest product outcome.
