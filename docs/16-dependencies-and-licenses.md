# 16 — Dependency and license release policy

## Reproducibility

- `pubspec.yaml` records intentional direct constraints.
- `pubspec.lock` is committed and is the source of exact package versions for Android release builds.
- Flutter, Dart, Java, Android Gradle Plugin, Kotlin, compile SDK, target SDK, and NDK versions are fixed by repository configuration and CI.
- Release CI must fail if dependency resolution changes the committed lockfile.

## DatePicker dependency

`persian_datetime_picker` is pinned to `3.2.0`. It is retained because it provides Material-compatible Persian/Jalali input, Persian localization delegates, Material 3 support, date range controls, and a `shamsi_date` conversion foundation. The app wraps it behind its own formatter/field boundary so a later package change does not leak calendar-specific values into the database or domain.

## Third-party notices

`tool/generate_release_dossier.py` reads the exact `.dart_tool/package_config.json` and `flutter pub deps --json` output used by the build. For every hosted/path package it:

- records name, resolved version, dependency kind, source, and license filename;
- requires a top-level license/copying file;
- embeds the complete license text in `THIRD-PARTY-NOTICES.txt`;
- fails release-dossier generation if a non-SDK package lacks a discoverable license.

Flutter/Dart SDK components are identified separately as SDK dependencies. The publisher must retain the Flutter/engine notices included in the generated APK/AAB and comply with all license terms.

## Update review

Every direct dependency update requires:

1. changelog and breaking-change review;
2. publisher/repository and maintenance-state review;
3. license comparison;
4. transitive dependency diff;
5. merged Android manifest and permission diff;
6. privacy/Data Safety impact review;
7. analyzer, full tests, schema parity, release builds and signatures;
8. arm64/universal size comparison;
9. physical-device smoke test for platform plugins.

Major Flutter, Android Gradle, target SDK, Drift, notification, timezone, Jalali, or future advertising updates must be isolated in their own PR.

## Prohibited dependency behavior

A dependency is not accepted merely because it compiles. Release blockers include:

- unknown or incompatible redistribution license;
- unreviewed Internet, advertising-ID, location, storage, account, health, or broad package permissions;
- medication/user data collection or logging;
- required production secrets committed to Git;
- failure that blocks core medication flows;
- unexplained arm64 size growth beyond the accepted budget;
- abandoned/incompatible SDK with no safe migration plan.

## Advertising boundary

The v1.0 candidate contains no advertising SDK. The official Adivery compatibility probe is tracked in Issue `#35`; account and placement IDs remain publisher-owned. A failed or incomplete monetization integration cannot block the ad-free core release.
