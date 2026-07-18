# Project Status

## Current phase

Phase 3: Android local-notification integration is implemented and awaiting physical-device verification.

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
- [x] CI code generation, schema parity, formatting, analyzer, tests, and debug APK build

## Next engineering increment

1. Run the notification device-test checklist in `docs/07-notifications.md` on Android.
2. Add medication metadata editing without accidental inventory events.
3. Add archived-medication management and restore UI.
4. Replace debug signing with a secure release signing workflow.
5. Integrate Adivery behind the existing `AdService` contract.
6. Add privacy-safe analytics containing no medication names, dosing, stock, or notes.
7. Produce a closed-beta APK/AAB for 10–20 testers.

## Repository

- GitHub repository: `Emad211/daro-ta-key-daram`
- Default branch: `main`
- Active integration PR: `#9`
- Repository is the source of truth for all subsequent engineering work.
