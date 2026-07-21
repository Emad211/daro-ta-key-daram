# 06 — Accessibility test matrix

## Automated CI baseline

| Surface | RTL | Text 1.0 | Text 1.3 | Text 2.0 | Narrow 360×640 | Semantics |
|---|---:|---:|---:|---:|---:|---:|
| Medication dashboard | ✓ | ✓ | ✓ | ✓ | ✓ | reminder, archive |
| Add medication | ✓ | ✓ | ✓ | ✓ | ✓ | primary save action |
| Medication details | ✓ | ✓ | ✓ | ✓ | ✓ | edit, archive |
| Quantity review | ✓ | ✓ | ✓ | ✓ | ✓ | cancel, confirm |
| Edit medication | ✓ | ✓ | ✓ | ✓ | ✓ | primary save action |
| Archived medications | ✓ | ✓ | ✓ | ✓ | ✓ | restore, permanent delete |

The widget suite fails on uncaught Flutter layout, rendering, or semantics exceptions. Primary actions remain reachable by realistic swiping; tests never reduce system text scale to make a control fit.

Strict Flutter CI run `#283` validated the complete matrix together with Drift schema parity, canonical formatting, analyzer, the full regression suite, Android debug APK creation, and artifact upload.

## Product rules

- Persian RTL is the canonical product direction.
- Icon-only interactive controls require meaningful Persian tooltips and explicit semantic labels.
- Color is supplementary. Urgency and lifecycle state require visible text.
- Product-controlled touch targets must be at least 48 logical pixels.
- Horizontal action groups adapt vertically when text or available width cannot fit.
- Dialog content that can grow with system text remains scrollable.
- Dropdown selections remain single-line and ellipsized rather than overflowing their field.

## Physical-device verification

These checks remain manual and must be completed before closed beta:

- TalkBack reading order and spoken labels
- focus traversal and switch-access behavior
- display size plus font size combinations on Android
- notification content and actions with TalkBack
- contrast review against final brand colors and assets
- gesture reachability on a small physical phone

Record device model, Android version, display size, font size, locale, and result for every manual run. Passing the automated matrix does not mark these device-only checks complete.
