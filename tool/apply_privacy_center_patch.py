from pathlib import Path


def replace_once(path_string: str, old: str, new: str) -> None:
    path = Path(path_string)
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected block count 1, got {count}")
    path.write_text(text.replace(old, new))


replace_once(
    "lib/features/medication_inventory/application/medication_repository.dart",
    """  Future<void> deletePermanently(String medicationId);
}
""",
    """  Future<void> deletePermanently(String medicationId);

  Future<void> deleteAll();
}
""",
)

replace_once(
    "lib/features/medication_inventory/infrastructure/drift_medication_repository.dart",
    """  @override
  Future<void> deletePermanently(String medicationId) async {
    await _database.transaction(() async {
      final MedicationRow? existing = await _findMedicationRow(medicationId);
      MedicationLifecyclePolicy.ensureAllowed(
        medicationId: medicationId,
        isArchived: existing?.isArchived,
        operation: MedicationLifecycleOperation.deletePermanently,
      );
      final int affected = await (_database.delete(
        _database.medications,
      )..where((Medications table) => table.id.equals(medicationId))).go();
      if (affected != 1) {
        throw StateError('Permanent deletion did not affect one aggregate.');
      }
    });
  }

""",
    """  @override
  Future<void> deletePermanently(String medicationId) async {
    await _database.transaction(() async {
      final MedicationRow? existing = await _findMedicationRow(medicationId);
      MedicationLifecyclePolicy.ensureAllowed(
        medicationId: medicationId,
        isArchived: existing?.isArchived,
        operation: MedicationLifecycleOperation.deletePermanently,
      );
      final int affected = await (_database.delete(
        _database.medications,
      )..where((Medications table) => table.id.equals(medicationId))).go();
      if (affected != 1) {
        throw StateError('Permanent deletion did not affect one aggregate.');
      }
    });
  }

  @override
  Future<void> deleteAll() async {
    await _database.transaction(() async {
      await _database.delete(_database.medications).go();
    });
  }

""",
)

replace_once(
    "lib/features/medication_inventory/infrastructure/in_memory_medication_repository.dart",
    """  @override
  Future<void> deletePermanently(String medicationId) async {
    final int index = _requireAllowedIndex(
      medicationId,
      MedicationLifecycleOperation.deletePermanently,
    );
    _items.removeAt(index);
    _eventsByMedicationId.remove(medicationId);
    _emit();
    _inventoryChanges.add(medicationId);
  }

""",
    """  @override
  Future<void> deletePermanently(String medicationId) async {
    final int index = _requireAllowedIndex(
      medicationId,
      MedicationLifecycleOperation.deletePermanently,
    );
    _items.removeAt(index);
    _eventsByMedicationId.remove(medicationId);
    _emit();
    _inventoryChanges.add(medicationId);
  }

  @override
  Future<void> deleteAll() async {
    final Set<String> medicationIds = <String>{
      ..._items.map((Medication medication) => medication.id),
      ..._eventsByMedicationId.keys,
    };
    _items.clear();
    _eventsByMedicationId.clear();
    _emit();
    for (final String medicationId in medicationIds) {
      _inventoryChanges.add(medicationId);
    }
  }

""",
)

replace_once(
    "lib/features/notifications/application/notification_sync_coordinator.dart",
    """  Future<bool> cancelMedication(String medicationId) async {
    try {
      await _notificationService.cancel(
        NotificationId.forMedication(medicationId),
      );
      return true;
    } on Object {
      return false;
    }
  }

  Future<int> rebuildAll() async {
""",
    """  Future<bool> cancelMedication(String medicationId) async {
    try {
      await _notificationService.cancel(
        NotificationId.forMedication(medicationId),
      );
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> cancelAll() async {
    try {
      await _notificationService.cancelAll();
      return true;
    } on Object {
      return false;
    }
  }

  Future<int> rebuildAll() async {
""",
)

replace_once(
    "lib/features/notifications/infrastructure/notification_aware_medication_repository.dart",
    """  @override
  Future<void> deletePermanently(String medicationId) async {
    await _delegate.deletePermanently(medicationId);
    await _notifications.cancelMedication(medicationId);
  }
}
""",
    """  @override
  Future<void> deletePermanently(String medicationId) async {
    await _delegate.deletePermanently(medicationId);
    await _notifications.cancelMedication(medicationId);
  }

  @override
  Future<void> deleteAll() async {
    await _delegate.deleteAll();
    await _notifications.cancelAll();
  }
}
""",
)

providers = "lib/features/medication_inventory/presentation/providers/medication_providers.dart"
replace_once(
    providers,
    """import '../../application/inventory_event_service.dart';
import '../../application/medication_repository.dart';
""",
    """import '../../application/inventory_event_service.dart';
import '../../application/local_medication_data_deletion_service.dart';
import '../../application/medication_repository.dart';
""",
)
replace_once(
    providers,
    """final Provider<InventoryEventService> inventoryEventServiceProvider =
    Provider<InventoryEventService>((Ref ref) {
      return InventoryEventService(
        ref.watch(medicationRepositoryProvider),
        ref.watch(clockProvider),
      );
    });

""",
    """final Provider<InventoryEventService> inventoryEventServiceProvider =
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

""",
)

router = "lib/app/router.dart"
replace_once(
    router,
    """import '../features/medication_inventory/presentation/screens/medication_list_screen.dart';
""",
    """import '../features/medication_inventory/presentation/screens/medication_list_screen.dart';
import '../features/privacy/presentation/privacy_center_screen.dart';
""",
)
replace_once(
    router,
    """        GoRoute(
          path: 'archive',
          name: 'archived-medications',
          builder: (BuildContext context, GoRouterState state) {
            return const ArchivedMedicationsScreen();
          },
        ),
""",
    """        GoRoute(
          path: 'archive',
          name: 'archived-medications',
          builder: (BuildContext context, GoRouterState state) {
            return const ArchivedMedicationsScreen();
          },
        ),
        GoRoute(
          path: 'privacy',
          name: 'privacy-center',
          builder: (BuildContext context, GoRouterState state) {
            return const PrivacyCenterScreen();
          },
        ),
""",
)

list_screen = (
    "lib/features/medication_inventory/presentation/screens/"
    "medication_list_screen.dart"
)
replace_once(
    list_screen,
    """        actions: <Widget>[
          Semantics(
            container: true,
            label: 'مدیریت آرشیو',
""",
    """        actions: <Widget>[
          Semantics(
            container: true,
            label: 'حریم خصوصی و مدیریت داده‌ها',
            button: true,
            enabled: true,
            onTap: () => context.goNamed('privacy-center'),
            excludeSemantics: true,
            child: IconButton(
              tooltip: 'حریم خصوصی و مدیریت داده‌ها',
              onPressed: () => context.goNamed('privacy-center'),
              icon: const Icon(Icons.privacy_tip_outlined),
            ),
          ),
          Semantics(
            container: true,
            label: 'مدیریت آرشیو',
""",
)
