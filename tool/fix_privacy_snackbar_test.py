from pathlib import Path

path = Path("test/features/privacy/presentation/privacy_center_widget_test.dart")
text = path.read_text()
old = """      expect(notifications.cancelAllCalls, 2);
      expect(find.byKey(const Key('retry-notification-cleanup')), findsNothing);
      expect(find.text('اعلان‌های باقی‌مانده پاک شدند.'), findsOneWidget);
"""
new = """      expect(notifications.cancelAllCalls, 2);
      expect(find.byKey(const Key('retry-notification-cleanup')), findsNothing);
      expect(find.text('اطلاعات دارویی محلی حذف شده‌اند.'), findsOneWidget);
"""
count = text.count(old)
if count != 1:
    raise SystemExit(f"Expected snackbar assertion block once, found {count}")
path.write_text(text.replace(old, new))
