from pathlib import Path


def replace_once(path_string: str, old: str, new: str) -> None:
    path = Path(path_string)
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected block count 1, got {count}")
    path.write_text(text.replace(old, new))


replace_once(
    ".github/workflows/ci.yml",
    """          mkdir -p "$output/store/cafebazaar/fa-IR" "$output/store/myket/fa-IR" "$output/docs"
          cp store/cafebazaar/fa-IR/listing.md "$output/store/cafebazaar/fa-IR/"
          cp store/myket/fa-IR/listing.md "$output/store/myket/fa-IR/"
          cp docs/09-privacy-policy-fa.md "$output/docs/"
          cp docs/13-v1-release-candidate.md "$output/docs/"
          cp docs/14-release-rollback-and-incidents.md "$output/docs/"
          cp docs/15-permissions-and-data-safety.md "$output/docs/"
          cp docs/16-dependencies-and-licenses.md "$output/docs/"
          cp docs/17-support-faq-fa.md "$output/docs/"
          cp docs/18-terms-of-use-fa.md "$output/docs/"
""",
    """          mkdir -p \
            "$output/store/assets" \
            "$output/store/cafebazaar/fa-IR" \
            "$output/store/myket/fa-IR" \
            "$output/store/metadata/fa-IR" \
            "$output/store/release" \
            "$output/docs"
          cp store/assets/app-icon-source.svg "$output/store/assets/"
          cp store/assets/app-icon-512.png "$output/store/assets/"
          cp store/cafebazaar/fa-IR/listing.md "$output/store/cafebazaar/fa-IR/"
          cp store/myket/fa-IR/listing.md "$output/store/myket/fa-IR/"
          cp -R store/metadata/fa-IR/. "$output/store/metadata/fa-IR/"
          cp -R store/release/. "$output/store/release/"
          cp docs/09-privacy-policy-fa.md "$output/docs/"
          cp docs/13-v1-release-candidate.md "$output/docs/"
          cp docs/14-release-rollback-and-incidents.md "$output/docs/"
          cp docs/15-permissions-and-data-safety.md "$output/docs/"
          cp docs/16-dependencies-and-licenses.md "$output/docs/"
          cp docs/17-support-faq-fa.md "$output/docs/"
          cp docs/18-terms-of-use-fa.md "$output/docs/"
          cp docs/19-brand-and-store-assets.md "$output/docs/"
""",
)

replace_once(
    ".github/workflows/android-release.yml",
    """          فایل AAB قابل نصب مستقیم نیست و فقط برای بارگذاری در فروشگاه است.
          EOF

      - name: Upload signed Android internal release
""",
    """          فایل AAB قابل نصب مستقیم نیست و فقط برای بارگذاری در فروشگاه است.
          EOF

          mkdir -p \
            "$output/store/assets" \
            "$output/store/cafebazaar/fa-IR" \
            "$output/store/metadata/fa-IR" \
            "$output/store/release"
          cp store/assets/app-icon-source.svg "$output/store/assets/"
          cp store/assets/app-icon-512.png "$output/store/assets/"
          cp store/cafebazaar/fa-IR/listing.md "$output/store/cafebazaar/fa-IR/"
          cp -R store/metadata/fa-IR/. "$output/store/metadata/fa-IR/"
          cp -R store/release/. "$output/store/release/"

      - name: Upload signed Android internal release
""",
)
