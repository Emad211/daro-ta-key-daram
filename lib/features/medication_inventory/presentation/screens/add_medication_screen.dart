import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/medication_repository.dart';
import '../../domain/medication.dart';
import '../../domain/medication_unit.dart';
import '../providers/medication_providers.dart';

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
  final TextEditingController _dailyUseController = TextEditingController();
  final TextEditingController _alertDaysController = TextEditingController(
    text: '5',
  );
  final TextEditingController _notesController = TextEditingController();

  MedicationUnit _selectedUnit = MedicationUnit.tablet;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _dailyUseController.dispose();
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
              _DisclaimerCard(),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'نام دارو',
                  hintText: 'مثلاً متفورمین',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'نام دارو را وارد کنید.';
                  }
                  if (value.trim().length > 80) {
                    return 'نام دارو بیش از حد طولانی است.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<MedicationUnit>(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'موجودی فعلی',
                        hintText: '۳۰',
                      ),
                      validator: _positiveOrZeroValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dailyUseController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'مصرف در روز',
                        hintText: '۲',
                      ),
                      validator: _strictlyPositiveValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _alertDaysController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'چند روز قبل هشدار بدهم؟',
                  prefixIcon: Icon(Icons.notifications_outlined),
                  suffixText: 'روز',
                ),
                validator: (String? value) {
                  final int? number = int.tryParse(_normalizeNumber(value));
                  if (number == null || number < 0 || number > 365) {
                    return 'عدد صحیح بین صفر تا ۳۶۵ وارد کنید.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
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

  String? _positiveOrZeroValidator(String? value) {
    final double? number = double.tryParse(_normalizeNumber(value));
    if (number == null || !number.isFinite || number < 0) {
      return 'عدد نامنفی وارد کنید.';
    }
    return null;
  }

  String? _strictlyPositiveValidator(String? value) {
    final double? number = double.tryParse(_normalizeNumber(value));
    if (number == null || !number.isFinite || number <= 0) {
      return 'عدد بزرگ‌تر از صفر وارد کنید.';
    }
    return null;
  }

  String _normalizeNumber(String? value) {
    const String persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const String arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    String normalized = (value ?? '').trim().replaceAll(',', '.');

    for (int index = 0; index < 10; index += 1) {
      normalized = normalized
          .replaceAll(persianDigits[index], '$index')
          .replaceAll(arabicDigits[index], '$index');
    }
    return normalized;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final DateTime now = ref.read(clockProvider)();
      final Medication medication = Medication(
        id: now.microsecondsSinceEpoch.toString(),
        name: _nameController.text,
        unit: _selectedUnit,
        stockAtRecord: double.parse(_normalizeNumber(_stockController.text)),
        unitsPerDay: double.parse(
          _normalizeNumber(_dailyUseController.text),
        ),
        inventoryRecordedAt: now,
        alertLeadDays: int.parse(_normalizeNumber(_alertDaysController.text)),
        notes: _notesController.text,
      );

      final MedicationRepository repository = ref.read(
        medicationRepositoryProvider,
      );
      await repository.upsert(medication);
      ref.invalidate(activeMedicationsProvider);

      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دارو با موفقیت ثبت شد.')),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ذخیره دارو انجام نشد. دوباره تلاش کنید.'),
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
                'مقدار مصرف را دقیقاً مطابق دستور پزشک یا داروساز وارد کنید. '
                'این برنامه دوز مصرف را پیشنهاد یا تغییر نمی‌دهد.',
                style: TextStyle(height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
