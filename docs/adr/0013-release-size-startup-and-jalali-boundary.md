# ADR-0013 — Release size, startup work, and Jalali presentation boundary

- Status: Proposed
- Date: 2026-07-22

## Context

A physical-device smoke test used a roughly 155 MB debug APK and reported severe slowness. Inspection showed that the package was dominated by debug-only Dart and Flutter runtime payloads plus multiple ABIs. The same test also showed that Gregorian dates do not meet the Persian product experience.

The application relies on Dart `DateTime` for medication stock calculations, Drift persistence, event ordering, and notification scheduling. Replacing domain dates with a calendar-specific type would create unnecessary migration and correctness risk.

## Decision

- Debug APKs are development artifacts and are excluded from production size and performance conclusions.
- CI preserves actual universal and arm64 release APKs and a release AAB.
- Modern physical-device testing uses the arm64 release APK by default.
- APK signatures are verified with `apksigner`; the AAB is verified with `jarsigner`.
- Exact byte sizes and SHA-256 checksums are build evidence.
- Initial regression budgets are 60 MiB universal and 30 MiB arm64; tighter targets follow measured evidence.
- Optional notification initialization starts after the first rendered frame.
- Startup diagnostics run only outside release and contain elapsed milestones without user data.
- Domain, persistence, and notification layers continue to use `DateTime`.
- Jalali conversion occurs only at presentation/input boundaries through one formatter and one reusable date/time field.
- The selected package is `persian_datetime_picker` version `3.2.0`.
- User-selected inventory times may be in the past but never in the future.
- Inventory `createdAt` records command time; `effectiveAt` records the selected inventory time.

## Consequences

The build pipeline becomes slower because it creates a universal APK, an arm64 APK, and an AAB. The resulting evidence is more useful: device testers receive a small architecture-specific release APK, while CI can detect accidental size regressions and missing artifacts.

Presentation uses the Iranian calendar without introducing calendar-specific storage. Any future locale expansion can provide a different formatter/picker while leaving medication calculations unchanged.

The initial size budgets are deliberately conservative. Passing them does not prove that the app is sufficiently small; it establishes a measured baseline that can be tightened safely.

## Validation required before acceptance

- package resolution and analyzer pass;
- known conversion fixtures pass;
- Persian date fields remain usable in narrow RTL layouts with large text;
- backdated inventory events preserve command time and reject future times;
- all visible medication dates use the central formatter;
- release APKs are present in artifacts and pass signature verification;
- exact universal and arm64 sizes are recorded;
- full strict CI passes on the exact PR head;
- arm64 release APK is installed and compared with debug on a physical device.
