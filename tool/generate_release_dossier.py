#!/usr/bin/env python3
"""Generate a privacy-safe Android release-candidate dossier.

The script inspects only build metadata, the merged Android manifest, dependency
metadata, and package license files. It never reads the application database or
user content.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import unquote, urlparse

ANDROID_NS = "http://schemas.android.com/apk/res/android"
ANDROID = f"{{{ANDROID_NS}}}"
EXPECTED_APPLICATION_ID = "ir.emadkarimi.darutakey"
EXPECTED_PERMISSIONS = {
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
}
FORBIDDEN_PERMISSIONS = {
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_BACKGROUND_LOCATION",
    "android.permission.READ_CONTACTS",
    "android.permission.WRITE_CONTACTS",
    "android.permission.READ_CALENDAR",
    "android.permission.WRITE_CALENDAR",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.MANAGE_EXTERNAL_STORAGE",
    "android.permission.CAMERA",
    "android.permission.RECORD_AUDIO",
    "android.permission.READ_PHONE_STATE",
    "android.permission.READ_PHONE_NUMBERS",
    "android.permission.GET_ACCOUNTS",
    "android.permission.QUERY_ALL_PACKAGES",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.USE_EXACT_ALARM",
    "com.google.android.gms.permission.AD_ID",
}
COMPONENT_TAGS = ("activity", "activity-alias", "service", "receiver", "provider")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--manifest-root", type=Path, required=True)
    parser.add_argument("--package-config", type=Path, required=True)
    parser.add_argument("--dependencies-json", type=Path, required=True)
    return parser.parse_args()


def read_pubspec_version(pubspec: Path) -> tuple[str, int]:
    match = re.search(r"^version:\s*([^+\s]+)\+(\d+)\s*$", pubspec.read_text(), re.MULTILINE)
    if match is None:
        raise RuntimeError("pubspec.yaml must contain version: <name>+<positive code>.")
    version_name = match.group(1)
    version_code = int(match.group(2))
    if version_code < 1:
        raise RuntimeError("Android version code must be positive.")
    return version_name, version_code


def choose_merged_manifest(root: Path) -> Path:
    candidates: list[Path] = []
    for path in root.rglob("AndroidManifest.xml"):
        lowered = str(path).lower()
        if "release" not in lowered:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if "<application" in text and "ir.emadkarimi.darutakey" in text:
            candidates.append(path)
    if not candidates:
        raise RuntimeError(f"No merged release manifest found under {root}.")

    def score(path: Path) -> tuple[int, int]:
        lowered = str(path).lower()
        priority = 0
        if "merged_manifests" in lowered:
            priority = 4
        elif "merged_manifest" in lowered:
            priority = 3
        elif "packaged_manifests" in lowered:
            priority = 2
        elif "intermediates" in lowered:
            priority = 1
        return priority, path.stat().st_size

    return max(candidates, key=score)


def bool_attr(element: ET.Element, name: str) -> str | None:
    return element.attrib.get(f"{ANDROID}{name}")


def component_rows(application: ET.Element) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for tag in COMPONENT_TAGS:
        for component in application.findall(tag):
            rows.append(
                {
                    "type": tag,
                    "name": component.attrib.get(f"{ANDROID}name", ""),
                    "exported": component.attrib.get(f"{ANDROID}exported", "unspecified"),
                    "permission": component.attrib.get(f"{ANDROID}permission", ""),
                }
            )
    return sorted(rows, key=lambda row: (row["type"], row["name"]))


def validate_manifest(tree: ET.ElementTree) -> tuple[list[str], list[dict[str, str]]]:
    root = tree.getroot()
    package_name = root.attrib.get("package")
    if package_name != EXPECTED_APPLICATION_ID:
        raise RuntimeError(
            f"Merged manifest package is {package_name!r}, expected {EXPECTED_APPLICATION_ID!r}."
        )
    application = root.find("application")
    if application is None:
        raise RuntimeError("Merged manifest has no <application> element.")

    expected_attrs = {
        "allowBackup": "false",
        "usesCleartextTraffic": "false",
        "dataExtractionRules": "@xml/data_extraction_rules",
        "networkSecurityConfig": "@xml/network_security_config",
    }
    for name, expected in expected_attrs.items():
        actual = bool_attr(application, name)
        if actual != expected:
            raise RuntimeError(
                f"Application attribute android:{name} is {actual!r}, expected {expected!r}."
            )

    permissions = sorted(
        {
            node.attrib.get(f"{ANDROID}name", "")
            for node in root.findall("uses-permission")
            if node.attrib.get(f"{ANDROID}name")
        }
    )
    forbidden = sorted(set(permissions) & FORBIDDEN_PERMISSIONS)
    if forbidden:
        raise RuntimeError(f"Forbidden release permissions present: {', '.join(forbidden)}")
    missing = sorted(EXPECTED_PERMISSIONS - set(permissions))
    if missing:
        raise RuntimeError(f"Required release permissions missing: {', '.join(missing)}")

    components = component_rows(application)
    exported = [row for row in components if row["exported"] == "true"]
    unexpected_exported = [
        row for row in exported if not row["name"].endswith(".MainActivity")
    ]
    if unexpected_exported:
        names = ", ".join(row["name"] for row in unexpected_exported)
        raise RuntimeError(f"Unexpected exported Android components: {names}")
    return permissions, components


def resolve_package_root(config_path: Path, root_uri: str) -> Path:
    parsed = urlparse(root_uri)
    if parsed.scheme == "file":
        return Path(unquote(parsed.path)).resolve()
    if parsed.scheme:
        raise RuntimeError(f"Unsupported package root URI scheme: {root_uri}")
    return (config_path.parent / unquote(root_uri)).resolve()


def package_license(root: Path) -> Path | None:
    candidates = [
        path
        for path in root.iterdir()
        if path.is_file()
        and path.name.lower()
        in {"license", "license.md", "license.txt", "copying", "copying.md", "copying.txt"}
    ]
    return sorted(candidates, key=lambda path: path.name.lower())[0] if candidates else None


def generate_notices(
    package_config_path: Path,
    dependencies_path: Path,
    output: Path,
    root_package: str,
) -> tuple[int, list[str]]:
    package_config = json.loads(package_config_path.read_text())
    dependencies = json.loads(dependencies_path.read_text())
    dependency_rows = {
        row.get("name"): row
        for row in dependencies.get("packages", [])
        if isinstance(row, dict) and row.get("name")
    }

    notices: list[str] = [
        "THIRD-PARTY SOFTWARE NOTICES",
        "Generated from the exact Flutter package configuration used for this build.",
        "",
    ]
    inventory: list[str] = [
        "# Dependency inventory",
        "",
        "| Package | Version | Kind | Source | License file |",
        "|---|---:|---|---|---|",
    ]
    missing_hosted: list[str] = []
    hosted_count = 0

    for package in sorted(package_config.get("packages", []), key=lambda row: row["name"]):
        name = package["name"]
        if name == root_package:
            continue
        metadata = dependency_rows.get(name, {})
        source = str(metadata.get("source", "unknown"))
        kind = str(metadata.get("kind", "transitive"))
        version = str(metadata.get("version", "sdk" if source == "sdk" else "unknown"))
        root = resolve_package_root(package_config_path, package["rootUri"])
        license_path = package_license(root)

        inventory.append(
            f"| `{name}` | `{version}` | {kind} | {source} | "
            f"{license_path.name if license_path else 'not found'} |"
        )
        if source == "sdk":
            continue
        if license_path is None:
            missing_hosted.append(name)
            continue
        hosted_count += 1
        notices.extend(
            [
                "=" * 80,
                f"PACKAGE: {name}",
                f"VERSION: {version}",
                f"LICENSE FILE: {license_path.name}",
                "=" * 80,
                license_path.read_text(encoding="utf-8", errors="replace").rstrip(),
                "",
            ]
        )

    (output / "DEPENDENCY-INVENTORY.md").write_text("\n".join(inventory) + "\n")
    (output / "THIRD-PARTY-NOTICES.txt").write_text("\n".join(notices) + "\n")
    if missing_hosted:
        raise RuntimeError(
            "Hosted/path packages missing a top-level license file: "
            + ", ".join(sorted(missing_hosted))
        )
    return hosted_count, inventory


def write_manifest_inventory(
    output: Path,
    source_manifest: Path,
    permissions: list[str],
    components: list[dict[str, str]],
) -> None:
    shutil.copy2(source_manifest, output / "MERGED-ANDROID-MANIFEST.xml")
    lines = [
        "# Android release manifest inventory",
        "",
        "## Declared permissions",
        "",
    ]
    lines.extend(f"- `{permission}`" for permission in permissions)
    lines.extend(
        [
            "",
            "The release intentionally contains no Internet, advertising-ID, exact-alarm, "
            "location, contacts, calendar, broad storage, camera, microphone, phone, "
            "account, or broad package-query permission.",
            "",
            "## Components",
            "",
            "| Type | Name | Exported | Permission |",
            "|---|---|---:|---|",
        ]
    )
    for row in components:
        lines.append(
            f"| {row['type']} | `{row['name']}` | {row['exported']} | "
            f"`{row['permission'] or '-'} ` |"
        )
    (output / "ANDROID-MANIFEST-INVENTORY.md").write_text("\n".join(lines) + "\n")


def write_data_safety_baseline(output: Path, version_name: str, version_code: int) -> None:
    content = f"""# مبنای افشای داده نسخه {version_name} ({version_code})

