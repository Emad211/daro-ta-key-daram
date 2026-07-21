import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../notifications/application/local_notification_service.dart';
import '../../../notifications/application/notification_sync_coordinator.dart';
import '../../../notifications/infrastructure/flutter_local_notification_service.dart';
import '../../../notifications/infrastructure/noop_local_notification_service.dart';
import '../../../notifications/infrastructure/notification_aware_medication_repository.dart';
import '../../application/inventory_event_service.dart';
import '../../application/local_medication_data_deletion_service.dart';
import '../../application/medication_repository.dart';
import '../../domain/inventory_event.dart';
import '../../domain/medication.dart';
import '../../infrastructure/drift_medication_repository.dart';

final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((
  Ref ref,
) {
  final AppDatabase database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});

final Provider<MedicationRepository> rawMedicationRepositoryProvider =
    Provider<MedicationRepository>((Ref ref) {
      return DriftMedicationRepository(
        ref.watch(appDatabaseProvider),
        clock: ref.watch(clockProvider),
      );
    });

final Provider<LocalNotificationService> localNotificationServiceProvider =
    Provider<LocalNotificationService>((Ref ref) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return FlutterLocalNotificationService();
      }
      return const NoopLocalNotificationService();
    });

final Provider<NotificationSyncCoordinator>
notificationSyncCoordinatorProvider = Provider<NotificationSyncCoordinator>((
  Ref ref,
) {
  return NotificationSyncCoordinator(
    medicationRepository: ref.watch(rawMedicationRepositoryProvider),
    notificationService: ref.watch(localNotificationServiceProvider),
    clock: ref.watch(clockProvider),
  );
});

final Provider<MedicationRepository> medicationRepositoryProvider =
    Provider<MedicationRepository>((Ref ref) {
      return NotificationAwareMedicationRepository(
        ref.watch(rawMedicationRepositoryProvider),
        ref.watch(notificationSyncCoordinatorProvider),
      );
    });

final Provider<InventoryEventService> inventoryEventServiceProvider =
    Provider<InventoryEventService>((Ref ref) {
      return InventoryEventService(
        ref.watch(medicationRepositoryProvider),
        ref.watch(clockProvider),
      );
    });

final Provider<LocalMedicationDataDeletionService>
localMedicationDataDeletionServiceProvider =
    Provider<LocalMedicationDataDeletionService>((Ref ref) {
      return LocalMedicationDataDeletionService(
        ref.watch(rawMedicationRepositoryProvider),
        ref.watch(notificationSyncCoordinatorProvider),
      );
    });

final StreamProvider<List<Medication>> activeMedicationsProvider =
    StreamProvider<List<Medication>>((Ref ref) {
      return ref.watch(medicationRepositoryProvider).watchActiveMedications();
    });

final StreamProvider<List<Medication>> archivedMedicationsProvider =
    StreamProvider<List<Medication>>((Ref ref) {
      return ref.watch(medicationRepositoryProvider).watchArchivedMedications();
    });

final medicationByIdProvider = FutureProvider.family<Medication?, String>((
  Ref ref,
  String medicationId,
) {
  return ref.watch(medicationRepositoryProvider).findById(medicationId);
});

final inventoryEventsProvider =
    StreamProvider.family<List<InventoryEvent>, String>((
      Ref ref,
      String medicationId,
    ) {
      return ref
          .watch(medicationRepositoryProvider)
          .watchInventoryEvents(medicationId);
    });
