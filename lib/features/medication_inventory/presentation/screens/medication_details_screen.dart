import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/medication_repository.dart';
import '../../domain/inventory_event.dart';
import '../../domain/medication.dart';
import '../../domain/medication_stock_snapshot.dart';
import '../providers/medication_providers.dart';
import '../widgets/inventory_event_form_sheet.dart';

class MedicationDetailsScreen extends ConsumerWidget {
  const MedicationDetailsScreen({required this.medicationId, super.key});

  final String medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Medication?> medication = ref.watch(
      medicationByIdProvider(medicationId),
    );

    return medication.when(
      data: (Medication? value) {
        if (value == null) {
          return _MedicationNotFound(onBack: () => context.go('/'));
        }
        return _MedicationDetailsScaffold(medication: value);
      },
      error: (Object error, StackTrace stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('جزئیات دارو')),
        body: _LoadError(
          onRetry: () => ref.invalidate(
            medicationByIdProvider(medicationId),
          ),
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('جزئیات دارو')),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _MedicationDetailsScaffold extends ConsumerWidget {
  const _MedicationDetailsScaffold({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(clockProvider)();
    final MedicationStockSnapshot snapshot = medication.stockAt(now);
    final AsyncValue<List<InventoryEvent>> history = ref.watch(
      inventoryEventsProvider(medication.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(medication.name),
        actions: <Widget>[
          IconButton(
            tooltip: 'آرشیو دارو',
            onPressed: () => _archive(context, ref),
            icon: const Icon(Icons.archive_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            _StockSummaryCard(
              medication: medication,
              snapshot: snapshot,
            ),
            const SizedBox(height: 14),
            _ActionCard(
              onRestock: () => _showInventoryForm(
                context,
                InventoryEventType.restock,
              ),
              onCorrection: () => _showInventoryForm(
                context,
                InventoryEventType.correction,
              ),
            ),
            const SizedBox(height: 14),
            _MedicationInformationCard(medication: medication),
            const SizedBox(height: 22),
            Text(
              'تاریخچه موجودی',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            history.when(
              data: (List<InventoryEvent> events) =>
                  _InventoryTimeline(events: events, medication: medication),
              error: (Object error, StackTrace stackTrace) => _HistoryError(
                onRetry: () => ref.invalidate(
                  inventoryEventsProvider(medication.id),
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInventoryForm(
    BuildContext context,
    InventoryEventType type,
  ) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext context) => InventoryEventFormSheet(
        medication: medication,
        type: type,
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${type.persianLabel} با موفقیت ثبت شد.')),
      );
    }
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('آرشیو دارو؟'),
            content: Text(
              '${medication.name} از فهرست داروهای فعال حذف می‌شود، اما '
              'اطلاعات و تاریخچه آن پاک نخواهد شد.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('انصراف'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('آرشیو'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      final MedicationRepository repository = ref.read(
        medicationRepositoryProvider,
      );
      await repository.archive(medication.id);
      ref.invalidate(activeMedicationsProvider);
      ref.invalidate(medicationByIdProvider(medication.id));
      if (context.mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دارو آرشیو شد.')),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('آرشیو دارو انجام نشد.')),
        );
      }
    }
  }
}

class _StockSummaryCard extends StatelessWidget {
  const _StockSummaryCard({
    required this.medication,
    required this.snapshot,
  });

  final Medication medication;
  final MedicationStockSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    snapshot.urgency.persianLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(Icons.query_builder_outlined),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${_number(snapshot.estimatedRemainingUnits)} '
              '${medication.unit.persianLabel}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${snapshot.fullRemainingDays} روز کامل باقی‌مانده • '
              'اتمام تقریبی ${_date(snapshot.depletionAt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.onRestock,
    required this.onCorrection,
  });

  final VoidCallback onRestock;
  final VoidCallback onCorrection;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: onRestock,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('خرید مجدد'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCorrection,
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('اصلاح موجودی'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationInformationCard extends StatelessWidget {
  const _MedicationInformationCard({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final String notes = medication.notes?.trim() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            _InformationRow(
              icon: Icons.schedule_outlined,
              label: 'مصرف ثبت‌شده روزانه',
              value: '${_number(medication.unitsPerDay)} '
                  '${medication.unit.persianLabel}',
            ),
            const Divider(height: 24),
            _InformationRow(
              icon: Icons.notifications_outlined,
              label: 'فاصله هشدار',
              value: '${medication.alertLeadDays} روز قبل از اتمام',
            ),
            if (notes.isNotEmpty) ...<Widget>[
              const Divider(height: 24),
              _InformationRow(
                icon: Icons.notes_outlined,
                label: 'توضیحات',
                value: notes,
              ),
            ],
            const Divider(height: 24),
            const _InformationRow(
              icon: Icons.health_and_safety_outlined,
              label: 'محدودیت برنامه',
              value: 'برنامه مقدار مصرف را پیشنهاد یا تغییر نمی‌دهد.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryTimeline extends StatelessWidget {
  const _InventoryTimeline({required this.events, required this.medication});

  final List<InventoryEvent> events;
  final Medication medication;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('هنوز رویدادی برای این دارو ثبت نشده است.'),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final InventoryEvent event = events[index];
          return ListTile(
            leading: CircleAvatar(
              child: Icon(_eventIcon(event.type), size: 20),
            ),
            title: Text(event.type.persianLabel),
            subtitle: Text(
              '${_dateTime(event.effectiveAt)}'
              '${event.note == null || event.note!.isEmpty ? '' : '\n${event.note}'}',
            ),
            trailing: Text(
              '${_number(event.stockUnits)}\n'
              '${medication.unit.persianLabel}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            isThreeLine: event.note != null && event.note!.isNotEmpty,
          );
        },
      ),
    );
  }

  static IconData _eventIcon(InventoryEventType type) {
    return switch (type) {
      InventoryEventType.initial => Icons.flag_outlined,
      InventoryEventType.restock => Icons.add_shopping_cart_outlined,
      InventoryEventType.correction => Icons.edit_note_outlined,
    };
  }
}

class _MedicationNotFound extends StatelessWidget {
  const _MedicationNotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دارو پیدا نشد')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.search_off_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                'این دارو حذف شده یا شناسه آن معتبر نیست.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onBack, child: const Text('بازگشت')),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            const Text('دریافت اطلاعات دارو با خطا مواجه شد.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('تلاش دوباره')),
          ],
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const Expanded(child: Text('دریافت تاریخچه انجام نشد.')),
            TextButton(onPressed: onRetry, child: const Text('تلاش دوباره')),
          ],
        ),
      ),
    );
  }
}

String _number(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

String _date(DateTime value) {
  return '${value.year}/${value.month.toString().padLeft(2, '0')}/'
      '${value.day.toString().padLeft(2, '0')}';
}

String _dateTime(DateTime value) {
  return '${_date(value)} • '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
