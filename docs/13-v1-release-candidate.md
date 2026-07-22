# 13 — Android v1.0 release-candidate runbook

## Release identity

- Product: **دارو تا کی دارم؟**
- Application ID: `ir.emadkarimi.darutakey`
- Version name: `1.0.0`
- Android version code: `1`
- Canonical locale: `fa-IR`
- Canonical direction: RTL
- Internal date type: Dart `DateTime`
- User-facing calendar: Jalali/Persian

## DatePicker decision

The release uses `persian_datetime_picker` version `3.2.0`, pinned in `pubspec.yaml`. It provides a Material-compatible Jalali picker and Persian localizations and is built on `shamsi_date`. Conversion remains at the UI boundary; persistence, stock calculations, sorting, and notification scheduling continue to use normal `DateTime` values.

Release date rules:

- displayed dates and date-times use the central Persian formatter and Persian digits;
- initial inventory and later inventory events can use a selected past effective time;
- future effective times are rejected;
- a new inventory event cannot precede the current inventory baseline;
- `createdAt` remains the actual command time and is never replaced by the selected effective time.

## v1.0 privacy/network boundary

The initial public release is intentionally:

- local-first and usable offline;
- account-free;
- cloud-sync-free;
- ad-SDK-free;
- analytics/crash-reporting-SDK-free;
- free of the Android `INTERNET` and advertising-ID permissions.

Medication name, schedule, stock, notes, archive state, history, and notification content remain inside the app sandbox. Auto Backup, cloud backup, and device-to-device transfer are excluded for app data. Cleartext traffic is explicitly disabled.

Advertising is not a release blocker. Issue `#35` isolates the official Adivery compatibility and privacy probe. It cannot be enabled until test/production IDs are supplied by the publisher and all safety, privacy, manifest, size, and failure-isolation gates pass.

## Automated release gates

The exact release-candidate head must pass:

1. dependency resolution from the committed lockfile;
2. Drift code generation and schema snapshot parity;
3. canonical formatting and Flutter analyzer;
4. the complete test suite;
5. RTL/large-text and Jalali picker coverage;
6. inventory date boundary and no-side-effect rejection tests;
7. notification/privacy concurrency tests;
8. debug APK build for diagnostics only;
9. missing-signing rejection;
10. local and environment-backed signing validation;
11. optimized universal APK, arm64 APK, and AAB builds;
12. APK `apksigner` and AAB `jarsigner` verification;
13. SHA-256 generation and size budgets;
14. merged-manifest permission/export/backup/cleartext inspection;
15. dependency and third-party-license inventory;
16. deterministic release dossier artifact generation.

## Release artifacts

The CI validation artifact contains disposable-key binaries and is for engineering verification only:

- universal APK;
- arm64 APK;
- AAB;
- checksums;
- merged manifest and permission/component inventory;
- dependency metadata and third-party notices;
- Data Safety baseline;
- store-listing drafts;
- release status and external blockers.

The store candidate must be produced by **Android Signed Release** using the publisher-owned permanent upload key. The arm64 APK is the preferred direct-install test artifact; the AAB is the preferred store upload artifact when supported.

## External publisher-owned gates

Repository automation cannot complete or fabricate:

- publisher/legal identity;
- monitored support/privacy email;
- public HTTPS privacy-policy URL;
- permanent upload keystore, passwords, backup locations, and fingerprint record;
- GitHub repository signing secrets;
- Cafe Bazaar/Myket developer accounts and console declarations;
- final branded visual assets and screenshots;
- physical-device install, notification, TalkBack, largest-text, and same-key upgrade evidence;
- Adivery account and placement IDs.

These are tracked in Issues `#30`, `#36`, `#37`, `#38`, and `#39`.

## Public rollout decision

Do not publish broadly until all critical device scenarios pass and a permanently signed Version A upgrades to a higher-version-code Version B without uninstalling or losing data. Closed beta precedes public rollout.
