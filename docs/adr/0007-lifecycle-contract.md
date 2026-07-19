# ADR-0007 — Lifecycle contract

- Status: Proposed
- Date: 2026-07-19

## States

An aggregate is either active, archived, or absent after permanent deletion.

## Rules

- New aggregates must start active.
- Details updates and quantity events are accepted only while active.
- Archive and restore are idempotent for an existing aggregate.
- Permanent delete removes the aggregate and all dependent history in one transaction.
- Commands targeting an absent aggregate fail explicitly.
- Event identifiers are unique across the repository.
- Future-effective events are rejected consistently by every implementation.
- Notification work runs only after persistence succeeds.

This ADR is completed when the same lifecycle contract passes against both repository implementations and strict CI produces a valid Android build.
