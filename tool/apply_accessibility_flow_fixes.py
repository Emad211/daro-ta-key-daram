from pathlib import Path


def replace_once(path_string: str, old: str, new: str) -> None:
    path = Path(path_string)
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected block count 1, got {count}")
    path.write_text(text.replace(old, new))


sheet_path = (
    "lib/features/medication_inventory/presentation/widgets/"
    "inventory_event_form_sheet.dart"
)
replace_once(
    sheet_path,
    """          child: SingleChildScrollView(
            child: Column(
""",
    """          child: SingleChildScrollView(
            key: const Key('inventory-event-scroll'),
            child: Column(
""",
)
replace_once(
    sheet_path,
    """          builder: (BuildContext context) => AlertDialog(
            title: Text('بازبینی ${widget.type.persianLabel}'),
""",
    """          builder: (BuildContext context) => AlertDialog(
            scrollable: true,
            title: Text('بازبینی ${widget.type.persianLabel}'),
""",
)

test_path = Path(
    "test/features/medication_inventory/presentation/"
    "accessibility_rtl_widget_test.dart"
)
text = test_path.read_text()
text = text.replace(
    """      final SemanticsHandle semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

""",
    """      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
""",
    1,
)
start = text.index("      try {\n") + len("      try {\n")
end_marker = "    });\n"
end = text.index(end_marker, start)
body = text[start:end]
if "_expectNoFlutterExceptions(tester, 'archive at scale $textScale');" not in body:
    raise SystemExit("Accessibility test body end marker was not found")
indented_body = "".join(
    f"  {line}" if line.strip() else line
    for line in body.splitlines(keepends=True)
)
text = (
    text[:start]
    + indented_body
    + "      } finally {\n"
    + "        semantics.dispose();\n"
    + "      }\n"
    + text[end:]
)
text = text.replace(
    """      await _scrollTo(tester, review, scrollable: find.byType(Scrollable).last);
""",
    """      await _scrollTo(
        tester,
        review,
        scrollable: find.byKey(const Key('inventory-event-scroll')),
      );
""",
    1,
)
test_path.write_text(text)
