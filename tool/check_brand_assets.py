#!/usr/bin/env python3
from __future__ import annotations

import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = (
    "android/app/src/main/res/values/colors.xml",
    "android/app/src/main/res/drawable/ic_launcher_background.xml",
    "android/app/src/main/res/drawable/ic_launcher_foreground.xml",
    "android/app/src/main/res/drawable/ic_launcher_monochrome.xml",
    "android/app/src/main/res/drawable/launch_logo.xml",
    "android/app/src/main/res/drawable/ic_notification.xml",
    "android/app/src/main/res/mipmap-anydpi/ic_launcher.xml",
    "android/app/src/main/res/mipmap-anydpi/ic_launcher_round.xml",
    "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
    "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml",
    "android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml",
    "android/app/src/main/res/mipmap-anydpi-v33/ic_launcher_round.xml",
    "android/app/src/main/res/values-v31/styles.xml",
    "android/app/src/main/res/values-night-v31/styles.xml",
    "store/assets/app-icon-source.svg",
    "store/assets/app-icon-512.png",
)

OLD_FLUTTER_BITMAPS = (
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
)


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError(f"{path} is not a valid PNG with an IHDR chunk")
    return struct.unpack(">II", data[16:24])


def main() -> int:
    errors: list[str] = []

    for relative in REQUIRED:
        if not (ROOT / relative).is_file():
            errors.append(f"missing required brand asset: {relative}")

    for relative in OLD_FLUTTER_BITMAPS:
        if (ROOT / relative).exists():
            errors.append(f"default Flutter launcher bitmap must be removed: {relative}")

    manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text()
    for required_fragment in (
        'android:icon="@mipmap/ic_launcher"',
        'android:roundIcon="@mipmap/ic_launcher_round"',
        'android:localeConfig="@xml/locales_config"',
    ):
        if required_fragment not in manifest:
            errors.append(f"manifest is missing {required_fragment}")

    adaptive = (
        ROOT / "android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml"
    ).read_text()
    if "<monochrome" not in adaptive:
        errors.append("Android 13 adaptive icon must provide a monochrome layer")

    source_svg = (ROOT / "store/assets/app-icon-source.svg").read_text().lower()
    if "<text" in source_svg:
        errors.append("store icon source must not contain text")

    icon_512 = ROOT / "store/assets/app-icon-512.png"
    if icon_512.is_file():
        try:
            if png_dimensions(icon_512) != (512, 512):
                errors.append("store icon PNG must be exactly 512x512 pixels")
        except ValueError as error:
            errors.append(str(error))

    if errors:
        print("Brand asset validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("Brand assets validated: launcher, adaptive, themed, splash, notification, and store icon.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
