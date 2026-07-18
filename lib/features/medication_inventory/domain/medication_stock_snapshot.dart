enum MedicationUrgency {
  safe,
  warning,
  critical,
  depleted;

  String get persianLabel {
    return switch (this) {
      MedicationUrgency.safe => 'موجودی مناسب',
      MedicationUrgency.warning => 'نزدیک به اتمام',
      MedicationUrgency.critical => 'بحرانی',
      MedicationUrgency.depleted => 'تمام‌شده',
    };
  }
}

class MedicationStockSnapshot {
  const MedicationStockSnapshot({
    required this.estimatedRemainingUnits,
    required this.exactRemainingDays,
    required this.fullRemainingDays,
    required this.depletionAt,
    required this.reorderAt,
    required this.urgency,
  });

  final double estimatedRemainingUnits;
  final double exactRemainingDays;
  final int fullRemainingDays;
  final DateTime depletionAt;
  final DateTime reorderAt;
  final MedicationUrgency urgency;
}
