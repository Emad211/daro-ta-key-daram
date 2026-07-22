import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import 'persian_date_formatter.dart';

class PersianDateTimeField extends StatelessWidget {
  const PersianDateTimeField({
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.includeTime = true,
    this.helperText,
    super.key,
  });

  final String label;
  final DateTime value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final bool includeTime;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final String displayedValue = includeTime
        ? PersianDateFormatter.dateTime(value)
        : PersianDateFormatter.date(value);

    return Semantics(
      button: true,
      label: '$label، $displayedValue',
      hint: 'برای انتخاب تاریخ${includeTime ? ' و زمان' : ''} ضربه بزنید',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            suffixIcon: const Icon(Icons.edit_calendar_outlined),
          ),
          child: Text(
            displayedValue,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final DateTime boundedInitial = value.isBefore(firstDate)
        ? firstDate
        : value.isAfter(lastDate)
        ? lastDate
        : value;

    final Jalali? pickedDate = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime(boundedInitial.toLocal()),
      firstDate: Jalali.fromDateTime(firstDate.toLocal()),
      lastDate: Jalali.fromDateTime(lastDate.toLocal()),
    );
    if (pickedDate == null || !context.mounted) {
      return;
    }

    TimeOfDay selectedTime = TimeOfDay.fromDateTime(boundedInitial.toLocal());
    if (includeTime) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        builder: (BuildContext context, Widget? child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: true),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      );
      if (pickedTime == null || !context.mounted) {
        return;
      }
      selectedTime = pickedTime;
    }

    final Gregorian gregorian = pickedDate.toGregorian();
    final DateTime result = DateTime(
      gregorian.year,
      gregorian.month,
      gregorian.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (result.isBefore(firstDate) || result.isAfter(lastDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تاریخ و زمان انتخاب‌شده خارج از بازه مجاز است.'),
        ),
      );
      return;
    }

    onChanged(result);
  }
}
