import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../application/medication_repository.dart';
import '../../domain/medication.dart';
import '../../infrastructure/drift_medication_repository.dart';

final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>(
  (Ref ref) {
    final AppDatabase database = AppDatabase.defaults();
    ref.onDispose(database.close);
    return database;
  },
);

final Provider<MedicationRepository> medicationRepositoryProvider =
    Provider<MedicationRepository>((Ref ref) {
  return DriftMedicationRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  );
});

final StreamProvider<List<Medication>> activeMedicationsProvider =
    StreamProvider<List<Medication>>((Ref ref) {
  final MedicationRepository repository = ref.watch(
    medicationRepositoryProvider,
  );
  return repository.watchActiveMedications();
});
