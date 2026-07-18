import 'dart:async';

import '../application/medication_repository.dart';
import '../domain/medication.dart';
import '../domain/medication_unit.dart';

class InMemoryMedicationRepository implements MedicationRepository {
  InMemoryMedicationRepository({List<Medication>? seed})
    : _items = <Medication>[...?seed];

  factory InMemoryMedicationRepository.withDemoData() {
    final DateTime now = DateTime.now();
    return InMemoryMedicationRepository(
      seed: <Medication>[
        Medication(
          id: 'demo-metformin',
          name: 'متفورمین',
          unit: MedicationUnit.tablet,
          stockAtRecord: 30,
          unitsPerDay: 2,
          inventoryRecordedAt: now,
        ),
        Medication(
          id: 'demo-vitamin-d',
          name: 'ویتامین D',
          unit: MedicationUnit.capsule,
          stockAtRecord: 4,
          unitsPerDay: 1 / 7,
          inventoryRecordedAt: now,
          alertLeadDays: 7,
        ),
      ],
    );
  }

  final List<Medication> _items;
  final StreamController<List<Medication>> _changes =
      StreamController<List<Medication>>.broadcast();

  List<Medication> get _activeSnapshot {
    return _items
        .where((Medication medication) => !medication.isArchived)
        .toList(growable: false);
  }

  @override
  Future<void> archive(String medicationId) async {
    final int index = _items.indexWhere(
      (Medication medication) => medication.id == medicationId,
    );
    if (index == -1) {
      return;
    }
    _items[index] = _items[index].copyWith(isArchived: true);
    _emit();
  }

  @override
  Future<void> deletePermanently(String medicationId) async {
    _items.removeWhere(
      (Medication medication) => medication.id == medicationId,
    );
    _emit();
  }

  @override
  Future<void> upsert(Medication medication) async {
    final int index = _items.indexWhere(
      (Medication item) => item.id == medication.id,
    );
    if (index == -1) {
      _items.add(medication);
    } else {
      _items[index] = medication;
    }
    _emit();
  }

  @override
  Stream<List<Medication>> watchActiveMedications() async* {
    yield _activeSnapshot;
    yield* _changes.stream;
  }

  void _emit() {
    _changes.add(_activeSnapshot);
  }
}
