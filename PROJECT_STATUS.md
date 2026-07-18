# Project Status

## Current phase

Phase 2: Local persistence and the core medication lifecycle UI are completed.

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
- [x] Medication details and inventory timeline
- [x] User-facing restock and correction flows
- [x] Archive confirmation with history preservation
- [x] Persian and Arabic numeric input parsing
- [x] CI code generation, schema diff, format, analyze, and tests
- [x] Automated domain, advertising, persistence, application, and widget tests

## Next engineering increment

1. Add medication metadata edit screen without creating inventory events unless the stock baseline changes.
2. Add archived-medication management and restore UI.
3. Add local notifications for low-stock alerts.
4. Generate and commit the Android platform project before release signing.
5. Integrate Adivery behind the existing `AdService` contract.
6. Add analytics events that contain no medication names or health data.
7. Produce a signed internal APK for device testing.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Repository is the source of truth for all subsequent engineering work.
