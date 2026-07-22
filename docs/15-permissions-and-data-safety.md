# 15 — Android permissions and data-processing baseline

## Exact v1.0 design

The signed v1.0 candidate is designed to operate without an account, backend, advertising SDK, analytics SDK, crash-reporting SDK, cloud synchronization, or Android Internet permission.

## Intentional Android permissions

| Permission | Purpose | User trigger / behavior |
|---|---|---|
| `android.permission.POST_NOTIFICATIONS` | Android 13+ runtime permission for optional inventory reminders | Requested only after the user taps the reminder action; denial does not block medication features |
| `android.permission.RECEIVE_BOOT_COMPLETED` | Rebuild locally scheduled reminders after reboot/app replacement | No user content is transmitted; scheduling remains on device |

The merged release manifest may include ordinary non-dangerous platform/library declarations required by Flutter or the notification plugin. CI rejects Internet, advertising ID, exact alarm, location, contacts, calendar, broad storage, camera, microphone, phone, account, and broad package-query permissions.

## Backup and transfer

Medication information is sensitive local data. The application explicitly:

- sets `android:allowBackup="false"`;
- provides legacy backup exclusion rules;
- provides Android 12+ cloud-backup and device-transfer exclusion rules;
- excludes root, files, databases, shared preferences, and external app domains;
- does not claim that uninstall or Android clear-data is recoverable.

## Network security

- `android:usesCleartextTraffic="false"` is explicit.
- A Network Security Configuration also denies cleartext traffic.
- The release has no `INTERNET` permission.
- A future network or advertising SDK requires a new manifest/dependency/privacy review and cannot be introduced silently.

## Local data categories

The user may enter:

- medication name;
- inventory unit and stock baseline;
- consumption schedule supplied by the user;
- reminder lead time;
- optional notes;
- restock, correction, and schedule-change history;
- active/archive state.

These values are stored in the app's local Drift/SQLite database. They are not sent off device by the v1.0 codebase.

## Notification data

Notifications use a stable internal medication ID for replacement/navigation. The current channel is marked private for lock-screen handling. Notification content may include the medication name and a coarse remaining-days message after the user enables reminders; it does not include dose instructions, notes, diagnoses, or the complete history. Device-only privacy verification remains required.

## Deletion

- Individual archived medications can be permanently deleted.
- The privacy center can atomically delete every active/archived medication and cascaded inventory history.
- Notification cleanup is serialized with rebuild/reschedule operations so deletion cannot be overtaken by in-flight scheduling.
- Notification cleanup failure is reported separately without falsely claiming the database was restored.

## Store declaration baseline

For the exact ad-free/network-free v1.0 candidate:

- data collected/transmitted off device by the app or included SDKs: **none**;
- data shared with third parties: **none**;
- local medication/health-related data: **processed only on device**;
- account creation: **none**;
- user deletion control: **available in app**;
- encryption in transit: **not applicable because no network transfer exists**.

This baseline must be regenerated from the exact merged release manifest and dependency inventory. Publisher console answers and public privacy policy remain the publisher's responsibility and must be updated before any SDK/network behavior changes.
