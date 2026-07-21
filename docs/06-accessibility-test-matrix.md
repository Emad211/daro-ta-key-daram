# 06 — Accessibility test matrix

## Automated CI baseline

| Surface | RTL | Text 1.0 | Text 1.3 | Text 2.0 | Narrow 360×640 | Semantics |
|---|---:|---:|---:|---:|---:|---:|
| Medication dashboard | ✓ | ✓ | ✓ | ✓ | ✓ | privacy, reminder, archive |
| Add medication | ✓ | ✓ | ✓ | ✓ | ✓ | primary save action |
| Medication details | ✓ | ✓ | ✓ | ✓ | ✓ | edit, archive |
| Quantity review | ✓ | ✓ | ✓ | ✓ | ✓ | cancel, confirm |
| Edit medication | ✓ | ✓ | ✓ | ✓ | ✓ | primary save action |
| Archived medications | ✓ | ✓ | ✓ | ✓ | ✓ | restore, permanent delete |
| Privacy center | ✓ | ✓ | ✓ | ✓ | ✓ | destructive confirmation and retry |

The widget suite fails on uncaught Flutter layout, rendering, or semantics exceptions. Primary actions remain reachable by realistic swiping; tests never reduce system text scale to make a control fit.

The privacy-center suite additionally proves that cancelling the destructive dialog has no persistence or notification side effects, successful confirmation removes active and archived medication data, and notification cleanup failure remains recoverable without pretending the database was restored.

Strict Flutter CI run `#283` established the original medication-flow matrix. PR `#27` extends the same release-blocking baseline to the privacy center and full local medication-data erasure.

## Product rules

- Persian RTL is the canonical product direction.
- Icon-only interactive controls require meaningful Persian tooltips and explicit semantic labels.
- Color is supplementary. Urgency and lifecycle state require visible text.
- Product-controlled touch targets must be at least 48 logical pixels.
- Horizontal action groups adapt vertically when text or available width cannot fit.
- Dialog content that can grow with system text remains scrollable.
- Dropdown selections remain single-line and ellipsized rather than overflowing their field.
- Destructive privacy controls state their exact data scope and never imply deletion of Android, store, or third-party data outside the app boundary.

## Physical-device verification

These checks remain manual and must be completed before closed beta:

- TalkBack reading order and spoken labels
- focus traversal and switch-access behavior
- display size plus font size combinations on Android
- notification content and actions with TalkBack
- contrast review against final brand colors and assets
- gesture reachability on a small physical phone

Record device model, Android version, display size, font size, locale, and result for every manual run. Passing the automated matrix does not mark these device-only checks complete.
