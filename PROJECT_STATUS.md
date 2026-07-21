# Project Status

## Current phase

Release engineering before physical-device verification and closed beta.

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

## Validated for merge in PR `#23`

- Persian RTL is the canonical regression direction.
- Dashboard, add, details, quantity review, edit, and archive flows pass on a narrow 360 × 640 viewport.
- Text scales 1.0, 1.3, and 2.0 pass with realistic swipe interaction.
- Critical icon-only controls expose explicit Persian semantic labels.
- Summary metrics, urgency state, action groups, dropdowns, bottom sheets, and dialogs adapt without RenderFlex overflow.
- The full existing regression suite remains green after the layout changes.
- Strict Flutter CI run `#283` passed Drift schema parity, formatting, analyzer, all tests, Android debug APK build, and artifact upload.

## Device-only work still required

- Run the notification checklist in Issue `#10` on Android hardware.
- Verify TalkBack reading order and spoken labels.
- Verify display-size plus font-size combinations and small-device gestures.
- Complete final brand color-contrast review.

## Next engineering increments

1. Replace debug signing with a secure release-signing workflow and produce an internal AAB.
2. Run physical-device notification and accessibility verification.
3. Integrate Adivery behind `AdService` with the safety caps in Issue `#3`.
4. Add privacy-safe technical analytics containing no medication names, schedules, stock, notes, or health attributes.
5. Prepare privacy policy, store listing, and a 10–20 user closed beta.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Accessibility PR ready for final validation: `#23`
- Repository and strict CI are the source of truth for subsequent engineering work.
