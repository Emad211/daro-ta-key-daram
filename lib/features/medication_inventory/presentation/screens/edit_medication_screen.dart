import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/input/localized_number_parser.dart';
import '../../application/medication_details_update.dart';
import '../../application/medication_repository.dart';
import '../../domain/consumption_schedule.dart';
import '../../domain/consumption_schedule_formatter.dart';
import '../../domain/medication.dart';
import '../../domain/medication_unit.dart';
import '../providers/medication_providers.dart';
import '../widgets/consumption_schedule_input.dart';

class EditMedicationScreen extends ConsumerWidget {
  const EditMedicationScreen({required this.medicationId, super.key});

  final String medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Medication?> medication = ref.watch(
      medicationByIdProvider(medicationId),
    );

    return medication.when(
      data: (Medication? value) {
        if (value == null) {
          return _NotFound(onBack: () => context.go('/'));
        }
        return _EditMedicationForm(medication: value);
      },
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('ویرایش مشخصات دارو')),
        body: Center(
          child: FilledButton(
            onPressed: () =>
                ref.invalidate(medicationByIdProvider(medicationId)),
            child: const Text('تلاش دوباره'),
          ),
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('ویرایش مشخصات دارو')),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EditMedicationForm extends ConsumerStatefulWidget {
  const _EditMedicationForm({required this.medication});

  final Medication medication;

  @override
  ConsumerState<_EditMedicationForm> createState() {
    return _EditMedicationFormState();
  }
}

class _EditMedicationFormState extends ConsumerState<_EditMedicationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _alertDaysController;
  late final TextEditingController _notesController;
  late MedicationUnit _selectedUnit;
  late ConsumptionSchedule? _consumptionSchedule;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication.name);
    _alertDaysController = TextEditingController(
      text: '${widget.medication.alertLeadDays}',
    );
    _notesController = TextEditingController(text: widget.medication.notes);
    _selectedUnit = widget.medication.unit;
    _consumptionSchedule = widget.medication.consumptionSchedule;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _alertDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش مشخصات دارو')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const _SafetyNotice(),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('edit-medication-name'),
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'نام دارو',
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
                key: const Key('edit-medication-unit'),
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
              ConsumptionScheduleInput(
                initialSchedule: widget.medication.consumptionSchedule,
                onChanged: (ConsumptionSchedule? value) {
                  _consumptionSchedule = value;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('edit-medication-alert-days'),
                controller: _alertDaysController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'فاصله هشدار قبل از اتمام',
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
                key: const Key('edit-medication-notes'),
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'توضیح اختیاری',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('save-medication-metadata'),
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSaving ? 'در حال ذخیره...' : 'ذخیره تغییرات'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _consumptionSchedule == null) {
      return;
    }

    final ConsumptionSchedule schedule = _consumptionSchedule!;
    if (schedule != widget.medication.consumptionSchedule) {
      final bool confirmed = await _confirmScheduleChange(schedule);
      if (!confirmed || !mounted) {
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final MedicationDetailsUpdate update = MedicationDetailsUpdate(
        medicationId: widget.medication.id,
        name: _nameController.text,
        unit: _selectedUnit,
        consumptionSchedule: schedule,
        alertLeadDays: int.parse(
          LocalizedNumberParser.normalize(_alertDaysController.text),
        ),
        notes: _notesController.text,
      );
      final MedicationRepository repository = ref.read(
        medicationRepositoryProvider,
      );
      await repository.updateDetails(update);
      ref.invalidate(activeMedicationsProvider);
      ref.invalidate(archivedMedicationsProvider);
      ref.invalidate(medicationByIdProvider(update.medicationId));
      ref.invalidate(inventoryEventsProvider(update.medicationId));

      if (mounted) {
        context.goNamed(
          'medication-details',
          pathParameters: <String, String>{'medicationId': update.medicationId},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              schedule == widget.medication.consumptionSchedule
                  ? 'مشخصات دارو به‌روزرسانی شد.'
                  : 'برنامه مصرف ثبت شد و موجودی فعلی مبنای جدید قرار گرفت.',
            ),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ذخیره تغییرات انجام نشد.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _confirmScheduleChange(ConsumptionSchedule schedule) async {
    final String previous = ConsumptionScheduleFormatter.describe(
      widget.medication.consumptionSchedule,
      widget.medication.unit,
    );
    final String next = ConsumptionScheduleFormatter.describe(
      schedule,
      _selectedUnit,
    );

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('تغییر برنامه مصرف؟'),
            content: Text(
              'برنامه قبلی:\n$previous\n\nبرنامه جدید:\n$next\n\n'
              'برای جلوگیری از بازنویسی گذشته، موجودی تخمینی فعلی در همین '
              'لحظه به‌عنوان مبنای جدید ثبت می‌شود.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                key: const Key('confirm-schedule-change'),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('تأیید تغییر'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.health_and_safety_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'برنامه مصرف را فقط زمانی تغییر دهید که دستور پزشک یا داروساز '
                'تغییر کرده باشد. برنامه هیچ پیشنهادی درباره مقدار یا زمان '
                'مصرف ارائه نمی‌دهد.',
                style: TextStyle(height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش مشخصات دارو')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.search_off_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('این دارو پیدا نشد.'),
              const SizedBox(height: 16),
              FilledButton(onPressed: onBack, child: const Text('بازگشت')),
            ],
          ),
        ),
      ),
    );
  }
}
