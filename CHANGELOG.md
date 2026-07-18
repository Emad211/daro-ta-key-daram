# Changelog

## 0.1.0-dev.4 — 2026-07-18

### Added

- Committed Android platform project with application ID `ir.emadkarimi.darutakey`
- Android local notification adapter using `flutter_local_notifications` 22.0.1
- Device timezone initialization using `flutter_timezone` and the IANA timezone database
- Stable, replaceable inexact low-stock and depleted notifications
- Android 13+ user-triggered permission flow
- Notification deep links to medication details
- Boot and app-update notification receivers
- Notification-aware repository decorator for create, restock, correction, archive, restore, and delete
- Debug APK build and downloadable CI artifact
- ADR and device-test checklist for notifications
- Widget tests for no startup permission prompt and notification launch navigation

### Changed

- CI now validates the committed Android project and builds a real debug APK
- Lifecycle writes synchronize notifications only after persistence succeeds
- Notification failures remain non-blocking for medication operations

## 0.1.0-dev.3 — 2026-07-18

### Added

- Medication details route and tappable dashboard cards
- Current stock, depletion estimate, recorded daily consumption, alert lead time, and notes display
- Restock and stock-correction bottom-sheet flows
- Inventory timeline backed by immutable domain events
- Archive confirmation preserving medication history
- Recoverable medication-not-found state
- Persian and Arabic numeric input parser
- Inventory event application service
- Tests for localized parsing, command creation, Drift history ordering, and widget lifecycle flows

### Changed

- Repository contract now exposes a reactive inventory-history stream
- In-memory test repository now mirrors initial, restock, correction, archive, and delete behavior
- Purchase flow records the total stock after purchase rather than an ambiguous added quantity

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
