import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../domain/medication.dart';
import '../medication_command_failure_message.dart';
import '../providers/medication_providers.dart';

class ArchivedMedicationsScreen extends ConsumerStatefulWidget {
  const ArchivedMedicationsScreen({super.key});

  @override
  ConsumerState<ArchivedMedicationsScreen> createState() {
    return _ArchivedMedicationsScreenState();
  }
}

class _ArchivedMedicationsScreenState
    extends ConsumerState<ArchivedMedicationsScreen> {
  final Set<String> _confirmingMedicationIds = <String>{};
  final Set<String> _savingMedicationIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Medication>> medications = ref.watch(
      archivedMedicationsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('داروهای آرشیوشده')),
      body: medications.when(
        data: (List<Medication> items) {
          if (items.isEmpty) {
            return EmptyState(
              title: 'آرشیو خالی است',
              message:
                  'داروهایی که موقتاً از فهرست فعال کنار می‌گذارید، همراه '
                  'تاریخچه‌شان در این بخش می‌مانند.',
              actionLabel: 'بازگشت',
              onAction: () => Navigator.of(context).maybePop(),
            );
          }

          final List<Medication> sorted = <Medication>[...items]
            ..sort(
              (Medication first, Medication second) =>
                  first.name.compareTo(second.name),
            );
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: sorted.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final Medication medication = sorted[index];
              return _ArchivedMedicationCard(
                medication: medication,
                isBusy: _isBusy(medication.id),
                showProgress: _savingMedicationIds.contains(medication.id),
                onRestore: () {
                  unawaited(_restore(medication));
                },
                onDelete: () {
                  unawaited(_delete(medication));
                },
              );
            },
          );
        },
        error: (Object error, StackTrace stackTrace) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(archivedMedicationsProvider),
            child: const Text('تلاش دوباره'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  bool _isBusy(String medicationId) {
    return _confirmingMedicationIds.contains(medicationId) ||
        _savingMedicationIds.contains(medicationId);
  }

  Future<void> _restore(Medication medication) async {
    if (_isBusy(medication.id)) {
      return;
    }
    setState(() => _savingMedicationIds.add(medication.id));

    try {
      await ref.read(medicationRepositoryProvider).restore(medication.id);
      _invalidate(medication.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${medication.name} به فهرست فعال برگشت.')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              MedicationCommandFailureMessage.resolve(
                error,
                fallback: 'بازیابی دارو انجام نشد. دوباره تلاش کنید.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingMedicationIds.remove(medication.id));
      }
    }
  }

  Future<void> _delete(Medication medication) async {
    if (_isBusy(medication.id)) {
      return;
    }
    setState(() => _confirmingMedicationIds.add(medication.id));

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('حذف دائمی دارو؟'),
            content: Text(
              'تمام اطلاعات و تاریخچه ${medication.name} برای همیشه حذف '
              'می‌شود. این عملیات قابل بازگشت نیست.',
            ),
            actions: <Widget>[
              TextButton(
                key: Key('cancel-delete-${medication.id}'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                key: Key('confirm-delete-${medication.id}'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('حذف دائمی'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) {
      return;
    }
    setState(() => _confirmingMedicationIds.remove(medication.id));
    if (!confirmed) {
      return;
    }
    setState(() => _savingMedicationIds.add(medication.id));

    try {
      await ref
          .read(medicationRepositoryProvider)
          .deletePermanently(medication.id);
      _invalidate(medication.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دارو و تاریخچه آن حذف شد.')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              MedicationCommandFailureMessage.resolve(
                error,
                fallback: 'حذف دائمی انجام نشد. دوباره تلاش کنید.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingMedicationIds.remove(medication.id));
      }
    }
  }

  void _invalidate(String medicationId) {
    ref.invalidate(activeMedicationsProvider);
    ref.invalidate(archivedMedicationsProvider);
    ref.invalidate(medicationByIdProvider(medicationId));
    ref.invalidate(inventoryEventsProvider(medicationId));
  }
}

class _ArchivedMedicationCard extends StatelessWidget {
  const _ArchivedMedicationCard({
    required this.medication,
    required this.isBusy,
    required this.showProgress,
    required this.onRestore,
    required this.onDelete,
  });

  final Medication medication;
  final bool isBusy;
  final bool showProgress;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.archive_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    medication.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'آخرین مبنای موجودی: ${_number(medication.stockAtRecord)} '
              '${medication.unit.persianLabel}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonalIcon(
                    key: Key('restore-${medication.id}'),
                    onPressed: isBusy ? null : onRestore,
                    icon: showProgress
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.unarchive_outlined),
                    label: Text(showProgress ? 'در حال انجام...' : 'بازیابی'),
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  container: true,
                  label: 'حذف دائمی',
                  button: true,
                  enabled: !isBusy,
                  onTap: isBusy ? null : onDelete,
                  excludeSemantics: true,
                  child: IconButton.filledTonal(
                    key: Key('delete-${medication.id}'),
                    tooltip: 'حذف دائمی',
                    onPressed: isBusy ? null : onDelete,
                    icon: const Icon(Icons.delete_forever_outlined),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
}
