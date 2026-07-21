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
- [x] Automated Persian RTL and large-text coverage at scales 1.0, 1.3, and 2.0
- [x] Strict CI for code generation, schema parity, formatting, analyzer, tests, debug APK build, and artifact upload

## Current engineering increment — Issue `#24`, draft PR `#25`

- Remove the Android release build's debug-signing fallback.
- Require ignored `android/key.properties` and an ignored permanent upload keystore.
- Fail release tasks explicitly when signing material is absent or invalid.
- Generate a disposable upload key in strict CI and build a signed release AAB.
- Verify the AAB signature and publish a SHA-256 checksum artifact.
- Add a manual GitHub Actions workflow backed by repository secrets for a store-candidate AAB.
- Document local key generation, offline backup, GitHub secret setup, versioning, and incident handling.

A CI-signed AAB proves the release build path only. It is deliberately signed by a disposable key and must not be uploaded to a store.

## Maintainer-owned release material still required

- Generate the permanent upload keystore once.
- Store encrypted offline backups and record its certificate fingerprint.
- Configure the four GitHub repository secrets described in `docs/08-android-release-signing.md`.
- Run the manual **Android Signed Release** workflow to produce the first store-candidate AAB.

## Device-only work still required

- Run the notification checklist in Issue `#10` on Android hardware.
- Verify TalkBack reading order and spoken labels.
- Verify display-size plus font-size combinations and small-device gestures.
- Complete final brand color-contrast review.

## Next engineering increments

1. Complete and merge PR `#25` after strict release AAB validation.
2. Run physical-device notification and accessibility verification.
3. Integrate Adivery behind `AdService` with the safety caps in Issue `#3`.
4. Add privacy-safe technical analytics containing no medication names, schedules, stock, notes, or health attributes.
5. Prepare privacy policy, store listing, and a 10–20 user closed beta.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Active release-signing PR: `#25`
- Repository and strict CI are the source of truth for subsequent engineering work.
