# ADR-0007 — Medication lifecycle state machine

- Status: Accepted
- Date: 2026-07-21

## States

- `active`: available for details changes, quantity events, archive, and permanent deletion.
- `archived`: read-only; available only for restore or permanent deletion.
- `missing`: no persisted aggregate exists. All non-create commands fail.

Permanent deletion removes the aggregate and its dependent history. The system does not retain a tombstone, so a later create with a new or reused identifier is a new aggregate.

## Transitions

| Current state | Command | Result |
|---|---|---|
| active | update details | active |
| active | record quantity event | active |
| active | archive | archived |
| active | permanent delete | missing |
| archived | restore | active |
| archived | permanent delete | missing |

All other command/state combinations are rejected with a typed lifecycle exception. Missing aggregates produce a typed not-found exception.

## Enforcement

The policy is enforced inside both repository implementations. UI guards improve clarity but are not trusted as the enforcement boundary. SQLite checks and writes occur in the same transaction. Notification synchronization runs only after the repository command succeeds.

## UI consequences

Archived detail routes are read-only. Direct navigation to the edit route shows a restore-first state instead of constructing an edit form. Quantity controls and archive/edit actions are not built for archived aggregates.

## Validation

A shared contract test executes the same transition matrix against in-memory and SQLite repositories. Additional tests verify notification side effects and direct-route UI guards. Strict CI must pass schema parity, formatting, analysis, all tests, and an Android debug build before merge.
