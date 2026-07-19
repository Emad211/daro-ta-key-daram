# ADR-0006 — Typed write boundaries

- Status: Accepted
- Date: 2026-07-19

## Context

A single aggregate overwrite operation could change descriptive fields, schedule configuration, quantity baseline, lifecycle state, and history as one undifferentiated write. That made accidental cross-boundary mutations possible and forced every caller to understand persistence invariants.

## Decision

The repository exposes separate commands:

- `create` creates one aggregate and one initial history event.
- `updateDetails` accepts a typed command containing name, unit, schedule, alert lead, and notes only.
- `recordInventoryEvent` is the only caller-controlled path for quantity and effective-time changes.
- archive, restore, and permanent delete remain explicit lifecycle commands.

When a schedule changes, the repository derives the current estimated quantity using the previous schedule and creates a new boundary event inside the same transaction. The caller cannot supply that derived quantity.

## Consequences

- UI code cannot overwrite the quantity baseline while editing descriptive fields.
- A details-only update creates no history event.
- A schedule update creates exactly one derived boundary event.
- Quantity events preserve descriptive fields and schedule configuration.
- SQLite and in-memory implementations must pass the same behavioral contract.
- Notification synchronization occurs only after persistence succeeds.
