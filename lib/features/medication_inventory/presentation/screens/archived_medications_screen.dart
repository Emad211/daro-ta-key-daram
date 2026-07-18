import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../application/medication_repository.dart';
import '../../domain/medication.dart';
import '../providers/medication_providers.dart';

class ArchivedMedicationsScreen extends ConsumerWidget {
  const ArchivedMedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                onRestore: () => _restore(context, ref, medication),
                onDelete: () => _delete(context, ref, medication),
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

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Medication medication,
  ) async {
    try {
      await ref.read(medicationRepositoryProvider).restore(medication.id);
      _invalidate(ref, medication.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${medication.name} به فهرست فعال برگشت.')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بازیابی دارو انجام نشد.')),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Medication medication,
  ) async {
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
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('انصراف'),
              ),
              FilledButton(
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
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(medicationRepositoryProvider)
          .deletePermanently(medication.id);
      _invalidate(ref, medication.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دارو و تاریخچه آن حذف شد.')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حذف دائمی انجام نشد.')),
        );
      }
    }
  }

  void _invalidate(WidgetRef ref, String medicationId) {
    ref.invalidate(activeMedicationsProvider);
    ref.invalidate(archivedMedicationsProvider);
    ref.invalidate(medicationByIdProvider(medicationId));
    ref.invalidate(inventoryEventsProvider(medicationId));
  }
}

class _ArchivedMedicationCard extends StatelessWidget {
  const _ArchivedMedicationCard({
    required this.medication,
    required this.onRestore,
    required this.onDelete,
  });

  final Medication medication;
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
                    onPressed: onRestore,
                    icon: const Icon(Icons.unarchive_outlined),
                    label: const Text('بازیابی'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  key: Key('delete-${medication.id}'),
                  tooltip: 'حذف دائمی',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_forever_outlined),
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
