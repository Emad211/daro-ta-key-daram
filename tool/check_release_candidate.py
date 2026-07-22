#!/usr/bin/env python3
"""Static release-candidate checks that do not require private signing material."""

from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID = "{http://schemas.android.com/apk/res/android}"


def fail(message: str) -> None:
    print(f"release-check: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_text(path: str) -> str:
    target = ROOT / path
    if not target.is_file():
        fail(f"required file is missing: {path}")
    return target.read_text(encoding="utf-8")


pubspec = require_text("pubspec.yaml")
version_match = re.search(r"^version:\s*([^\s]+)$", pubspec, re.MULTILINE)
if version_match is None:
    fail("pubspec version is missing")
if version_match.group(1) != "1.0.0+1":
    fail(f"candidate version must be 1.0.0+1, found {version_match.group(1)}")
if "persian_datetime_picker: 3.2.0" not in pubspec:
    fail("the audited Persian date picker must remain pinned to 3.2.0")

app_dart = require_text("lib/app/app.dart")
if "Locale('fa', 'IR')" not in app_dart:
    fail("the Persian Iran locale is missing")
if "Locale('en'" in app_dart:
    fail("English product locale is advertised without an English translation")
for delegate in (
    "PersianMaterialLocalizations.delegate",
    "PersianCupertinoLocalizations.delegate",
):
    if delegate not in app_dart:
        fail(f"localization delegate is missing: {delegate}")

manifest_path = ROOT / "android/app/src/main/AndroidManifest.xml"
manifest = ET.parse(manifest_path).getroot()
application = manifest.find("application")
if application is None:
    fail("Android application element is missing")

required_attributes = {
    ANDROID + "icon": "@mipmap/ic_launcher",
    ANDROID + "roundIcon": "@mipmap/ic_launcher_round",
    ANDROID + "localeConfig": "@xml/locales_config",
    ANDROID + "supportsRtl": "true",
    ANDROID + "allowBackup": "false",
    ANDROID + "fullBackupContent": "@xml/backup_rules",
    ANDROID + "dataExtractionRules": "@xml/data_extraction_rules",
    ANDROID + "usesCleartextTraffic": "false",
}
for key, expected in required_attributes.items():
    actual = application.get(key)
    if actual != expected:
        fail(f"Android application attribute {key} must be {expected}, found {actual}")

for resource in (
    "android/app/src/main/res/xml/backup_rules.xml",
    "android/app/src/main/res/xml/data_extraction_rules.xml",
    "android/app/src/main/res/xml/locales_config.xml",
):
    require_text(resource)

source_permissions = {
    node.get(ANDROID + "name")
    for node in manifest.findall("uses-permission")
    if node.get(ANDROID + "name")
}
forbidden_permissions = {
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.CAMERA",
    "android.permission.RECORD_AUDIO",
    "android.permission.READ_CONTACTS",
    "android.permission.WRITE_CONTACTS",
    "android.permission.READ_PHONE_STATE",
    "android.permission.READ_SMS",
    "android.permission.SEND_SMS",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.MANAGE_EXTERNAL_STORAGE",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.USE_EXACT_ALARM",
    "com.google.android.gms.permission.AD_ID",
}
unexpected = sorted(source_permissions & forbidden_permissions)
if unexpected:
    fail("forbidden source permissions: " + ", ".join(unexpected))

expected_permissions = {
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
}
if source_permissions != expected_permissions:
    fail(
        "source permission allowlist changed: "
        + ", ".join(sorted(source_permissions))
    )

gradle = require_text("android/app/build.gradle.kts")
for marker in (
    'applicationId = "ir.emadkarimi.darutakey"',
    "compileSdk = 36",
    "targetSdk = 36",
    "isMinifyEnabled = true",
    "isShrinkResources = true",
    'getDefaultProguardFile("proguard-android-optimize.txt")',
):
    if marker not in gradle:
        fail(f"Android release contract is missing: {marker}")
if 'signingConfigs.getByName("debug")' in gradle:
    fail("release must never fall back to debug signing")

locales = require_text("android/app/src/main/res/xml/locales_config.xml")
if 'android:name="fa-IR"' not in locales:
    fail("Persian Iran locale is missing from Android locale config")
if 'android:name="en' in locales:
    fail("English locale is advertised without an English product translation")

privacy = require_text("docs/09-privacy-policy-fa.md")
if "[تکمیل شود]" not in privacy:
    print("release-check: privacy draft has no standard placeholders; review manually")

required_store_files = (
    "store/assets/app-icon-source.svg",
    "store/assets/app-icon-512.png",
    "store/metadata/fa-IR/title.txt",
    "store/metadata/fa-IR/short-description.txt",
    "store/metadata/fa-IR/full-description.txt",
    "store/metadata/fa-IR/release-notes-1.0.0.txt",
    "store/release/data-safety-fa.md",
    "store/release/asset-manifest.md",
    "store/release/publication-gates.md",
)
for resource in required_store_files:
    if not (ROOT / resource).is_file():
        fail(f"required store resource is missing: {resource}")

print("release-check: candidate static checks passed")
