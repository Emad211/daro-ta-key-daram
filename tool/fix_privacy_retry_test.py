from pathlib import Path

path = Path("test/features/privacy/presentation/privacy_center_widget_test.dart")
text = path.read_text()
old = """      notifications.failCancelAll = false;
      await tester.tap(find.byKey(const Key('retry-notification-cleanup')));
      await tester.pumpAndSettle();
"""
new = """      notifications.failCancelAll = false;
      final Finder retryCleanup = find.byKey(
        const Key('retry-notification-cleanup'),
      );
      await tester.scrollUntilVisible(
        retryCleanup,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(retryCleanup);
      await tester.pumpAndSettle();
"""
count = text.count(old)
if count != 1:
    raise SystemExit(f"Expected retry block once, found {count}")
path.write_text(text.replace(old, new))
