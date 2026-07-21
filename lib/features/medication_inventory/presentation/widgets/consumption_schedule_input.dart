import 'package:flutter/material.dart';

import '../../../../core/input/localized_number_parser.dart';
import '../../domain/consumption_schedule.dart';
import '../../domain/consumption_schedule_formatter.dart';

class ConsumptionScheduleInput extends StatefulWidget {
  const ConsumptionScheduleInput({
    required this.initialSchedule,
    required this.onChanged,
    super.key,
  });

  final ConsumptionSchedule initialSchedule;
  final ValueChanged<ConsumptionSchedule?> onChanged;

  @override
  State<ConsumptionScheduleInput> createState() {
    return _ConsumptionScheduleInputState();
  }
}

class _ConsumptionScheduleInputState extends State<ConsumptionScheduleInput> {
  final GlobalKey<FormFieldState<Set<int>>> _weekdaysFieldKey =
      GlobalKey<FormFieldState<Set<int>>>();
  late final TextEditingController _amountController;
  late final TextEditingController _secondaryController;
  late ConsumptionScheduleKind _kind;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();
    final ConsumptionSchedule initial = widget.initialSchedule;
    _kind = initial.kind;
    _amountController = TextEditingController(
      text: ConsumptionScheduleFormatter.formatNumber(
        initial.amountPerOccurrence,
      ),
    );
    _secondaryController = TextEditingController(
      text: switch (initial) {
        DailyConsumptionSchedule(:final occurrencesPerDay) =>
          '$occurrencesPerDay',
        EveryNDaysConsumptionSchedule(:final intervalDays) => '$intervalDays',
        WeeklyConsumptionSchedule() => '1',
      },
    );
    _weekdays = switch (initial) {
      WeeklyConsumptionSchedule(:final weekdays) => weekdays.toSet(),
      _ => <int>{},
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'برنامه مصرف ثبت‌شده',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'فقط اطلاعات دستور پزشک یا داروساز را وارد کنید.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ConsumptionScheduleKind>(
              key: const Key('schedule-kind'),
              initialValue: _kind,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'نوع برنامه',
                prefixIcon: Icon(Icons.event_repeat_outlined),
              ),
              items: ConsumptionScheduleKind.values
                  .map(
                    (ConsumptionScheduleKind kind) =>
                        DropdownMenuItem<ConsumptionScheduleKind>(
                          value: kind,
                          child: Text(
                            kind.persianLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  )
                  .toList(growable: false),
              onChanged: (ConsumptionScheduleKind? value) {
                if (value == null || value == _kind) {
                  return;
                }
                setState(() {
                  _kind = value;
                  _secondaryController.text = switch (value) {
                    ConsumptionScheduleKind.daily => '1',
                    ConsumptionScheduleKind.everyNDays => '2',
                    ConsumptionScheduleKind.weekly => '1',
                  };
                  if (value != ConsumptionScheduleKind.weekly) {
                    _weekdays = <int>{};
                  }
                });
                _weekdaysFieldKey.currentState?.didChange(_weekdays);
                _emit();
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('schedule-amount'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'مقدار در هر نوبت',
                hintText: 'مثلاً ۰٫۵ یا ۱',
                prefixIcon: Icon(Icons.medication_outlined),
              ),
              onChanged: (String value) => _emit(),
              validator: (String? value) {
                final double? amount = LocalizedNumberParser.tryParseDouble(
                  value,
                );
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'عدد بزرگ‌تر از صفر وارد کنید.';
                }
                return null;
              },
            ),
            if (_kind == ConsumptionScheduleKind.daily) ...<Widget>[
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('schedule-occurrences-per-day'),
                controller: _secondaryController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'تعداد نوبت در روز',
                  prefixIcon: Icon(Icons.today_outlined),
                  suffixText: 'نوبت',
                ),
                onChanged: (String value) => _emit(),
                validator: (String? value) {
                  return _validateInteger(value, min: 1, max: 24);
                },
              ),
            ],
            if (_kind == ConsumptionScheduleKind.everyNDays) ...<Widget>[
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('schedule-interval-days'),
                controller: _secondaryController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'فاصله بین نوبت‌ها',
                  prefixIcon: Icon(Icons.date_range_outlined),
                  suffixText: 'روز',
                ),
                onChanged: (String value) => _emit(),
                validator: (String? value) {
                  return _validateInteger(value, min: 1, max: 365);
                },
              ),
            ],
            if (_kind == ConsumptionScheduleKind.weekly) ...<Widget>[
              const SizedBox(height: 16),
              FormField<Set<int>>(
                key: _weekdaysFieldKey,
                initialValue: _weekdays,
                validator: (Set<int>? value) {
                  if (_kind == ConsumptionScheduleKind.weekly &&
                      (value == null || value.isEmpty)) {
                    return 'حداقل یک روز هفته را انتخاب کنید.';
                  }
                  return null;
                },
                builder: (FormFieldState<Set<int>> field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'روزهای مصرف',
                      errorText: field.errorText,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _orderedWeekdays
                          .map((int weekday) {
                            final bool selected = _weekdays.contains(weekday);
                            return FilterChip(
                              key: Key('schedule-weekday-$weekday'),
                              label: Text(
                                ConsumptionScheduleFormatter.weekdayLabel(
                                  weekday,
                                ),
                              ),
                              selected: selected,
                              onSelected: (bool value) {
                                setState(() {
                                  if (value) {
                                    _weekdays.add(weekday);
                                  } else {
                                    _weekdays.remove(weekday);
                                  }
                                });
                                field.didChange(Set<int>.of(_weekdays));
                                _emit();
                              },
                            );
                          })
                          .toList(growable: false),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const List<int> _orderedWeekdays = <int>[
    DateTime.saturday,
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  String? _validateInteger(
    String? value, {
    required int min,
    required int max,
  }) {
    final int? number = int.tryParse(LocalizedNumberParser.normalize(value));
    if (number == null || number < min || number > max) {
      return 'عدد صحیح بین $min تا $max وارد کنید.';
    }
    return null;
  }

  void _emit() {
    final double? amount = LocalizedNumberParser.tryParseDouble(
      _amountController.text,
    );
    final int? secondary = int.tryParse(
      LocalizedNumberParser.normalize(_secondaryController.text),
    );
    if (amount == null || !amount.isFinite || amount <= 0) {
      widget.onChanged(null);
      return;
    }

    try {
      final ConsumptionSchedule schedule = switch (_kind) {
        ConsumptionScheduleKind.daily => DailyConsumptionSchedule(
          amountPerOccurrence: amount,
          occurrencesPerDay: secondary ?? 0,
        ),
        ConsumptionScheduleKind.everyNDays => EveryNDaysConsumptionSchedule(
          amountPerOccurrence: amount,
          intervalDays: secondary ?? 0,
        ),
        ConsumptionScheduleKind.weekly => WeeklyConsumptionSchedule(
          amountPerOccurrence: amount,
          weekdays: _weekdays,
        ),
      };
      widget.onChanged(schedule);
    } on ArgumentError {
      widget.onChanged(null);
    }
  }
}
