# Project Status

## Current phase

Measured Android release performance, Jalali date migration, physical-device verification, and closed-beta preparation.

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
- [x] Android release signing without debug fallback and disposable-key APK/AAB validation
- [x] Direct internal APK workflow, no-SAI installation guidance, and physical-device runbook

## Physical-device finding

The first installed artifact was a roughly 155 MB Flutter debug APK and felt very slow. APK inspection showed that most of the package was debug/runtime payload rather than product functionality, including a large Dart kernel blob, multiple Flutter engine ABIs, and validation libraries.

Debug remains useful for development but is excluded from final size and performance conclusions. Release or profile mode on a named physical device is the source of truth.

## Current engineering increment — Issue `#31`, draft PR `#32`

Implemented on the branch:

- `persian_datetime_picker` 3.2.0 with Persian Material/Cupertino localization delegates.
- Central Jalali formatter with Persian digits.
- Jalali date/time fields for medication creation, restock, and correction.
- Jalali depletion dates and inventory history.
- Gregorian Dart `DateTime` retained inside domain, persistence, calculations, and notifications.
- Past inventory effective times supported; future times rejected in UI and application service.
- Command `createdAt` remains distinct from selected `effectiveAt`.
- Optional notification initialization deferred until after the first rendered frame.
- Debug/profile startup milestones without medication or user data.
- Universal and arm64 release APK outputs plus AAB.
- Actual APK files preserved in CI artifacts rather than checksum-only output.
- `apksigner`, `jarsigner`, SHA-256, byte-size metadata, and initial regression budgets.
- Unit/widget coverage for known Jalali conversions, Persian digits, large text, backdating, and future-date rejection.

Still required before merge:

- exact-head analyzer and full regression suite;
- exact universal/arm64 release sizes from CI;
- passage of the initial 60 MiB universal and 30 MiB arm64 gates;
- inspection of the release-validation artifact contents;
- installation and responsiveness comparison of the arm64 release APK on a physical device;
- acceptance of ADR-0013 after evidence is complete.

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

- Install the arm64 release APK from PR `#32` after exact-head CI succeeds.
- Compare cold launch, warm launch, first usable dashboard, and first tap response against debug.
- Run the full checklist in `docs/10-android-device-validation.md` and Issue `#30`.
- Verify Jalali picker, backdated events, history, and depletion displays.
- Run the notification checklist in Issue `#10` on Android hardware.
- Verify TalkBack reading order, spoken labels, largest text, display size, and gestures.
- After configuring the permanent key, validate clean install and upgrade with permanently signed APKs.

## Next engineering increments

1. Complete and merge PR `#32` after exact-head release measurements and device comparison.
2. Tighten release-size budgets from evidence and decide whether R8/resource shrinking is justified.
3. Add a stable profile-mode benchmark target for repeatable startup evidence.
4. Create and protect the permanent upload key and configure repository secrets.
5. Integrate Adivery behind `AdService` with the safety caps in Issue `#3`.
6. Finalize privacy/store metadata and start a 10–20 user closed beta.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Active performance/Jalali PR: `#32`
- Repository and strict CI are the source of truth for subsequent engineering work.
