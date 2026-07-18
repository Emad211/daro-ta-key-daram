import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../ads/presentation/ad_banner_slot.dart';
import '../../../notifications/application/local_notification_service.dart';
import '../../domain/medication.dart';
import '../providers/medication_providers.dart';
import '../widgets/medication_card.dart';

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Medication>> medications = ref.watch(
      activeMedicationsProvider,
    );
    final DateTime now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('دارو تا کی دارم؟'),
            Text(
              'تخمین موجودی، بدون نسخه‌نویسی',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'مدیریت آرشیو',
            onPressed: () => context.goNamed('archived-medications'),
            icon: const Icon(Icons.archive_outlined),
          ),
          IconButton(
            tooltip: 'فعال‌کردن یادآوری موجودی',
            onPressed: () => _requestNotificationPermission(context, ref),
            icon: const Icon(Icons.notifications_active_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add'),
        icon: const Icon(Icons.add),
        label: const Text('افزودن دارو'),
      ),
      body: medications.when(
        data: (List<Medication> items) {
          final List<Medication> sorted = <Medication>[...items]
            ..sort(
              (Medication first, Medication second) => first
                  .stockAt(now)
                  .depletionAt
                  .compareTo(second.stockAt(now).depletionAt),
            );

          if (sorted.isEmpty) {
            return EmptyState(
              title: 'هنوز دارویی ثبت نشده',
              message:
                  'موجودی و مصرف روزانه دارو را وارد کن تا برنامه '
                  'زمان تقریبی اتمام آن را حساب کند.',
              actionLabel: 'ثبت اولین دارو',
              onAction: () => context.go('/add'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeMedicationsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
              children: <Widget>[
                _SummaryCard(medications: sorted, now: now),
                const SizedBox(height: 14),
                const AdBannerSlot(),
                const SizedBox(height: 14),
                ...sorted.map(
                  (Medication medication) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MedicationCard(
                      medication: medication,
                      now: now,
                      onTap: () => context.goNamed(
                        'medication-details',
                        pathParameters: <String, String>{
                          'medicationId': medication.id,
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        error: (Object error, StackTrace stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.error_outline, size: 56),
                  const SizedBox(height: 12),
                  const Text('نمایش اطلاعات با خطا مواجه شد.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(activeMedicationsProvider),
                    child: const Text('تلاش دوباره'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _requestNotificationPermission(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final LocalNotificationService service = ref.read(
      localNotificationServiceProvider,
    );
    final NotificationPermissionState state = await service.requestPermission();
    if (!context.mounted) {
      return;
    }

    if (state == NotificationPermissionState.granted) {
      final int scheduled = await ref
          .read(notificationSyncCoordinatorProvider)
          .rebuildAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scheduled == 0
                  ? 'یادآوری فعال شد؛ داروی فعالی برای زمان‌بندی وجود ندارد.'
                  : 'یادآوری برای $scheduled دارو فعال شد.',
            ),
          ),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'مجوز اعلان فعال نشد؛ همه امکانات مدیریت دارو همچنان قابل استفاده‌اند.',
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.medications, required this.now});

  final List<Medication> medications;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final int urgentCount = medications
        .where(
          (Medication medication) =>
              medication.stockAt(now).fullRemainingDays <= 5,
        )
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _SummaryMetric(
                label: 'داروی فعال',
                value: '${medications.length}',
                icon: Icons.medication_outlined,
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              child: _SummaryMetric(
                label: 'نیازمند توجه',
                value: '$urgentCount',
                icon: Icons.notifications_active_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
