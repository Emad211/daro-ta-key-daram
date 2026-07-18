import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/medication_repository.dart';
import '../../domain/medication.dart';
import '../../infrastructure/in_memory_medication_repository.dart';

final Provider<DateTime Function()> clockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

final Provider<MedicationRepository> medicationRepositoryProvider =
    Provider<MedicationRepository>((Ref ref) {
  return InMemoryMedicationRepository.withDemoData();
});

final StreamProvider<List<Medication>> activeMedicationsProvider =
    StreamProvider<List<Medication>>((Ref ref) {
  final MedicationRepository repository = ref.watch(
    medicationRepositoryProvider,
  );
  return repository.watchActiveMedications();
});