این فایل یک برگهٔ فنی برای تکمیل فرم فروشگاه است و جایگزین بررسی حقوقی ناشر نیست.

## رفتار واقعی این build

- اطلاعات دارویی، برنامه مصرف، موجودی، یادداشت و تاریخچه داخل پایگاه داده محلی برنامه نگهداری می‌شوند.
- حساب کاربری، همگام‌سازی ابری، backup خودکار برنامه، analytics، crash-reporting شبکه‌ای و SDK تبلیغاتی فعال وجود ندارد.
- build انتشار مجوز `INTERNET` و `AD_ID` ندارد و cleartext traffic را صریحاً رد می‌کند.
- برنامه فقط مجوز اعلان Android 13+ و دریافت رویداد تکمیل boot/update را اعلام می‌کند.
- درخواست مجوز اعلان فقط پس از اقدام آگاهانه کاربر انجام می‌شود.
- حذف همه اطلاعات دارویی از داخل privacy center وجود دارد و اعلان‌های برنامه نیز پاک می‌شوند.
- Auto Backup، cloud backup و device-to-device transfer برای داده برنامه در manifest/rules غیرفعال شده‌اند.

## پاسخ پایهٔ پیشنهادی فروشگاه

- انتقال دادهٔ کاربر به سرور ناشر یا شخص ثالث: **خیر** در این build.
- اشتراک‌گذاری داده با SDK تبلیغ/تحلیل: **خیر** در این build.
- دادهٔ سلامت واردشده توسط کاربر: **فقط پردازش و ذخیره محلی روی دستگاه**.
- رمزگذاری انتقال: موضوعیت ندارد؛ build شبکه ندارد.
- امکان حذف: بله، حذف موردی و حذف همهٔ اطلاعات دارویی داخل برنامه.

