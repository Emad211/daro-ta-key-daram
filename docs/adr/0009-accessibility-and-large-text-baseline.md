# ADR-0009 — Accessibility, large text, and RTL baseline

- Status: Proposed
- Date: 2026-07-21

## Context

The application is Persian-first, right-to-left, and intended for people who may rely on larger system text. Medication quantities, depletion warnings, destructive actions, and reminder controls must remain understandable and operable without requiring default text size, color perception, or icon recognition.

Flutter widget tests can reliably catch many regressions before physical-device review: rendering overflow, clipped controls, missing semantics on icon-only actions, and write flows that become unreachable on narrow screens. TalkBack behavior and final color contrast still require device and design review.

## Decision

- Treat RTL as the canonical layout direction for all product regression tests.
- Exercise representative narrow phone viewports at text scales 1.0, 1.3, and 2.0.
- Fail tests on any uncaught Flutter rendering or semantics exception.
- Keep primary write actions reachable by scrolling rather than shrinking text below the theme baseline.
- Replace rigid horizontal action layouts with adaptive layouts when large text cannot fit.
- Give every interactive icon-only control a meaningful Persian tooltip/semantic label.
- Keep state and urgency labels textual; color and icons are supplementary only.
- Keep product-controlled interactive targets at least 48 logical pixels in both dimensions.

## Automated coverage

The accessibility smoke suite traverses:

- medication dashboard and reminder/archive actions
- add-medication form
- medication details and quantity-review dialog
- edit-medication form
- archived-medication restore and permanent-delete actions

The suite uses a 360 × 640 logical-pixel viewport and validates scales 1.0, 1.3, and 2.0.

## Device-only follow-up

The following remain outside widget-test scope:

- TalkBack reading order and spoken phrasing
- focus traversal with a hardware keyboard or switch access
- manufacturer-specific font and display-size combinations
- final brand color contrast measurements
- notification accessibility on a physical Android device

## Consequences

Accessibility regressions become release-blocking through the existing strict CI pipeline. Some cards and action groups may grow vertically at large text scales; preserving meaning and operability takes priority over fixed visual height.
