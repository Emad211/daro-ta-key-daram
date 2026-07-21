# ADR-0010 — Android release signing boundary

- Status: Accepted
- Date: 2026-07-21

## Context

The Android `release` build type previously reused the debug signing configuration. That could create an artifact named as a release while binding it to a development-only certificate, which is unsafe for store enrollment and future updates.

The repository also needs to prove that its Flutter, Gradle, manifest, plugin, and signing configuration can produce a signed Android App Bundle without storing a permanent private key in Git.

## Decision

- Debug builds may use the standard Android debug key.
- Release builds never fall back to debug signing.
- Local release credentials are loaded from ignored `android/key.properties` and an ignored keystore file.
- Automated release workflows may pass signing credentials through step-scoped `ANDROID_UPLOAD_*` environment variables without writing production passwords into repository files.
- `assembleRelease` and `bundleRelease` depend on an explicit signing-verification task.
- Missing signing properties or keystore bytes fail with a clear Gradle error.
- Pull-request and main CI generate a short-lived upload key, prove both file-backed and environment-backed signing, build a signed release AAB, verify its JAR signature, upload the AAB and checksum, and delete the temporary key material.
- The CI-generated AAB is a build-validation artifact only. It must never be uploaded to a store because its private key is intentionally disposable.
- A separate manual workflow reconstructs the permanent upload keystore from GitHub repository secrets and produces the store-candidate AAB.
- Permanent keystore bytes and passwords never appear in Git history, issue/PR text, or downloadable build artifacts.

## Required repository secrets

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_UPLOAD_STORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_ALIAS`
- `ANDROID_UPLOAD_KEY_PASSWORD`

## Validation evidence

Strict Flutter CI run `#309` passed:

- source and secret-file guards;
- Drift generation and schema parity;
- canonical formatting and analyzer;
- the complete test suite;
- debug APK build;
- expected rejection of release signing without credentials;
- local `key.properties` signing verification;
- environment-backed signing verification;
- release AAB build;
- JAR signature verification and SHA-256 checksum generation;
- APK and AAB artifact upload;
- cleanup of ephemeral signing material.

## Key ownership

For Google Play, the upload key signs the submitted AAB while Play App Signing protects and uses the app-signing key for distributed APKs. The upload key and app-signing key should remain separate when possible.

For any additional store, the maintainer must review that store's signing and update requirements before the first publication. A key strategy cannot be changed casually after users have installed a signed application.

## Consequences

Release builds are intentionally impossible until valid signing material is supplied. CI is slower because it compiles and verifies a release AAB, but signing regressions become release-blocking before store work begins.

A successful ephemeral CI AAB proves the build path, not ownership of the permanent upload key, store acceptance, Play App Signing enrollment, or the ability to publish an update. The permanent upload key, encrypted backups, certificate fingerprint record, and repository secrets remain maintainer-owned prerequisites.
