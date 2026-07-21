import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/input/localized_number_parser.dart';
import '../../application/medication_repository.dart';
import '../../domain/consumption_schedule.dart';
import '../../domain/medication.dart';
import '../../domain/medication_unit.dart';
import '../medication_command_failure_message.dart';
import '../providers/medication_providers.dart';
import '../widgets/consumption_schedule_input.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() {
    return _AddMedicationScreenState();
  }
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _alertDaysController = TextEditingController(
    text: '5',
  );
  final TextEditingController _notesController = TextEditingController();

  MedicationUnit _selectedUnit = MedicationUnit.tablet;
  ConsumptionSchedule? _consumptionSchedule = DailyConsumptionSchedule(
    amountPerOccurrence: 1,
    occurrencesPerDay: 1,
  );
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _alertDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('افزودن دارو')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const _DisclaimerCard(),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('add-medication-name'),
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'نام دارو',
                  hintText: 'مثلاً متفورمین',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (String? value) {
                  final String normalized = value?.trim() ?? '';
                  if (normalized.isEmpty) {
                    return 'نام دارو را وارد کنید.';
                  }
                  if (normalized.length > 80) {
                    return 'نام دارو بیش از حد طولانی است.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<MedicationUnit>(
                key: const Key('add-medication-unit'),
                initialValue: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'واحد موجودی',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: MedicationUnit.values
                    .map(
                      (MedicationUnit unit) => DropdownMenuItem<MedicationUnit>(
                        value: unit,
                        child: Text(unit.persianLabel),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (MedicationUnit? value) {
                  if (value != null) {
                    setState(() => _selectedUnit = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('add-medication-stock'),
                controller: _stockController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'موجودی فعلی',
                  hintText: '۳۰',
                  suffixText: _selectedUnit.persianLabel,
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
                validator: (String? value) {
                  final double? number = LocalizedNumberParser.tryParseDouble(
                    value,
                  );
                  if (number == null || !number.isFinite || number < 0) {
                    return 'عدد نامنفی وارد کنید.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              ConsumptionScheduleInput(
                initialSchedule: _consumptionSchedule!,
                onChanged: (ConsumptionSchedule? value) {
                  _consumptionSchedule = value;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('add-medication-alert-days'),
                controller: _alertDaysController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'چند روز قبل هشدار بدهم؟',
                  prefixIcon: Icon(Icons.notifications_outlined),
                  suffixText: 'روز',
                ),
                validator: (String? value) {
                  final int? number = int.tryParse(
                    LocalizedNumberParser.normalize(value),
                  );
                  if (number == null || number < 0 || number > 365) {
                    return 'عدد صحیح بین صفر تا ۳۶۵ وارد کنید.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('add-medication-notes'),
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'توضیح اختیاری',
                  hintText: 'مثلاً داروی داخل کشوی دوم',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('save-new-medication'),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSaving ? 'در حال ذخیره...' : 'ذخیره دارو'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false) ||
        _consumptionSchedule == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final DateTime now = ref.read(clockProvider)();
      final Medication medication = Medication(
        id: now.microsecondsSinceEpoch.toString(),
        name: _nameController.text,
        unit: _selectedUnit,
        stockAtRecord: LocalizedNumberParser.tryParseDouble(
          _stockController.text,
        )!,
        consumptionSchedule: _consumptionSchedule,
        inventoryRecordedAt: now,
        alertLeadDays: int.parse(
          LocalizedNumberParser.normalize(_alertDaysController.text),
        ),
        notes: _notesController.text,
      );

      final MedicationRepository repository = ref.read(
        medicationRepositoryProvider,
      );
      await repository.create(medication);
      ref.invalidate(activeMedicationsProvider);

      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('دارو با موفقیت ثبت شد.')));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              MedicationCommandFailureMessage.resolve(
                error,
                fallback: 'ذخیره دارو انجام نشد. دوباره تلاش کنید.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'برنامه مصرف را دقیقاً مطابق دستور پزشک یا داروساز وارد کنید. '
                'این برنامه مقدار یا زمان مصرف را پیشنهاد یا تغییر نمی‌دهد.',
                style: TextStyle(height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
