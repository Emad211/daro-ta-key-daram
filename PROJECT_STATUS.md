# Project Status

## Current phase

Phase 3: Structured consumption schedules are under implementation before physical-device verification.

## Completed

- [x] Product scope, safety boundaries, and ad-only monetization policy
- [x] Flutter application architecture and Persian RTL vertical slice
- [x] Drift/SQLite schema, snapshot enforcement, and transactional repository
- [x] Medication details, restock, correction, history, and archive flows
- [x] Stable notification IDs and versioned deep-link payloads
- [x] Pure low-stock/depleted notification planner
- [x] Android 13+ user-triggered notification permission flow
- [x] Inexact schedule, replace, cancel, and startup rebuild
- [x] Reboot and app-update receivers
- [x] Local timezone initialization and UTC fallback
- [x] Notification-aware repository decorator after successful persistence
- [x] Committed Android project with application ID `ir.emadkarimi.darutakey`
- [x] Medication metadata editing and archive management
- [x] Hardened stock calculation invariants
- [x] CI code generation, schema parity, formatting, analyzer, tests, and debug APK build

## Next engineering increment

1. Complete structured daily, every-N-days, and selected-weekday schedules.
2. Validate schema v1-to-v2 migration and schedule-change baselines.
3. Run the notification device-test checklist in `docs/07-notifications.md`.
4. Replace debug signing with a secure release signing workflow.
5. Integrate Adivery behind the existing `AdService` contract.
6. Add privacy-safe analytics containing no medication names, schedules, stock, or notes.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Active integration PR: `#16`
- Repository is the source of truth for all subsequent engineering work.
