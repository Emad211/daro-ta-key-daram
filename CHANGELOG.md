# Changelog

## 0.1.0-dev.2 — 2026-07-18

### Added

- Drift/SQLite schema version 1
- Transactional medication repository
- Inventory event history for initial, restock, and correction baselines
- Archive, restore, lookup, and cascade deletion operations
- File-based SQLite reopen persistence test
- Version-controlled Drift schema snapshot
- CI steps for Drift code generation and schema snapshot verification

### Changed

- Production dependency injection now uses `DriftMedicationRepository`
- Widget tests explicitly override persistence with an in-memory repository
- Dependency versions are pinned to the Flutter 3.44.6-compatible Drift toolchain

## 0.1.0-dev.1 — 2026-07-18

### Added

- Product vision, MVP requirements and engineering roadmap
- Feature-first application architecture
- Medication stock depletion calculation engine
- Persian RTL dashboard and add-medication flow
- In-memory repository for the first vertical slice
- Unit tests for stock calculations
- Advertising abstraction and monetization policy
- GitHub Actions CI definition
