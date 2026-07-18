# Project Status

## Current phase

Phase 1: Product engineering foundation and first vertical slice.

## Completed

- [x] Product scope and non-goals
- [x] MVP functional requirements
- [x] Safety and privacy boundaries
- [x] Monetization principles and ad frequency caps
- [x] Architecture Decision Records
- [x] Flutter source scaffold
- [x] Core stock calculation domain model
- [x] In-memory data source
- [x] Dashboard and add-medication form
- [x] Unit test suite for the calculation engine
- [x] CI workflow

## Next engineering increment

1. Generate and commit the Android platform project.
2. Replace the in-memory repository with Drift/SQLite.
3. Add medication edit, archive and restock history.
4. Add local notifications for low-stock alerts.
5. Integrate Adivery behind the existing `AdService` contract.
6. Add analytics events that contain no medication names or health data.
7. Produce signed internal APK for device testing.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Repository is the source of truth for all subsequent engineering work.
