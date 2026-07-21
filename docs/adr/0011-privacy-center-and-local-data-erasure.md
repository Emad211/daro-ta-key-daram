# ADR-0011 — Privacy center and local medication-data erasure

- Status: Accepted
- Date: 2026-07-21

## Context

The application stores medication names, schedules, stock baselines, optional notes, archive state, and inventory history locally. Per-medication permanent deletion exists, but users also need one understandable control that removes every medication aggregate before closed beta.

Medication rows are aggregate roots. Inventory-event rows reference them with `ON DELETE CASCADE`. Notification cleanup is external to SQLite and cannot participate in the database transaction.

## Decision

- Add one `deleteAll` command to the medication repository boundary.
- Drift deletes all medication aggregate roots in one transaction; inventory history is removed by enforced foreign-key cascade.
- The in-memory repository mirrors the same aggregate and event cleanup semantics for tests.
- Notification-aware repository decoration does not hide the two-phase nature of full erasure.
- A dedicated application service performs database erasure first and then requests `cancelAll` from the local notification service.
- The service returns a typed result distinguishing:
  - complete success;
  - medication data deleted but notification cleanup failed.
- A notification cleanup failure never claims database rollback. The UI shows that data is gone and provides a retry for notification cleanup.
- Cancelling or rejecting the destructive confirmation invokes no command and creates no side effects.
- Duplicate destructive submissions are disabled.
- The privacy center explains current local storage, medical non-goals, data deletion, and the boundary of future advertising SDK processing.
- The destructive action remains reachable in Persian RTL on a 360×640 viewport at text scales 1.0, 1.3, and 2.0.

## Data scope

Deleted:

- active medication rows;
- archived medication rows;
- all inventory events and schedule-change baselines related to those rows.

Not deleted by this command:

- application preferences unrelated to medication content;
- advertising frequency-cap rows;
- Android or store-managed data outside the app database;
- future third-party SDK data outside the medication repository boundary.

The UI calls the action «حذف همه اطلاعات دارویی» rather than claiming to erase the entire device or every third-party record.

## Validation evidence

Strict Flutter CI run `#345` passed:

- signing and repository-secret guards;
- Drift generation and schema parity;
- canonical formatting and analyzer;
- the complete regression suite;
- atomic Drift deletion of active and archived aggregates plus cascaded history;
- preservation of unrelated application preferences;
- notification cleanup success, failure, and retry outcomes;
- destructive-dialog cancellation without side effects;
- dashboard-to-privacy traversal at text scales 1.0, 1.3, and 2.0;
- debug APK build;
- disposable-key release AAB build, signature verification, checksum generation, artifact upload, and signing-material cleanup.

## Consequences

The database operation is atomic, but end-to-end erasure is a two-phase workflow because notification cancellation is external. Medication data is never restored or represented as restored merely because notification cleanup failed.

The public Persian privacy policy remains a pre-publication draft until publisher identity, contact information, HTTPS policy URL, target stores, permissions, and the final third-party SDK list are known and verified against the release build.
