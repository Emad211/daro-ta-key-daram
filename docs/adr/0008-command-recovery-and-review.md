# ADR-0008 — Command recovery, review, and undo

- Status: Accepted
- Date: 2026-07-21

## Context

Medication write commands can fail because the aggregate was deleted, archived, changed concurrently, or rejected by validation. A generic failure message is not sufficient for a Persian consumer application, and clearing a form after a failed command can cause data-entry errors. Quantity corrections and restocks also replace the calculation baseline, so accidental submission has a lasting effect on history.

## Decision

- UI messages are derived from typed repository failures in the medication presentation layer. Core code does not depend on medication-specific failures.
- Every write surface has an explicit in-flight guard. A second tap cannot start a second repository command.
- Add, edit, and quantity forms retain controllers and schedule selections after failure.
- Restock and correction require a review dialog showing the current estimate and proposed new baseline before persistence.
- Cancelling a review or confirmation performs no repository call.
- Archive success exposes a one-step undo action that executes the typed restore command. Permanent deletion remains confirmation-only and has no undo.
- Repository atomicity remains the persistence boundary. Notification synchronization runs only after a successful repository command.

## Consequences

- Users can correct a failed entry without retyping it.
- Quantity history cannot be changed by merely opening or cancelling a review.
- Archive is recoverable without weakening permanent-delete semantics.
- Widget tests must hold commands pending to prove buttons are disabled and call counts remain one.
- Negative tests must prove cancelled and rejected flows leave medication and inventory history unchanged.

## Validation

Strict CI must pass canonical formatting, analyzer, the complete test suite, Drift schema parity, and an Android debug APK build before merge.
