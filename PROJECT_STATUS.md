# Project Status

## Current phase

Quality and release hardening before physical-device notification verification and closed beta.

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
- [x] Typed Persian command failures, retained form state, duplicate-submit guards, quantity review, schedule confirmation, and archive undo
- [x] Cancelled and rejected write commands proven to have no persisted aggregate or history side effects
- [x] Stable notification IDs, permission flow, scheduling, replacement, cancellation, deep links, reboot persistence, and timezone fallback
- [x] Android project with application ID `ir.emadkarimi.darutakey`
- [x] Strict CI for code generation, schema parity, formatting, analyzer, tests, debug APK build, and artifact upload

## Current engineering increment

Issue `#22` and draft PR `#23` establish the accessibility baseline:

- Persian RTL as the canonical regression direction
- narrow 360 × 640 logical-pixel phone viewport
- text scales 1.0, 1.3, and 2.0
- dashboard, add, details, quantity review, edit, and archive traversal
- Persian semantics for critical icon-only actions
- tests that fail on uncaught Flutter rendering exceptions
- adaptive fixes for any measured overflow or unreachable control

The increment remains draft until strict CI, the complete test suite, and the Android debug APK build pass.

## Next engineering increments

1. Run the physical-device notification checklist in Issue `#10`.
2. Replace debug signing with a secure release signing workflow and produce an internal AAB.
3. Integrate Adivery behind `AdService` with the safety caps in Issue `#3`.
4. Add privacy-safe technical analytics containing no medication names, schedules, stock, notes, or health attributes.
5. Prepare privacy policy, store listing, and a 10–20 user closed beta.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Active accessibility PR: `#23`
- Repository and strict CI are the source of truth for subsequent engineering work.
