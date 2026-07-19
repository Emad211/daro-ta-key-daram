import '../domain/consumption_schedule.dart';
import '../domain/medication.dart';
import '../domain/medication_unit.dart';

final class MedicationDetailsUpdate {
  MedicationDetailsUpdate({
    required String medicationId,
    required String name,
    required this.unit,
    required this.consumptionSchedule,
    required this.alertLeadDays,
    String? notes,
  }) : medicationId = medicationId.trim(),
       name = name.trim(),
       notes = _normalizeNotes(notes) {
    if (this.medicationId.isEmpty) {
      throw ArgumentError.value(
        medicationId,
        'medicationId',
        'The identifier cannot be empty.',
      );
    }
    if (this.name.isEmpty || this.name.length > 80) {
      throw ArgumentError.value(
        name,
        'name',
        'The name must contain between 1 and 80 characters.',
      );
    }
    if (alertLeadDays < 0 || alertLeadDays > 365) {
      throw RangeError.range(alertLeadDays, 0, 365, 'alertLeadDays');
    }
  }

  final String medicationId;
  final String name;
  final MedicationUnit unit;
  final ConsumptionSchedule consumptionSchedule;
  final int alertLeadDays;
  final String? notes;

  Medication applyTo(Medication current) {
    if (current.id != medicationId) {
      throw ArgumentError.value(
        current.id,
        'current.id',
        'The aggregate does not match this update command.',
      );
    }
    return current.copyWith(
      name: name,
      unit: unit,
      consumptionSchedule: consumptionSchedule,
      alertLeadDays: alertLeadDays,
      notes: notes,
      clearNotes: notes == null,
    );
  }

  static String? _normalizeNotes(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}