پیش از submission، ناشر باید این متن را با manifest ادغام‌شده، dependency inventory، سیاست حریم خصوصی عمومی و هر SDK یا سرویس فعال دوباره تطبیق دهد.
"""
    (output / "DATA-SAFETY-BASELINE-FA.md").write_text(content)


def write_status(
    output: Path,
    version_name: str,
    version_code: int,
    hosted_license_count: int,
) -> None:
    content = f"""# Android v{version_name} release-candidate dossier

- Version name: `{version_name}`
- Version code: `{version_code}`
- Application ID: `{EXPECTED_APPLICATION_ID}`
- Advertising SDK enabled: **no**
- Network permission enabled: **no**
- Hosted/path package license texts included: **{hosted_license_count}**

## Automated gates represented by this artifact

- Drift generation and committed schema parity
- canonical Dart formatting and Flutter analyzer
- complete unit/widget regression suite
- Jalali conversion/input and large-text RTL tests
- notification/privacy race regression
- release signing guard and APK/AAB signature verification
- universal and arm64 size budgets
- hardened backup, cleartext, permission, and exported-component checks
- dependency and third-party license inventory

## Publisher/device actions still required

- create and protect the permanent upload keystore and configure repository secrets;
- supply legal publisher name, support/privacy email, and public HTTPS privacy-policy URL;
- capture final screenshots from the permanently signed build;
- complete physical-device notification, TalkBack, largest-text, clean-install, and same-key upgrade tests;
- create Cafe Bazaar/Myket app records, complete declarations, and submit through their consoles.

The disposable CI signer proves build integrity only and must not be used to establish public update continuity.
"""
    (output / "RELEASE-CANDIDATE-STATUS.md").write_text(content)


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)

    version_name, version_code = read_pubspec_version(repo_root / "pubspec.yaml")
    if version_name != "1.0.0" or version_code != 1:
        raise RuntimeError(
            f"Release candidate must be 1.0.0+1, found {version_name}+{version_code}."
        )

    manifest = choose_merged_manifest(args.manifest_root.resolve())
    tree = ET.parse(manifest)
    permissions, components = validate_manifest(tree)
    write_manifest_inventory(output, manifest, permissions, components)

    hosted_count, _ = generate_notices(
        args.package_config.resolve(),
        args.dependencies_json.resolve(),
        output,
        root_package="daro_ta_key_daram",
    )
    write_data_safety_baseline(output, version_name, version_code)
    write_status(output, version_name, version_code, hosted_count)

    shutil.copy2(repo_root / "pubspec.yaml", output / "pubspec.yaml")
    shutil.copy2(repo_root / "pubspec.lock", output / "pubspec.lock")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:  # noqa: BLE001 - release tooling must report all failures.
        print(f"release dossier generation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
