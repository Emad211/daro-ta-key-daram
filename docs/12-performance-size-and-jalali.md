# 12 — Performance, release size, and Jalali dates

## Why the installed build felt slow and oversized

The first physical-device build was a Flutter debug APK. APK inspection found that most of its approximately 155 MB came from debug/runtime payload rather than medication features:

- Dart `kernel_blob.bin` was approximately 71 MB;
- Flutter engine libraries for arm64, armv7, and x86_64 were bundled together;
- debug Vulkan validation libraries were present;
- the package was therefore unsuitable for judging production startup, runtime smoothness, or final download size.

Debug remains useful for development diagnostics. Physical-device performance conclusions must use release or profile mode.

## Release artifact contract

Strict CI and the secret-backed release workflow produce three distinct outputs:

1. **Arm64 release APK** — recommended for most modern physical Android devices.
2. **Universal release APK** — compatibility fallback containing multiple ABIs.
3. **AAB** — store submission artifact and not directly installable.

All APKs are verified with Android SDK `apksigner`; the AAB is verified with `jarsigner`. SHA-256 files and exact byte sizes are included in build metadata.

Initial baseline gates:

- universal release APK: at most 60 MiB;
- arm64 release APK: at most 30 MiB.

These are first-pass regression limits, not the final product targets. After exact CI measurements, the target is to move toward 45 MiB universal and 25 MiB arm64 without unsafe plugin removal or unmeasured changes.

## Startup contract

Notification initialization is optional and must not compete with the first frame. It starts only after the first rendered frame. Debug/profile builds emit local startup milestones:

- application start;
- first frame rendered;
- notification initialization started;
- notification initialization completed or failed.

The milestones contain elapsed time only and no medication or user content. Release builds do not emit these diagnostics.

Database or isolate behavior must not be changed merely because a debug build feels slow. Further changes require release/profile measurements on a named device.

## Jalali boundary

The application continues to store and calculate normal Dart `DateTime` values. This preserves Drift storage, stock arithmetic, sorting, notification scheduling, and migration behavior.

Jalali conversion is a presentation/input boundary:

- all visible medication dates use one central Jalali formatter;
- displayed digits are Persian;
- the Material Persian picker is used for date selection;
- selected Jalali dates are converted back to Gregorian `DateTime` before entering the domain/application layers;
- future inventory effective times are rejected;
- `createdAt` remains the real command time while `effectiveAt` may be a selected past time.

This boundary avoids mixing calendar-specific value types into medication calculations or database schema.

## Validation plan

Automated gates:

- known Gregorian/Jalali conversion fixtures;
- Persian-digit date and time output;
- text scale 2.0 RTL rendering of the date field;
- backdated inventory-event behavior;
- future-date rejection without side effects;
- full regression suite, analyzer, formatter, and Drift schema parity;
- universal/arm64 release builds, signature verification, checksums, actual artifact preservation, and size limits.

Physical-device gates:

- compare cold and warm launch of debug versus arm64 release;
- record time to first usable dashboard and first tap response;
- verify the Persian picker, backdated event, history, and depletion date;
- verify notification rebuild after restart and upgrade;
- repeat largest-text and TalkBack checks.

## Follow-up requirements

After the first measured release run:

1. replace baseline size limits with evidence-based tighter budgets;
2. add a repeatable profile-mode startup sheet to Issue `#30`;
3. select a stable emulator or physical-device target before introducing macrobenchmarks;
4. evaluate R8/resource shrinking only with plugin compatibility and release-regression evidence;
5. keep Dart obfuscation as a separate release-security decision, not a presumed performance optimization.
