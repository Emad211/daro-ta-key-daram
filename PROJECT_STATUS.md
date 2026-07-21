# Project Status

## Current phase

Physical-device verification, permanent release key setup, and closed-beta preparation.

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
- [x] Stable notification scheduling, cancellation, deep links, reboot persistence, and timezone fallback
- [x] Automated Persian RTL and large-text coverage at scales 1.0, 1.3, and 2.0
- [x] Android release signing without debug fallback, disposable-key AAB validation, and secret-backed manual release workflow

## Validated for merge in PR `#27`

- Persian privacy/about center accessible from the dashboard with explicit semantics.
- Clear disclosure of current local medication storage, medical non-goals, notifications, and future third-party advertising boundaries.
- One typed `deleteAll` repository command shared by Drift and in-memory implementations.
- Drift transaction removes active and archived medication aggregate roots; inventory history follows by enforced foreign-key cascade.
- Unrelated application preferences remain outside medication-domain erasure.
- Dedicated application service performs persistence erasure before notification cleanup.
- Typed result distinguishes complete success from pending notification cleanup.
- Failed notification cleanup never implies database rollback and supports retry without re-deleting data.
- Cancelling the destructive dialog produces no persistence or notification side effects.
- Duplicate destructive submissions are disabled.
- Privacy and destructive controls pass the narrow 360×640 Persian RTL matrix at text scales 1.0, 1.3, and 2.0.
- Public-facing Persian privacy-policy draft includes explicit publisher/contact/HTTPS/SDK placeholders.
- Strict Flutter CI run `#345` passed schema parity, formatting, analyzer, the complete regression suite, debug APK, disposable-key release AAB, signature/checksum validation, artifact upload, and signing-material cleanup.

## Build artifacts from validation

- Debug APK artifact digest: `sha256:345dd73f65bba583ac8b46552185a85b184136e9b914c74504e9f9dec289ff5c`
- CI release AAB artifact digest: `sha256:599e9f083d3335567120a1af315d8f3e6d2f33488cd500ec3f33538105f6adce`

The CI AAB is signed by a disposable key and must not be uploaded to a store.

## Maintainer-owned release material still required

- Generate the permanent upload keystore once.
- Store at least two encrypted backups and record the certificate SHA-256 fingerprint.
- Configure the four GitHub repository secrets described in `docs/08-android-release-signing.md`.
- Run the manual **Android Signed Release** workflow to produce the first store-candidate AAB.

## Publication material still required

- Replace every placeholder in `docs/09-privacy-policy-fa.md`.
- Publish the final policy at a stable HTTPS URL.
- Verify the final permission and SDK inventory against the release build.
- Complete store-specific Data Safety and metadata.

## Device-only work still required

- Run the notification checklist in Issue `#10` on Android hardware.
- Verify TalkBack reading order and spoken labels.
- Verify display-size plus font-size combinations and small-device gestures.
- Complete final brand color-contrast review.

## Next engineering increments

1. Merge PR `#27` after the final documentation CI run.
2. Run physical-device notification, installation, upgrade, and accessibility verification.
3. Create and protect the permanent upload key and produce the first store-candidate AAB.
4. Integrate Adivery behind `AdService` with the safety caps in Issue `#3`.
5. Finalize privacy/store metadata and start a 10–20 user closed beta.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Privacy-control PR ready for final validation: `#27`
- Repository and strict CI are the source of truth for subsequent engineering work.
