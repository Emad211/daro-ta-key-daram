from pathlib import Path

path = Path('.github/workflows/ci.yml')
text = path.read_text()
old = """          flutter build apk --release --target-platform=android-arm64 --analyze-size
          size_file=\"$(find build -maxdepth 2 -type f -name '*code-size-analysis*.json' | sort | tail -n 1)\"
          test -n \"$size_file\"
          cp \"$size_file\" \"$output/arm64-code-size-analysis.json\"
"""
new = """          flutter build apk --release --target-platform=android-arm64 --analyze-size
          size_file=\"$(
            find \"$HOME/.flutter-devtools\" build \\
              -type f -name '*code-size-analysis*.json' -printf '%T@ %p\\n' 2>/dev/null \\
              | sort -n | tail -n 1 | cut -d' ' -f2-
          )\"
          test -n \"$size_file\"
          cp \"$size_file\" \"$output/arm64-code-size-analysis.json\"
"""
count = text.count(old)
if count != 1:
    raise SystemExit(f'expected AOT size-analysis block once, found {count}')
path.write_text(text.replace(old, new))
