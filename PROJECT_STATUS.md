# Project Status

## Current phase

Reliability hardening before physical-device notification verification and release engineering.

## Completed on `main`

- [x] Product scope, safety boundaries, and ad-only monetization policy
- [x] Flutter application architecture and Persian RTL vertical slice
- [x] Drift/SQLite schema, snapshot enforcement, and transactional repository
- [x] Medication details, restock, correction, immutable history, edit, archive, restore, and permanent deletion
- [x] Structured daily, every-N-days, and selected-weekday consumption schedules
- [x] Schema v1-to-v2 migration and schedule-change inventory baselines
- [x] Hardened stock calculation precision and boundary invariants
- [x] Typed create, details, quantity, archive, restore, and delete repository commands
- [x] Explicit active / archived / missing lifecycle state machine
- [x] Stable notification IDs, permission flow, scheduling, replacement, cancellation, deep links, reboot persistence, and timezone fallback
- [x] Android project with application ID `ir.emadkarimi.darutakey`
- [x] Strict CI for code generation, schema parity, formatting, analyzer, tests, debug APK build, and artifact upload

## Current engineering increment

PR `#21` implements command error recovery:

- typed Persian UI failure messages
- retained form state after rejected commands
- duplicate-submission guards
- review-before-save for quantity baselines
- archive undo through the typed restore command
- tests proving cancelled and rejected flows have no persisted side effects
- canonical Dart formatting committed from Flutter `3.44.6`
- bidirectional, viewport-deterministic retained-field widget assertions

The increment is not complete until strict CI and the Android debug build pass.

## Next engineering increments

1. Run the physical-device notification checklist in Issue `#10`.
2. Replace debug signing with a secure release signing workflow and produce an internal AAB.
3. Perform accessibility, large-font, and RTL overflow audits.
4. Integrate Adivery behind `AdService` with the safety caps in Issue `#3`.
5. Add privacy-safe technical analytics containing no medication names, schedules, stock, notes, or health attributes.
6. Prepare privacy policy, store listing, and a 10–20 user closed beta.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Active integration PR: `#21`
- Repository and strict CI are the source of truth for subsequent engineering work.
