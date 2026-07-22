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
if "supportedLocales: const <Locale>[Locale('fa')]" not in app_dart:
    fail("release UI must advertise only the implemented Persian locale")
if "PersianMaterialLocalizations.delegate" not in app_dart:
    fail("Persian Material localization delegate is missing")
if "PersianCupertinoLocalizations.delegate" not in app_dart:
    fail("Persian Cupertino localization delegate is missing")

manifest_path = ROOT / "android/app/src/main/AndroidManifest.xml"
manifest = ET.parse(manifest_path).getroot()
application = manifest.find("application")
if application is None:
    fail("Android application element is missing")

required_attributes = {
    ANDROID + "allowBackup": "false",
    ANDROID + "fullBackupContent": "@xml/backup_rules",
    ANDROID + "dataExtractionRules": "@xml/data_extraction_rules",
    ANDROID + "usesCleartextTraffic": "false",
    ANDROID + "localeConfig": "@xml/locales_config",
    ANDROID + "supportsRtl": "true",
    ANDROID + "appCategory": "medical",
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
}
unexpected = sorted(source_permissions & forbidden_permissions)
if unexpected:
    fail("forbidden source permissions: " + ", ".join(unexpected))

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
if 'android:name="en"' in locales:
    fail("English locale is advertised without an English product translation")
if 'android:name="fa"' not in locales:
    fail("Persian locale is missing")

privacy = require_text("docs/09-privacy-policy-fa.md")
if "[تکمیل شود]" not in privacy:
    print("release-check: privacy draft has no standard placeholders; review manually")

required_store_files = (
    "store/metadata/fa-IR/title.txt",
    "store/metadata/fa-IR/short-description.txt",
    "store/metadata/fa-IR/full-description.txt",
    "store/metadata/fa-IR/release-notes-1.0.0.txt",
    "store/release/data-safety-fa.md",
    "store/release/asset-manifest.md",
    "store/release/publication-gates.md",
)
for resource in required_store_files:
    require_text(resource)

print("release-check: candidate static checks passed")
