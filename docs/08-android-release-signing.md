# 08 — Android release signing runbook

## Purpose

This runbook creates and protects the permanent Android upload key, configures local release builds, and enables the manual GitHub Actions workflow that produces a store-candidate AAB.

The repository never stores the keystore or its passwords. The AAB built by ordinary CI uses a disposable CI key and is **not** suitable for store upload.

## 1. Generate the permanent upload key once

Run `keytool` interactively so passwords do not enter shell history:

```bash
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Use a unique strong store password and key password. Keep the alias stable. Do not reuse the disposable CI alias or CI artifact.

## 2. Create local ignored configuration

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_UPLOAD_KEYSTORE_PASSWORD
keyPassword=YOUR_UPLOAD_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

Relative `storeFile` paths are resolved from `android/`. Both `android/key.properties` and keystore extensions are ignored by Git.

## 3. Validate and build locally

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
(cd android && ./gradlew :app:verifyReleaseSigning)
flutter build appbundle --release
jarsigner -verify -strict -certs build/app/outputs/bundle/release/app-release.aab
sha256sum build/app/outputs/bundle/release/app-release.aab
```

The bundle is created at:

```text
build/app/outputs/bundle/release/app-release.aab
```

Increase the `version` in `pubspec.yaml` before every store update. The value after `+` becomes the Android version code and must increase for each uploaded release.

## 4. Back up the key before the first publication

Create at least two encrypted backups in different secure locations. Back up all of the following together:

- `upload-keystore.jks`
- key alias
- store password
- key password
- creation date and owner
- SHA-256 certificate fingerprint

Inspect and record the public certificate fingerprint:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

Never place the private keystore in Drive folders, chat messages, repository releases, issue attachments, or ordinary project backups unless they are separately encrypted and access-controlled.

## 5. Configure GitHub repository secrets

Create a single-line Base64 representation of the keystore.

Linux or macOS with OpenSSL:

```bash
openssl base64 -A -in android/upload-keystore.jks
```

PowerShell:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("android/upload-keystore.jks")
)
```

Add these repository secrets:

| Secret | Value |
|---|---|
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | Complete one-line Base64 keystore |
| `ANDROID_UPLOAD_STORE_PASSWORD` | Keystore password |
| `ANDROID_UPLOAD_KEY_ALIAS` | Usually `upload` |
| `ANDROID_UPLOAD_KEY_PASSWORD` | Private-key password |

Do not paste these values into workflow inputs. Inputs are only for optional version overrides.

## 6. Run the signed release workflow

In GitHub Actions, run **Android Signed Release** manually.

Optional inputs:

- `build_name`: semantic version such as `0.1.0`
- `build_number`: positive integer Android version code

The workflow:

1. validates all four secrets and optional version inputs;
2. reconstructs the keystore only inside the isolated runner;
3. runs formatting, analyzer, and tests;
4. verifies the Gradle signing contract;
5. builds a signed release AAB;
6. verifies the AAB signature;
7. uploads only the AAB and SHA-256 checksum;
8. deletes reconstructed signing files even after failure.

## 7. Understand the two AAB artifact types

### CI release AAB

- signed by a generated disposable key;
- proves the release build and signing configuration work;
- safe for engineering inspection;
- **never upload to a store**.

### Manual signed release AAB

- signed by the permanent upload key reconstructed from secrets;
- candidate for store upload after version, privacy, content, and device checks;
- still does not imply store acceptance or production rollout.

## 8. Google Play boundary

For a new Google Play app, configure Play App Signing. The upload key signs the submitted AAB; Google protects the app-signing key and signs distributed APKs. Keep the permanent upload key secret and preserve its backups even when Play App Signing is enabled.

Before publishing to another store, confirm its signing and update-key requirements. Do not assume that a Google Play upload-key arrangement automatically matches another store's lifecycle.

## 9. Incident rules

- Suspected password exposure: rotate passwords if possible and replace repository secrets immediately.
- Lost upload key with Play App Signing enabled: follow the Play Console upload-key reset process.
- Lost signing key for a store that relies directly on that key: stop release work and assess update continuity before generating anything new.
- Accidental key commit: treat the key as compromised even after deleting the commit; rewrite history only as containment, not as proof the secret is safe.
