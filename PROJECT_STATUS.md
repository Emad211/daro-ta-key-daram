# Project Status

## Current phase

Phase 2: Local persistence foundation completed; medication lifecycle UI is next.

## Completed

- [x] Product scope and non-goals
- [x] MVP functional requirements
- [x] Safety and privacy boundaries
- [x] Monetization principles and ad frequency caps
- [x] Architecture Decision Records
- [x] Flutter source scaffold
- [x] Core stock calculation domain model
- [x] Dashboard and add-medication form
- [x] Drift/SQLite schema version 1
- [x] Version-controlled schema snapshot
- [x] Transactional medication repository
- [x] Initial, restock, and correction inventory events
- [x] Archive, restore, and cascade deletion at repository level
- [x] Persistence across database close and reopen
- [x] CI code generation, schema diff, format, analyze, and tests
- [x] Automated domain, advertising, widget, and persistence tests

## Next engineering increment

1. Add medication details and edit screen.
2. Add user-facing restock/correction flow and history timeline.
3. Add archive/restore management screen.
4. Add local notifications for low-stock alerts.
5. Generate and commit the Android platform project before release signing.
6. Integrate Adivery behind the existing `AdService` contract.
7. Add analytics events that contain no medication names or health data.
8. Produce a signed internal APK for device testing.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Repository is the source of truth for all subsequent engineering work.
