# 12 — Performance, release size, and Jalali dates

## Why the installed build felt slow and oversized

The first physical-device build was a Flutter debug APK. APK inspection found that most of its approximately 155 MB came from debug/runtime payload rather than medication features:

- Dart `kernel_blob.bin` was approximately 71 MB;
- Flutter engine libraries for arm64, armv7, and x86_64 were bundled together;
- debug Vulkan validation libraries were present;
- the package was therefore unsuitable for judging production startup, runtime smoothness, or final download size.

Debug remains useful for development diagnostics. Physical-device performance conclusions must use release or profile mode.

## Measured release evidence

Strict CI run `#374` produced and verified all three release artifacts with a disposable validation key:

| Artifact | Exact bytes | Approximate MiB | Purpose |
|---|---:|---:|---|
| Arm64 release APK | 21,796,928 | 20.79 | recommended physical-device build |
| Universal release APK | 63,045,908 | 60.13 | compatibility fallback with multiple ABIs |
| Release AAB | 60,726,842 | 57.91 | store-oriented bundle; not directly installable |

The arm64 APK SHA-256 was `86502f9b6decb1913101fab51f55b015b68415e40ec0756037f84f63300d585b`.

The arm64 APK is roughly one seventh of the installed debug APK. Its largest entries were:

- Flutter engine `libflutter.so`: approximately 11.05 MiB;
- AOT application `libapp.so`: approximately 7.31 MiB;
- SQLite `libsqlite3.so`: approximately 1.65 MiB;
- Android bytecode and remaining resources: less than 1 MiB combined.

This breakdown shows that superficial Android resource shrinking cannot remove most of the package. The useful optimization targets are architecture-specific delivery, startup work, and measured changes to AOT application code.

## Release artifact contract

Strict CI and the secret-backed release workflow produce three distinct outputs:

1. **Arm64 release APK** — recommended for most modern physical Android devices.
2. **Universal release APK** — compatibility fallback containing multiple ABIs.
3. **AAB** — store submission artifact and not directly installable.

All APKs are verified with Android SDK `apksigner`; the AAB is verified with `jarsigner`. SHA-256 files and exact byte sizes are included in build metadata.

Measured regression gates:

- universal release APK: at most 61 MiB;
- arm64 release APK: at most 22 MiB.

The arm64 gate is intentionally close to the measured 20.79 MiB baseline. Any growth above 22 MiB requires explicit analysis. The universal gate is a compatibility guard; it is not the recommended download for modern phones.

The earlier aspirational universal target of 45 MiB is not realistic while the package carries multiple Flutter engines. The product-facing target is now the architecture-specific arm64 package, with a future goal below 20 MiB only when a measured and safe reduction is identified.

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
- a new inventory event cannot precede the medication's current inventory baseline;
- `createdAt` remains the real command time while `effectiveAt` may be a selected past time.

The monotonic baseline rule is enforced in the UI, application service, Drift repository, and in-memory repository. This removes the earlier semantic mismatch between test and SQLite implementations.

This boundary avoids mixing calendar-specific value types into medication calculations or database schema.

## Validation plan

Automated gates:

- known Gregorian/Jalali conversion fixtures;
- Persian-digit date and time output;
- text scale 2.0 RTL rendering of the date field;
- backdated inventory-event behavior;
- future-date and pre-baseline rejection without side effects;
- direct Drift and in-memory repository parity tests;
- full regression suite, analyzer, formatter, and Drift schema parity;
- universal/arm64 release builds, signature verification, checksums, actual artifact preservation, and measured size limits.

Physical-device gates:

- compare cold and warm launch of debug versus arm64 release;
- record time to first usable dashboard and first tap response;
- verify the Persian picker, backdated event, history, and depletion date;
- verify notification rebuild after restart and upgrade;
- repeat largest-text and TalkBack checks.

## Follow-up requirements

After the first measured release run:

1. keep the arm64 package below the 22 MiB regression gate;
2. add a repeatable profile-mode startup sheet to Issue `#30`;
3. select a stable emulator or physical-device target before introducing macrobenchmarks;
4. evaluate R8/resource shrinking only with plugin compatibility and release-regression evidence;
5. investigate `libapp.so` growth with Flutter's `--analyze-size` output before removing features;
6. keep Dart obfuscation as a separate release-security decision, not a presumed performance optimization.
