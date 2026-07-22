# 14 — Rollout, rollback, and incident response

## Versioning rules

- `versionName` follows semantic versioning for user-visible releases.
- Android `versionCode` is a positive integer and increases for every file uploaded to a store or distributed as an upgrade candidate.
- A used version code is never reused, even after rejection or rollback.
- Every upgrade must use the same permanent signing identity as the installed production build.
- Debug or disposable-CI certificates never establish update continuity.

## Staged rollout

1. Engineering validation with disposable CI signing.
2. Permanent-key internal build and clean-install test.
3. Same-key Version A → Version B upgrade test.
4. Closed beta with 10–20 invited users.
5. Limited store rollout where the target store supports staging.
6. Public rollout only after critical monitoring and support readiness.

## Stop conditions

Stop distribution immediately for any reproducible:

- crash loop or failure to open the local database;
- medication/history data loss or partial write;
- incorrect inventory baseline or date conversion;
- notification for a deleted/archived medication;
- destructive action without clear confirmation;
- release signing/version mismatch;
- unexpected network, advertising, analytics, dangerous permission, or exported component;
- inaccessible critical action at supported large text/TalkBack settings;
- privacy-policy behavior mismatch.

## Rollback model

Android does not support silently replacing a higher version code with a lower one. A rollback normally means:

- stop or pause the current rollout;
- fix the issue from the last known-good source;
- increase `versionCode`;
- build with the same permanent key;
- test upgrade from both the last known-good and faulty builds;
- distribute the new corrective release.

Never instruct users to bypass signature verification. Uninstall/reinstall is a last resort because it removes local medication data unless an explicit export/restore feature exists.

## Incident classes

### Calculation or Jalali date error

- preserve exact app version, timezone, locale, and reproduction inputs using fictional values where possible;
- add a failing domain/repository test before changing logic;
- verify no historical event is rewritten;
- publish corrected wording if only presentation was wrong.

### Database or migration failure

- do not auto-delete or recreate the production database;
- collect database version and stack trace without medication row contents;
- reproduce on a copy/fixture;
- add forward-only recovery or migration with rollback tests.

### Notification misdelivery

- record notification ID, app version, Android version, permission state, lifecycle action, reboot/update/timezone context;
- do not request the user's medication list;
- cancel/rebuild only through the coordinator boundary;
- verify archive/delete/full erasure cannot be overtaken by in-flight scheduling.

### Signing-key incident

- stop release workflow access;
- rotate repository secret access where possible;
- follow each store's upload-key recovery process;
- do not generate a replacement key and assume existing installs can update;
- preserve public certificate fingerprints and incident timestamps outside Git.

### Privacy mismatch or unexpected SDK/network behavior

- disable the optional SDK or release path immediately;
- compare merged manifest and dependency inventory with the published policy;
- update the policy/store declarations before re-enabling;
- never use medication data for advertising, analytics, attribution, or support evidence.

### Inappropriate advertising

Advertising is disabled in v1.0. If enabled later, the kill switch must fall back to `NoopAdService` without affecting core medication features. No ad appears in forms, permission, notification, privacy, destructive, critical, or depleted flows.

## Last-known-good record

For each accepted release preserve:

- release tag and commit;
- version name/code;
- APK/AAB checksums and sizes;
- signer certificate SHA-256;
- dependency lockfile and release dossier;
- privacy-policy version/URL;
- store rollout state;
- device-test and beta evidence.

No artifact containing a private key, password, real medication data, or production console secret belongs in the record.
