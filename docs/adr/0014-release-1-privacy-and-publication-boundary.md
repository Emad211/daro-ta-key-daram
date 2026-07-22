# ADR-0014 — Release 1.0 privacy and publication boundary

- Status: Proposed
- Date: 2026-07-22

## Context

The product stores medication names, schedules, quantities, notes, and inventory history locally. Version 1.0 is offline-first and has no account, cloud medication store, advertising SDK, or analytics SDK. Public release requires Android hardening, reproducible artifacts, truthful store disclosures, permanent signing ownership, and physical-device evidence.

## Decision

- Version 1.0 advertises only the implemented Persian locale.
- Medication data is excluded from Android cloud backup and device transfer until an explicit encrypted and consented backup product exists.
- Cleartext network traffic is rejected.
- The release candidate carries no Internet permission, ad SDK, or analytics SDK. Adding any of them requires a separate privacy/data-safety review.
- Release builds enable R8 code shrinking and Android resource shrinking, with notification plugin entry points conservatively retained.
- Static CI checks the manifest, package ID, SDK levels, locale boundary, Jalali dependency pin, release version, and store-material inventory.
- Built APK permissions are inspected separately from source-manifest checks.
- Candidate engineering checks and public-publication checks are separate. Publication mode requires permanent signing, legal identity, support contact, HTTPS privacy policy, approved assets, store accounts, and physical-device signoff.
- Open-source license text is reachable from the privacy/about surface using Flutter's license registry.

## Consequences

The repository can produce a high-confidence release candidate without pretending external ownership and legal gates are complete. Backup is intentionally unavailable in 1.0. Ads and analytics remain disabled, so the first release may have no monetization until an audited Adivery integration and updated disclosure are ready.
