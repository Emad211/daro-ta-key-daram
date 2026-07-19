import 'medication_details_update.dart';
import '../domain/inventory_event.dart';
import '../domain/medication.dart';

abstract interface class MedicationRepository {
  Stream<List<Medication>> watchActiveMedications();

  Stream<List<Medication>> watchArchivedMedications();

  Stream<List<InventoryEvent>> watchInventoryEvents(String medicationId);

  Future<Medication?> findById(String medicationId);

  Future<void> create(Medication medication);

  Future<void> updateDetails(MedicationDetailsUpdate update);

  Future<void> recordInventoryEvent(InventoryEvent event);

  Future<void> archive(String medicationId);

  Future<void> restore(String medicationId);

  Future<void> deletePermanently(String medicationId);
}
