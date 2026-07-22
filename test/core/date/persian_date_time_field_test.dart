import 'package:daro_ta_key_daram/core/date/persian_date_time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

void main() {
  testWidgets('renders a reachable Jalali value at text scale 2', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fa', 'IR'),
        supportedLocales: const <Locale>[Locale('fa', 'IR')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          PersianMaterialLocalizations.delegate,
          PersianCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PersianDateTimeField(
                  key: const Key('jalali-date-field'),
                  label: 'تاریخ و زمان موجودی',
                  value: DateTime(2025, 3, 21, 9, 5),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2026),
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('jalali-date-field')), findsOneWidget);
    expect(find.text('۱۴۰۴/۰۱/۰۱ • ۰۹:۰۵'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
