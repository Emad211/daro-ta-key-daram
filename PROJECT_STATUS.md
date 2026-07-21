# Project Status

## Current phase

Privacy controls and physical-device verification before closed beta.

## Completed on `main`

- [x] Product scope, safety boundaries, and ad-only monetization policy
- [x] Flutter application architecture and Persian RTL vertical slice
- [x] Drift/SQLite schema, snapshot enforcement, and transactional repository
- [x] Medication details, restock, correction, immutable history, edit, archive, restore, and permanent deletion
- [x] Structured daily, every-N-days, and selected-weekday consumption schedules
- [x] Schema v1-to-v2 migration and schedule-change inventory baselines
- [x] Hardened stock calculation precision and boundary invariants
- [x] Typed create, details, quantity, archive, restore, delete, and full-erasure repository commands
- [x] Explicit active / archived / missing lifecycle state machine
- [x] Typed Persian command failures, retained form state, duplicate-submit guards, quantity review, schedule confirmation, and archive undo
- [x] Stable notification scheduling, cancellation, deep links, reboot persistence, and timezone fallback
- [x] Automated Persian RTL and large-text coverage at scales 1.0, 1.3, and 2.0
- [x] Android release signing without debug fallback, disposable-key AAB validation, and secret-backed manual release workflow

## Current engineering increment — Issue `#26`, draft PR `#27`

- Persian privacy/about center accessible from the dashboard.
- Clear disclosure of current local medication storage and medical non-goals.
- One typed `deleteAll` repository command.
- Drift transaction removes every medication aggregate; inventory history follows by foreign-key cascade.
- Unrelated app preferences remain outside medication-domain erasure.
- Dedicated application service deletes persistence first and then clears notifications.
- Typed outcome distinguishes complete success from pending notification cleanup.
- Notification cleanup can be retried without pretending medication data was restored.
- Destructive confirmation, duplicate-submit guard, Persian feedback, and text-scale 2.0 coverage.
- Public-facing Persian privacy-policy draft with explicit pre-publication placeholders.

The increment remains draft until schema parity, formatting, analyzer, full tests, debug APK, and disposable-key release AAB validation pass.

## Maintainer-owned release material still required

- Generate the permanent upload keystore once.
- Store at least two encrypted backups and record the certificate SHA-256 fingerprint.
- Configure the four GitHub repository secrets described in `docs/08-android-release-signing.md`.
- Run the manual **Android Signed Release** workflow to produce the first store-candidate AAB.

## Device-only work still required

- Run the notification checklist in Issue `#10` on Android hardware.
- Verify TalkBack reading order and spoken labels.
- Verify display-size plus font-size combinations and small-device gestures.
- Complete final brand color-contrast review.

## Next engineering increments

1. Complete and merge PR `#27` after strict privacy-control validation.
2. Run physical-device notification and accessibility verification.
3. Integrate Adivery behind `AdService` with the safety caps in Issue `#3`.
4. Finalize the public privacy policy, store metadata, and a 10–20 user closed beta.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Active privacy-control PR: `#27`
- Repository and strict CI are the source of truth for subsequent engineering work.
