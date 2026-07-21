# 10 — Android installation and physical-device validation

## Purpose

This runbook covers direct installation of an internal signed APK and the physical-device checks required before closed beta.

It distinguishes four different files:

| File | Directly installable? | Signing identity | Purpose |
|---|---:|---|---|
| Debug APK | Yes | Debug key | Developer smoke testing; uninstall may be required between differently signed builds |
| Internal signed release APK | Yes | Permanent upload key | Direct installation and upgrade testing on real devices |
| Store-candidate AAB | No | Permanent upload key | Upload to a compatible store after all release checks |
| CI validation AAB | No | Disposable CI key | Build-path validation only; never upload to a store |

## 1. Fix for the SAI `DISPLAY_NAME column is null` error

An error such as:

```text
ContentUriFileDescriptor$BadContentProviderException: DISPLAY_NAME column is null
```

occurs before APK installation. SAI received a `content://` URI from another application whose Android `ContentProvider` did not return a usable `DISPLAY_NAME` column.

This does **not** prove that the APK is corrupt.

For this project, the generated internal file is one universal APK. SAI is unnecessary because SAI is primarily useful for split APK, `.apks`, or multi-package installation workflows.

Use this path instead:

1. Download the GitHub Actions artifact.
2. The artifact itself is a ZIP archive. Extract it first.
3. Locate `daro-ta-key-internal-release.apk`.
4. Copy or move the APK to `Downloads` or normal internal storage.
5. Open **Files**, **My Files**, or the phone manufacturer's file manager.
6. Tap the APK itself.
7. Choose **Package Installer**, **Install unknown apps**, or the equivalent system installer.
8. Grant the selected file manager permission to install unknown applications only when Android requests it.
9. Revoke that permission after the test when practical.

Do not open the ZIP as though it were an APK. Do not send a single universal APK to SAI unless ordinary Android Package Installer is unavailable and the file manager provides a valid document URI.

## 2. Signature mismatch and upgrade rules

Android permits an existing application to be upgraded only when the new APK:

- uses the same application ID;
- has a higher version code when required by the installation path;
- is signed by an accepted continuation of the existing signing identity.

The application ID is:

```text
ir.emadkarimi.darutakey
```

A debug APK and a permanently signed internal APK usually use different certificates. Installing one over the other may produce messages such as:

- App not installed;
- package conflicts with an existing package;
- signatures do not match;
- update is incompatible.

For the first transition from debug to the permanent internal signing identity:

1. verify or export any test data you intentionally need;
2. uninstall the debug application;
3. install the permanently signed internal APK;
4. use only APKs produced with the same permanent upload key for subsequent upgrade tests.

Uninstalling removes the application's local database unless Android or the device vendor restores application data from a system backup. Test with backup restoration disabled when validating a truly clean install.

## 3. Producing the internal APK and store AAB

Configure the four repository secrets documented in `08-android-release-signing.md`, then manually run **Android Signed Release** in GitHub Actions.

The workflow produces one artifact containing:

```text
daro-ta-key-internal-release.apk
daro-ta-key-internal-release.apk.sha256
daro-ta-key-store-candidate.aab
daro-ta-key-store-candidate.aab.sha256
BUILD-METADATA.txt
INSTALL-APK-FA.txt
```

The workflow uses one build name, build number, commit, and permanent upload key for both APK and AAB.

It verifies:

- the APK with Android SDK `apksigner` and a modern APK Signature Scheme;
- the AAB with `jarsigner`;
- SHA-256 checksums for both files.

## 4. Record the test environment

Create one record per device and test run:

| Field | Example |
|---|---|
| Device model | Samsung Galaxy A54 |
| Android version | Android 15 |
| Build fingerprint | From Settings or `adb shell getprop ro.build.fingerprint` |
| App version name | `0.1.0` |
| App version code | `1` |
| APK SHA-256 | From the artifact checksum |
| Install source | Files / Package Installer |
| Locale | فارسی |
| Font size | Default / Large / Largest |
| Display size | Default / Large |
| TalkBack | Off / On |
| Tester | Name or initials |
| Date | YYYY-MM-DD |

## 5. Clean-install checklist

- [ ] No prior package with application ID `ir.emadkarimi.darutakey` remains installed.
- [ ] The artifact ZIP is extracted.
- [ ] The APK filename is visible and ends with `.apk`.
- [ ] The downloaded APK checksum matches the included `.sha256` file.
- [ ] Android Package Installer opens without SAI.
- [ ] Android shows the expected application name.
- [ ] Installation completes without package parsing or signature errors.
- [ ] The application launches from the installer and launcher icon.
- [ ] The first frame renders in Persian RTL without a crash.
- [ ] No notification permission is requested automatically on first launch.
- [ ] The empty state and first-medication action are reachable.

