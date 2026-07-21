# Project Status

## Current phase

Physical-device verification, permanent release key setup, and closed-beta preparation.

## Completed on `main`

- [x] Product scope, safety boundaries, and ad-only monetization policy
- [x] Flutter application architecture and Persian RTL vertical slice
- [x] Drift/SQLite schema, snapshot enforcement, and transactional repository
- [x] Medication details, restock, correction, immutable history, edit, archive, restore, permanent deletion, and full local medication erasure
- [x] Structured daily, every-N-days, and selected-weekday consumption schedules
- [x] Schema v1-to-v2 migration and schedule-change inventory baselines
- [x] Typed Persian write failures, review gates, duplicate-submit guards, undo, and recoverable notification cleanup
- [x] Stable notification scheduling, cancellation, deep links, reboot persistence, and timezone fallback
- [x] Automated Persian RTL and large-text coverage at scales 1.0, 1.3, and 2.0
- [x] Privacy center, atomic medication-data deletion, and Persian privacy-policy draft
- [x] Android release signing without debug fallback and disposable-key AAB validation

## Current engineering increment — Issue `#28`, draft PR `#29`

The increment was triggered by a physical-device installation failure in SAI. SAI received a `content://` document whose provider returned a null `DISPLAY_NAME`. The failure occurred before Android parsed or verified the APK.

Implemented in the branch:

- Secret-backed **Android Signed Release** workflow builds both a universal release APK and a store-candidate AAB.
- Both files use the same commit, version inputs, and permanent upload signing identity.
- APK verification uses Android SDK `apksigner` and requires a modern APK Signature Scheme.
- AAB verification uses `jarsigner`.
- SHA-256 checksum files are created for both outputs.
- Artifact contains APK, AAB, checksums, build metadata, and Persian installation instructions.
- Instructions explicitly require extracting the GitHub artifact ZIP and opening the APK with Android Package Installer rather than SAI.
- Local release script builds and verifies both APK and AAB.
- Strict CI builds an ephemeral signed release APK and AAB, validates both signatures, and keeps the disposable key outside Git.
- Device runbook covers clean install, signature mismatch, persistence, notifications, privacy erasure, TalkBack, largest text, upgrade, ADB installation, and closed-beta exit criteria.

The PR remains draft until the exact-head strict CI run passes source checks, the complete regression suite, debug APK, ephemeral release APK verification, release AAB verification, checksums, artifact upload, and cleanup.

## Direct debug APK currently available

The current debug APK can be installed without SAI by downloading the raw `.apk` file and opening it from Files / My Files with Android Package Installer.

A debug build may not upgrade directly to the future permanently signed internal APK because Android requires compatible signing certificates. The first transition may require uninstalling the debug build, which removes local app data.

## Maintainer-owned release material still required

- Generate the permanent upload keystore once.
- Store at least two encrypted backups and record the certificate SHA-256 fingerprint.
- Configure the four GitHub repository secrets described in `docs/08-android-release-signing.md`.
- Run **Android Signed Release** to produce the first permanently signed APK/AAB pair.
- Preserve the same signing identity for future internal upgrade tests.

## Publication material still required

- Replace every placeholder in `docs/09-privacy-policy-fa.md`.
- Publish the final policy at a stable HTTPS URL.
- Verify the final permission and SDK inventory against the release build.
- Complete store-specific Data Safety and metadata.

## Device-only work still required

- Install the raw debug APK with Android Package Installer and confirm launch.
- Run the full checklist in `docs/10-android-device-validation.md`.
- Run the notification checklist in Issue `#10` on Android hardware.
- Verify TalkBack reading order and spoken labels.
- Verify display-size plus font-size combinations and small-device gestures.
- Complete final brand color-contrast review.
- After configuring the permanent key, validate clean install and upgrade with permanently signed APKs.

## Next engineering increments

1. Complete and merge PR `#29` after strict APK/AAB validation.
2. Create and protect the permanent upload key and configure repository secrets.
3. Produce the first permanently signed internal APK and store-candidate AAB.
4. Execute and record physical-device installation, notification, privacy, accessibility, and upgrade checks.
5. Integrate Adivery behind `AdService` with the safety caps in Issue `#3`.
6. Finalize privacy/store metadata and start a 10–20 user closed beta.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Active signed-APK/device-validation PR: `#29`
- Repository and strict CI are the source of truth for subsequent engineering work.
