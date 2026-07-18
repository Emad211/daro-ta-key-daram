import '../domain/medication.dart';

abstract interface class MedicationRepository {
  Stream<List<Medication>> watchActiveMedications();

  Future<void> upsert(Medication medication);

  Future<void> archive(String medicationId);

  Future<void> deletePermanently(String medicationId);
}
