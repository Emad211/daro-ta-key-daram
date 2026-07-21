# 08 — Android release signing runbook

## Purpose

This runbook creates and protects the permanent Android upload key, configures local release builds, and enables the manual GitHub Actions workflow that produces:

- a directly installable internal release APK;
- a store-candidate Android App Bundle.

The repository never stores the permanent keystore or its passwords. The AAB built by ordinary CI uses a disposable CI key and is **not** suitable for store upload.

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

Use the repository command so source checks, Gradle signing verification, APK/AAB creation, signature verification, and checksum generation remain consistent:

```bash
bash tool/build_signed_android_release.sh
```

Optional version overrides:

```bash
bash tool/build_signed_android_release.sh \
  --build-name 0.1.0 \
  --build-number 1
```

The script never accepts passwords as arguments. It reads the ignored signing configuration through Gradle and locates `apksigner` from `ANDROID_SDK_ROOT` or `ANDROID_HOME`.

Outputs:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/flutter-apk/app-release.apk.sha256
build/app/outputs/bundle/release/app-release.aab
build/app/outputs/bundle/release/app-release.aab.sha256
```

Verification rules:

- the APK must pass Android SDK `apksigner verify --verbose --print-certs` and use a modern APK Signature Scheme;
- the AAB must produce the `jar verified.` result from `jarsigner`;
- both files receive SHA-256 checksums.

Android signing certificates are normally self-signed. Verification proves cryptographic integrity and signing identity; it does not require a public certificate-authority trust chain.

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

Do not paste these values into workflow inputs. Inputs are only for optional version overrides. Secret values are exposed only to workflow steps that validate or use signing material; setup actions do not receive them.

## 6. Run the signed Android workflow

In GitHub Actions, run **Android Signed Release** manually.

Optional inputs:

- `build_name`: semantic version such as `0.1.0`
- `build_number`: positive integer Android version code

The workflow:

1. validates all four secrets and optional version inputs;
2. reconstructs and inspects the keystore only inside the isolated runner;
3. runs formatting, analyzer, and tests;
4. verifies the Gradle signing contract;
5. builds a signed universal release APK;
6. builds a signed release AAB using the same version inputs and signing identity;
7. verifies the APK with `apksigner`;
8. verifies the AAB with `jarsigner`;
9. creates SHA-256 checksums, build metadata, and Persian installation instructions;
10. uploads one internal-release artifact containing both outputs;
11. deletes reconstructed signing files even after failure.

The artifact contains:

```text
daro-ta-key-internal-release.apk
daro-ta-key-internal-release.apk.sha256
daro-ta-key-store-candidate.aab
daro-ta-key-store-candidate.aab.sha256
BUILD-METADATA.txt
INSTALL-APK-FA.txt
```

## 7. Installing the internal APK

GitHub Actions artifacts are downloaded as ZIP archives. The ZIP itself is not installable.

1. Extract the ZIP.
2. Locate `daro-ta-key-internal-release.apk`.
3. Open it from Files / My Files using Android Package Installer.
4. Grant the selected file manager permission to install unknown applications only when Android requests it.

Do not use SAI for this single universal APK. SAI is mainly useful for split APK, `.apks`, or multi-package workflows. A SAI error stating that the `DISPLAY_NAME` column is null usually indicates a broken or incomplete `content://` URI supplied by another file provider, not an invalid APK signature.

Detailed installation, upgrade, notification, privacy, and accessibility checks are in [`10-android-device-validation.md`](10-android-device-validation.md).

## 8. Understand the artifact types

### Debug APK

- directly installable;
- intended for developer smoke testing;
- typically signed by a debug certificate;
- may not upgrade to a permanently signed internal APK because Android requires compatible signatures.

### Internal signed release APK

- directly installable with Android Package Installer or `adb install`;
- signed by the permanent upload key;
- suitable for physical-device and closed-beta installation when distribution rules permit;
- supports upgrade testing only when subsequent APKs use the same signing identity and increasing version codes.

### CI validation AAB

- signed by a generated disposable key;
- proves the release build and signing configuration work;
- safe for engineering inspection;
- **never upload to a store**.

### Store-candidate AAB

- signed by the permanent upload key reconstructed from secrets;
- candidate for store upload after version, privacy, content, and device checks;
- not directly installable;
- still does not imply store acceptance or production rollout.

## 9. Google Play boundary

For a new Google Play app, configure Play App Signing. The upload key signs the submitted AAB while Google protects the app-signing key and signs distributed APKs. Keep the permanent upload key secret and preserve its backups even when Play App Signing is enabled.

The internal release APK is signed directly with the configured upload key. Treat it as an internal testing artifact, not as proof of the exact signing identity Google Play will use for APKs distributed after Play App Signing.

Before publishing to another store, confirm its signing and update requirements. Do not assume that a Google Play upload-key arrangement automatically matches another store's lifecycle.

## 10. Incident rules

- Suspected password exposure: rotate passwords if possible and replace repository secrets immediately.
- Lost upload key with Play App Signing enabled: follow the Play Console upload-key reset process.
- Lost signing key for a store that relies directly on that key: stop release work and assess update continuity before generating anything new.
- Accidental key commit: treat the key as compromised even after deleting the commit; rewrite history only as containment, not as proof the secret is safe.
- Signature mismatch during internal installation: do not bypass Android checks. Confirm application ID, certificate fingerprint, and version code. Uninstall the old build only after accepting that its local data will be removed.
