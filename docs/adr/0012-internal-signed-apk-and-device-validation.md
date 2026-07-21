# ADR-0012 — Internal signed APK and physical-device validation

- Status: Proposed
- Date: 2026-07-21

## Context

GitHub Actions artifacts are downloaded as ZIP archives. A debug APK was opened through SAI from an Android `content://` URI whose provider returned a null `DISPLAY_NAME`, causing SAI to fail before package installation.

The project previously produced a secret-backed store-candidate AAB but no permanently signed universal APK for direct installation. AAB files are not directly installable, while debug APKs may use a different signing identity and cannot reliably validate upgrade continuity.

## Decision

- The manual **Android Signed Release** workflow produces both a universal release APK and a store-candidate AAB.
- Both outputs use the same commit, version inputs, and maintainer-owned permanent upload key.
- The APK is verified with Android SDK `apksigner` and must use a modern APK Signature Scheme.
- The AAB is verified with `jarsigner`.
- SHA-256 checksums are generated for both outputs.
- One artifact contains the APK, AAB, checksums, build metadata, and Persian installation instructions.
- GitHub artifact ZIPs must be extracted before installation.
- The universal APK is installed with Android Package Installer or `adb install`; SAI is not the canonical path.
- Signature mismatch is never bypassed. The tester verifies application ID, version code, and certificate continuity, or explicitly uninstalls the old debug build after accepting local-data loss.
- Strict CI builds and verifies an ephemeral signed release APK in addition to the existing disposable-key AAB, but does not publish the disposable APK as an internal upgrade artifact.
- Physical-device validation records device, Android version, APK checksum, application version, install source, locale, text/display sizes, and TalkBack state.

## Artifact boundary

### Internal signed release APK

- directly installable;
- signed by the permanent upload key;
- intended for device and closed-beta testing;
- upgrade-compatible only with subsequent builds that preserve signing identity and increase version code as required.

### Store-candidate AAB

- not directly installable;
- signed by the permanent upload key;
- intended for store submission after privacy, metadata, and device checks.

### Disposable CI APK/AAB

- prove build and signature configuration;
- use a temporary private key;
- must not be used to establish upgrade continuity or store ownership.

## Consequences

The manual release job becomes slower because it builds and verifies two Android artifacts. In return, physical-device installation no longer depends on debug signing or split-package installers, and the APK/AAB relationship is recorded from one reproducible run.

A successful workflow does not replace physical-device validation. Clean install, upgrade, persistence, notifications, privacy erasure, TalkBack, large text, and restart behavior remain explicit release gates.