## 6. Core medication flow

- [ ] Create a daily medication with a Persian name.
- [ ] Create a weekly medication.
- [ ] Close and reopen the application; both records remain.
- [ ] Verify estimated stock and depletion date remain plausible.
- [ ] Record a restock and confirm history appears.
- [ ] Record a correction and confirm history appears.
- [ ] Edit the medication name and schedule.
- [ ] Archive a medication.
- [ ] Restore the medication.
- [ ] Permanently delete an archived medication.
- [ ] Confirm deleted history does not reappear after application restart.

## 7. Notification validation

- [ ] Open the reminder action intentionally.
- [ ] Grant notification permission.
- [ ] Confirm a successful reminder message is shown.
- [ ] Change stock or schedule and verify old notification plans are replaced.
- [ ] Archive a medication and verify its notification is cancelled.
- [ ] Restore it and verify a new notification can be scheduled.
- [ ] Reboot the device and confirm schedules are rebuilt where applicable.
- [ ] Update the application and confirm schedules are rebuilt where applicable.
- [ ] Tap a delivered notification and confirm the correct medication opens.
- [ ] Repeat with notification permission denied; medication management must continue working.

Record expected timing carefully. The application uses inexact scheduling and does not claim alarm-clock precision.

## 8. Privacy-center and erasure validation

- [ ] Open **حریم خصوصی و اطلاعات برنامه** from the dashboard.
- [ ] Confirm local-storage, medical-boundary, notification, and advertising disclosures are readable.
- [ ] Open the full-erasure confirmation and press **انصراف**; no medication disappears.
- [ ] Reopen the confirmation and approve permanent deletion.
- [ ] Confirm active and archived medication lists become empty.
- [ ] Close and reopen the application; medication data remains deleted.
- [ ] Confirm application preferences unrelated to medication content are not falsely represented as erased.
- [ ] Confirm pending application notifications are removed.
- [ ] If notification cleanup is intentionally forced to fail in a test build, verify the UI states that medication data is already deleted and offers notification-only retry.

## 9. Accessibility validation

Repeat critical paths with these combinations:

| Text size | Display size | TalkBack |
|---|---|---|
| Default | Default | Off |
| Large | Default | Off |
| Largest available | Large | Off |
| Large | Default | On |
| Largest available | Large | On |

Verify:

- [ ] Dashboard actions are spoken in a logical order.
- [ ] Privacy, archive, reminder, edit, and delete icon actions have meaningful Persian labels.
- [ ] Form fields announce labels and entered values.
- [ ] Destructive confirmations clearly announce permanence and scope.
- [ ] Buttons remain reachable by scrolling.
- [ ] No text or action is clipped beyond recovery.
- [ ] Focus does not become trapped in sheets or dialogs.
- [ ] SnackBars do not contain the only durable explanation of an error.
- [ ] Color is not the only indicator of urgency or destructive state.

## 10. Upgrade checklist

This test requires two APKs signed with the same permanent upload key and increasing version codes.

Version A:

- [ ] Install the older signed APK.
- [ ] Create active and archived medication records.
- [ ] Create restock/correction history.
- [ ] Enable reminders.
- [ ] Record the database-visible state.

Version B:

- [ ] Confirm version code is higher than Version A.
- [ ] Install Version B over Version A without uninstalling.
- [ ] Confirm Android presents an update, not a new application.
- [ ] Confirm all active, archived, and history data remain.
- [ ] Confirm application launch succeeds after upgrade.
- [ ] Confirm notification permission state remains appropriate.
- [ ] Confirm notifications are rebuilt or retained as designed.
- [ ] Run the full-erasure flow after upgrade and confirm deletion remains complete after restart.

## 11. ADB installation alternative

For a trusted development computer with Android Platform Tools:

```bash
adb devices
adb install daro-ta-key-internal-release.apk
```

Upgrade an existing package signed by the same key:

```bash
adb install -r daro-ta-key-internal-release.apk
```

A signature mismatch during `adb install -r` is expected when switching from a debug certificate to the permanent internal certificate. Uninstall the old package only after accepting that its local app data will be removed:

```bash
adb uninstall ir.emadkarimi.darutakey
adb install daro-ta-key-internal-release.apk
```

## 12. Exit criteria before closed beta

- [ ] Clean install passes on at least two Android versions.
- [ ] Upgrade passes using two builds signed by the permanent upload key.
- [ ] Notification checklist passes on at least one physical device.
- [ ] Privacy erasure passes and remains deleted after restart.
- [ ] TalkBack and largest-text checks pass on a narrow phone.
- [ ] APK and AAB checksums and signing fingerprints are recorded.
- [ ] Final privacy policy and store disclosures match the tested build.
- [ ] Every failure is recorded with device, Android version, app version, exact steps, and screenshot/log where possible.
