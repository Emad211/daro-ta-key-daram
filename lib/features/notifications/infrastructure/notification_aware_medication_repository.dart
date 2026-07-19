import '../../medication_inventory/application/medication_details_update.dart';
import '../../medication_inventory/application/medication_repository.dart';
import '../../medication_inventory/domain/inventory_event.dart';
import '../../medication_inventory/domain/medication.dart';
import '../application/notification_sync_coordinator.dart';

final class NotificationAwareMedicationRepository
    implements MedicationRepository {
  const NotificationAwareMedicationRepository(
    this._delegate,
    this._notifications,
  );

  final MedicationRepository _delegate;
  final NotificationSyncCoordinator _notifications;

  @override
  Stream<List<Medication>> watchActiveMedications() {
    return _delegate.watchActiveMedications();
  }

  @override
  Stream<List<Medication>> watchArchivedMedications() {
    return _delegate.watchArchivedMedications();
  }

  @override
  Stream<List<InventoryEvent>> watchInventoryEvents(String medicationId) {
    return _delegate.watchInventoryEvents(medicationId);
  }

  @override
  Future<Medication?> findById(String medicationId) {
    return _delegate.findById(medicationId);
  }

  @override
  Future<void> create(Medication medication) async {
    await _delegate.create(medication);
    await _notifications.rescheduleMedication(medication.id);
  }

  @override
  Future<void> updateDetails(MedicationDetailsUpdate update) async {
    await _delegate.updateDetails(update);
    await _notifications.rescheduleMedication(update.medicationId);
  }

  @override
  Future<void> recordInventoryEvent(InventoryEvent event) async {
    await _delegate.recordInventoryEvent(event);
    await _notifications.rescheduleMedication(event.medicationId);
  }

  @override
  Future<void> archive(String medicationId) async {
    await _delegate.archive(medicationId);
    await _notifications.cancelMedication(medicationId);
  }

  @override
  Future<void> restore(String medicationId) async {
    await _delegate.restore(medicationId);
    await _notifications.rescheduleMedication(medicationId);
  }

  @override
  Future<void> deletePermanently(String medicationId) async {
    await _delegate.deletePermanently(medicationId);
    await _notifications.cancelMedication(medicationId);
  }
}
