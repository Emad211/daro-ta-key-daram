import '../domain/inventory_event.dart';
import '../domain/medication.dart';

abstract interface class MedicationRepository {
  Stream<List<Medication>> watchActiveMedications();

  Stream<List<Medication>> watchArchivedMedications();

  Stream<List<InventoryEvent>> watchInventoryEvents(String medicationId);

  Future<Medication?> findById(String medicationId);

  Future<void> upsert(Medication medication);

  Future<void> recordInventoryEvent(InventoryEvent event);

  Future<void> archive(String medicationId);

  Future<void> restore(String medicationId);

  Future<void> deletePermanently(String medicationId);
}
