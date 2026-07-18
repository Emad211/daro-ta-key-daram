import 'package:flutter/material.dart';

import '../../domain/medication.dart';
import '../../domain/medication_stock_snapshot.dart';

class MedicationCard extends StatelessWidget {
  const MedicationCard({
    required this.medication,
    required this.now,
    this.onTap,
    super.key,
  });

  final Medication medication;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final MedicationStockSnapshot snapshot = medication.stockAt(now);
    final _UrgencyStyle urgencyStyle = _UrgencyStyle.from(
      context,
      snapshot.urgency,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: urgencyStyle.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: urgencyStyle.foreground,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          medication.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_displayNumber(snapshot.estimatedRemainingUnits)} '
                          '${medication.unit.persianLabel} باقی‌مانده',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyStyle.background,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      snapshot.urgency.persianLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: urgencyStyle.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Metric(
                      label: 'روز کامل باقی‌مانده',
                      value: '${snapshot.fullRemainingDays}',
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'اتمام تقریبی',
                      value: _date(snapshot.depletionAt),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_left, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _date(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _displayNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _UrgencyStyle {
  const _UrgencyStyle({required this.background, required this.foreground});

  factory _UrgencyStyle.from(BuildContext context, MedicationUrgency urgency) {
    return switch (urgency) {
      MedicationUrgency.safe => const _UrgencyStyle(
        background: Color(0xFFE5F5EF),
        foreground: Color(0xFF12634F),
      ),
      MedicationUrgency.warning => const _UrgencyStyle(
        background: Color(0xFFFFF3D6),
        foreground: Color(0xFF855A00),
      ),
      MedicationUrgency.critical => const _UrgencyStyle(
        background: Color(0xFFFFE8E4),
        foreground: Color(0xFFA33A2B),
      ),
      MedicationUrgency.depleted => const _UrgencyStyle(
        background: Color(0xFFF1E8F8),
        foreground: Color(0xFF6B368D),
      ),
    };
  }

  final Color background;
  final Color foreground;
}
