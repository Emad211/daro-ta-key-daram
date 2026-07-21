# ADR-0010 — Android release signing boundary

- Status: Proposed
- Date: 2026-07-21

## Context

The Android `release` build type previously reused the debug signing configuration. That can create an artifact named as a release while binding it to a development-only certificate, which is unsafe for store enrollment and future updates.

The repository also needs to prove that its Flutter, Gradle, R8, manifest, and plugin configuration can produce a signed Android App Bundle without storing a permanent private key in Git.

## Decision

- Debug builds may use the standard Android debug key.
- Release builds never fall back to debug signing.
- Release credentials are loaded only from ignored `android/key.properties` and an ignored keystore file.
- `assembleRelease` and `bundleRelease` depend on an explicit signing-verification task.
- Missing signing properties or keystore bytes fail with a clear Gradle error.
- Pull-request and main CI generate a short-lived upload key, build a signed release AAB, verify its JAR signature, upload the AAB and checksum, and delete the temporary key material.
- The CI-generated AAB is a build-validation artifact only. It must never be uploaded to a store because its private key is intentionally disposable.
- A separate manual workflow reconstructs the permanent upload keystore from GitHub repository secrets and produces the store-candidate AAB.
- The permanent keystore and passwords never appear in repository files, workflow artifacts, command output, or issue/PR text.

## Required repository secrets

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_UPLOAD_STORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_ALIAS`
- `ANDROID_UPLOAD_KEY_PASSWORD`

## Key ownership

For Google Play, the upload key signs the submitted AAB while Play App Signing protects and uses the app-signing key for distributed APKs. The upload key and app-signing key should remain separate when possible.

For any additional store, the maintainer must review that store's signing and update requirements before the first publication. A key strategy cannot be changed casually after users have installed a signed application.

## Consequences

Release builds become intentionally impossible until signing material is supplied. CI becomes slower because it also compiles and verifies a release AAB, but signing regressions become release-blocking before store work begins.

A successful ephemeral CI AAB proves the build path, not ownership of the permanent upload key, store acceptance, Play App Signing enrollment, or the ability to publish an update.
