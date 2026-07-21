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
- [x] Typed create, details, quantity, archive, restore, and delete repository commands
- [x] Explicit active / archived / missing lifecycle state machine
- [x] Typed Persian command failures, retained form state, duplicate-submit guards, quantity review, schedule confirmation, and archive undo
- [x] Cancelled and rejected write commands proven to have no persisted aggregate or history side effects
- [x] Stable notification IDs, permission flow, scheduling, replacement, cancellation, deep links, reboot persistence, and timezone fallback
- [x] Android project with application ID `ir.emadkarimi.darutakey`
- [x] Automated Persian RTL and large-text coverage at scales 1.0, 1.3, and 2.0
- [x] Strict CI for code generation, schema parity, formatting, analyzer, tests, debug APK build, and artifact upload

## Validated for merge in PR `#25`

- Android release builds never fall back to debug signing.
- Release tasks fail explicitly when signing material is missing.
- Local ignored `android/key.properties` signing is validated.
- Step-scoped environment signing used by the manual release workflow is validated.
- Signing files and private-key formats are rejected from Git tracking.
- Strict Flutter CI run `#309` passed the full source suite, debug APK, release AAB build, JAR signature verification, SHA-256 checksum generation, artifact upload, and signing-material cleanup.
- The manual **Android Signed Release** workflow validates secrets and version inputs, reconstructs the upload keystore only inside the runner, and removes it after the run.
- A local release command performs the same source, signing, AAB, signature, and checksum checks.

The downloaded CI AAB is signed by a disposable key and is **not** a store-candidate artifact.

## Maintainer-owned release material still required

- Generate the permanent upload keystore once.
- Store at least two encrypted backups and record the certificate SHA-256 fingerprint.
- Configure the four GitHub repository secrets described in `docs/08-android-release-signing.md`.
- Run the manual **Android Signed Release** workflow to produce the first store-candidate AAB.
- Confirm the signing/update-key rules of each target store before first publication.

## Current next increment

Issue `#26` tracks a Persian privacy center and one atomic command for deleting all local medication data, history, and related notifications.

## Device-only work still required

- Run the notification checklist in Issue `#10` on Android hardware.
- Verify TalkBack reading order and spoken labels.
- Verify display-size plus font-size combinations and small-device gestures.
- Complete final brand color-contrast review.

## Next engineering increments

1. Merge PR `#25` after the final documentation CI run.
2. Implement Issue `#26` for privacy controls and atomic local-data deletion.
3. Run physical-device notification and accessibility verification.
4. Integrate Adivery behind `AdService` with the safety caps in Issue `#3`.
5. Prepare the public privacy policy, store listing, and a 10–20 user closed beta.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Release-signing PR ready for final validation: `#25`
- Privacy-control issue queued next: `#26`
- Repository and strict CI are the source of truth for subsequent engineering work.
