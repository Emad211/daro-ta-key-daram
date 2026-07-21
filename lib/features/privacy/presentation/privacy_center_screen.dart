import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../medication_inventory/application/local_medication_data_deletion_service.dart';
import '../../medication_inventory/presentation/providers/medication_providers.dart';

class PrivacyCenterScreen extends ConsumerStatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  ConsumerState<PrivacyCenterScreen> createState() =>
      _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends ConsumerState<PrivacyCenterScreen> {
  bool _isDeleting = false;
  bool _isRetryingCleanup = false;
  bool _notificationCleanupPending = false;
  bool _deletionCompleted = false;

  bool get _isBusy => _isDeleting || _isRetryingCleanup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حریم خصوصی و اطلاعات برنامه')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          const _PrivacyNoticeCard(),
          const SizedBox(height: 12),
          const _MedicalBoundaryCard(),
          const SizedBox(height: 12),
          const _NotificationBoundaryCard(),
          const SizedBox(height: 12),
          const _AdvertisingBoundaryCard(),
          const SizedBox(height: 18),
          _DataDeletionCard(
            isBusy: _isBusy,
            deletionCompleted: _deletionCompleted,
            notificationCleanupPending: _notificationCleanupPending,
            onDelete: _isBusy ? null : _confirmAndDelete,
            onRetryCleanup:
                _notificationCleanupPending && !_isBusy
                ? _retryNotificationCleanup
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              scrollable: true,
              title: const Text('حذف همه اطلاعات دارویی؟'),
              content: const Text(
                'تمام داروهای فعال و آرشیوشده، موجودی‌ها و تاریخچه تغییرات '
                'برای همیشه از این دستگاه حذف می‌شوند. این عملیات قابل بازگشت نیست.',
              ),
              actions: <Widget>[
                TextButton(
                  key: const Key('cancel-delete-all-medication-data'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  key: const Key('confirm-delete-all-medication-data'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('حذف دائمی همه اطلاعات'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || _isBusy) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _deletionCompleted = false;
    });

    try {
      final LocalMedicationDataDeletionResult result = await ref
          .read(localMedicationDataDeletionServiceProvider)
          .deleteAll();
      ref.invalidate(activeMedicationsProvider);
      ref.invalidate(archivedMedicationsProvider);

      if (!mounted) {
        return;
      }
      setState(() {
        _deletionCompleted = true;
        _notificationCleanupPending = !result.notificationsCleared;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.notificationsCleared
                ? 'همه اطلاعات دارویی این دستگاه حذف شد.'
                : 'اطلاعات دارویی حذف شد؛ پاک‌سازی اعلان‌ها کامل نشد.',
          ),
        ),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حذف اطلاعات دارویی انجام نشد. هیچ حذف ناقصی گزارش نشده است.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _retryNotificationCleanup() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isRetryingCleanup = true);

    final bool succeeded = await ref
        .read(localMedicationDataDeletionServiceProvider)
        .retryNotificationCleanup();
    if (!mounted) {
      return;
    }

    setState(() {
      _isRetryingCleanup = false;
      _notificationCleanupPending = !succeeded;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'اعلان‌های باقی‌مانده پاک شدند.'
              : 'پاک‌سازی اعلان‌ها دوباره انجام نشد. بعداً تلاش کنید.',
        ),
      ),
    );
  }
}

class _PrivacyNoticeCard extends StatelessWidget {
  const _PrivacyNoticeCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.lock_outline,
      title: 'اطلاعات دارویی روی دستگاه',
      body:
          'نام دارو، برنامه مصرف، موجودی، توضیحات و تاریخچه تغییرات در نسخه فعلی '
          'داخل پایگاه داده همین برنامه نگهداری می‌شوند. برنامه حساب کاربری یا '
          'فضای ابری برای اطلاعات دارویی ندارد.',
    );
  }
}

class _MedicalBoundaryCard extends StatelessWidget {
  const _MedicalBoundaryCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.health_and_safety_outlined,
      title: 'مرز ایمنی پزشکی',
      body:
          'محاسبات برنامه تقریبی و بر اساس اطلاعات واردشده توسط شما هستند. برنامه '
          'تشخیص پزشکی، نسخه‌نویسی یا پیشنهاد تغییر دوز انجام نمی‌دهد. دارو را فقط '
          'مطابق دستور پزشک یا داروساز مصرف کنید.',
    );
  }
}

class _NotificationBoundaryCard extends StatelessWidget {
  const _NotificationBoundaryCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.notifications_none_outlined,
      title: 'اعلان‌ها',
      body:
          'مجوز اعلان اختیاری است. ردکردن آن مانع مدیریت دارو نمی‌شود. هنگام حذف '
          'همه اطلاعات دارویی، برنامه تلاش می‌کند تمام اعلان‌های خودش را نیز پاک کند.',
    );
  }
}

class _AdvertisingBoundaryCard extends StatelessWidget {
  const _AdvertisingBoundaryCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.ads_click_outlined,
      title: 'تبلیغات و سرویس‌های ثالث',
      body:
          'اطلاعاتی مانند نام دارو، موجودی، برنامه مصرف و یادداشت‌ها نباید به سرویس '
          'تبلیغاتی یا تحلیل فنی ارسال شوند. پیش از فعال‌شدن هر SDK ثالث، سیاست '
          'حریم خصوصی و افشای داده فروشگاه باید به‌روزرسانی شود.',
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(height: 1.65)),
          ],
        ),
      ),
    );
  }
}

class _DataDeletionCard extends StatelessWidget {
  const _DataDeletionCard({
    required this.isBusy,
    required this.deletionCompleted,
    required this.notificationCleanupPending,
    required this.onDelete,
    required this.onRetryCleanup,
  });

  final bool isBusy;
  final bool deletionCompleted;
  final bool notificationCleanupPending;
  final VoidCallback? onDelete;
  final VoidCallback? onRetryCleanup;

  @override
  Widget build(BuildContext context) {
    final Color error = Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(Icons.delete_forever_outlined, color: error),
            const SizedBox(height: 10),
            Text(
              'حذف همه اطلاعات دارویی',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: error,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'این فرمان فقط داده‌های دارویی این برنامه و تاریخچه وابسته را حذف '
              'می‌کند. تنظیمات Android، فروشگاه یا سرویس‌های ثالث خارج از این '
              'فرمان هستند.',
              style: TextStyle(height: 1.65),
            ),
            if (deletionCompleted) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'اطلاعات دارویی محلی حذف شده‌اند.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            if (notificationCleanupPending) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'پاک‌سازی اعلان‌ها کامل نشده است؛ داده‌های دارویی قبلاً حذف شده‌اند.',
                style: TextStyle(color: error, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('retry-notification-cleanup'),
                onPressed: onRetryCleanup,
                icon: isBusy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('تلاش دوباره برای پاک‌سازی اعلان‌ها'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('delete-all-medication-data'),
              onPressed: onDelete,
              style: FilledButton.styleFrom(
                backgroundColor: error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              icon: isBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(isBusy ? 'در حال انجام...' : 'حذف دائمی همه اطلاعات'),
            ),
          ],
        ),
      ),
    );
  }
}
