import 'dart:async';

import '../application/medication_repository.dart';
import '../domain/consumption_schedule.dart';
import '../domain/inventory_event.dart';
import '../domain/medication.dart';
import '../domain/medication_unit.dart';

class InMemoryMedicationRepository implements MedicationRepository {
  InMemoryMedicationRepository({
    List<Medication>? seed,
    DateTime Function()? clock,
  }) : _items = <Medication>[...?seed],
       _clock = clock ?? DateTime.now {
    for (final Medication medication in _items) {
      _eventsByMedicationId[medication.id] = <InventoryEvent>[
        _initialEventFor(medication),
      ];
    }
  }

  factory InMemoryMedicationRepository.withDemoData() {
    final DateTime now = DateTime.now();
    return InMemoryMedicationRepository(
      seed: <Medication>[
        Medication(
          id: 'demo-metformin',
          name: 'متفورمین',
          unit: MedicationUnit.tablet,
          stockAtRecord: 30,
          consumptionSchedule: DailyConsumptionSchedule(
            amountPerOccurrence: 1,
            occurrencesPerDay: 2,
          ),
          inventoryRecordedAt: now,
        ),
        Medication(
          id: 'demo-vitamin-d',
          name: 'ویتامین D',
          unit: MedicationUnit.capsule,
          stockAtRecord: 4,
          consumptionSchedule: WeeklyConsumptionSchedule(
            amountPerOccurrence: 1,
            weekdays: <int>{DateTime.friday},
          ),
          inventoryRecordedAt: now,
          alertLeadDays: 7,
        ),
      ],
    );
  }

  final List<Medication> _items;
  final DateTime Function() _clock;
  final Map<String, List<InventoryEvent>> _eventsByMedicationId =
      <String, List<InventoryEvent>>{};
  final StreamController<List<Medication>> _changes =
      StreamController<List<Medication>>.broadcast();
  final StreamController<String> _inventoryChanges =
      StreamController<String>.broadcast();

  List<Medication> get _activeSnapshot => _snapshot(isArchived: false);

  List<Medication> get _archivedSnapshot => _snapshot(isArchived: true);

  @override
  Future<void> archive(String medicationId) async {
    _setArchived(medicationId: medicationId, isArchived: true);
  }

  @override
  Future<void> deletePermanently(String medicationId) async {
    _items.removeWhere(
      (Medication medication) => medication.id == medicationId,
    );
    _eventsByMedicationId.remove(medicationId);
    _emit();
    _inventoryChanges.add(medicationId);
  }

  @override
  Future<Medication?> findById(String medicationId) async {
    for (final Medication medication in _items) {
      if (medication.id == medicationId) {
        return medication;
      }
    }
    return null;
  }

  @override
  Future<void> recordInventoryEvent(InventoryEvent event) async {
    final int index = _items.indexWhere(
      (Medication medication) => medication.id == event.medicationId,
    );
    if (index == -1) {
      throw StateError(
        'Cannot create inventory event for a missing medication.',
      );
    }

    final List<InventoryEvent> events = _eventsByMedicationId.putIfAbsent(
      event.medicationId,
      () => <InventoryEvent>[],
    );
    events.add(event);
    events.sort(_newestFirst);

    _items[index] = _items[index].copyWith(
      stockAtRecord: event.stockUnits,
      inventoryRecordedAt: event.effectiveAt,
    );
    _emit();
    _inventoryChanges.add(event.medicationId);
  }

  @override
  Future<void> restore(String medicationId) async {
    _setArchived(medicationId: medicationId, isArchived: false);
  }

  @override
  Future<void> upsert(Medication medication) async {
    final int index = _items.indexWhere(
      (Medication item) => item.id == medication.id,
    );
    if (index == -1) {
      _items.add(medication);
      _eventsByMedicationId[medication.id] = <InventoryEvent>[
        _initialEventFor(medication),
      ];
      _inventoryChanges.add(medication.id);
      _emit();
      return;
    }

    final Medication previous = _items[index];
    final bool scheduleChanged =
        previous.consumptionSchedule != medication.consumptionSchedule;
    final bool baselineChanged =
        previous.stockAtRecord != medication.stockAtRecord ||
        previous.inventoryRecordedAt != medication.inventoryRecordedAt;
    if (scheduleChanged && baselineChanged) {
      throw ArgumentError(
        'Change the consumption schedule and inventory baseline in separate '
        'operations.',
      );
    }

    if (scheduleChanged) {
      final DateTime now = _clock();
      final double currentEstimatedStock = previous
          .stockAt(now)
          .estimatedRemainingUnits;
      _items[index] = medication.copyWith(
        stockAtRecord: currentEstimatedStock,
        inventoryRecordedAt: now,
      );
      final InventoryEvent change = InventoryEvent(
        id: 'memory-schedule-${medication.id}-${now.microsecondsSinceEpoch}',
        medicationId: medication.id,
        type: InventoryEventType.scheduleChange,
        stockUnits: currentEstimatedStock,
        effectiveAt: now,
        createdAt: now,
        note: 'مبنای موجودی پس از تغییر برنامه مصرف',
      );
      _eventsByMedicationId
          .putIfAbsent(medication.id, () => <InventoryEvent>[])
          .add(change);
      _eventsByMedicationId[medication.id]?.sort(_newestFirst);
      _inventoryChanges.add(medication.id);
      _emit();
      return;
    }

    _items[index] = medication;
    if (baselineChanged) {
      final InventoryEvent correction = InventoryEvent(
        id:
            'memory-correction-${medication.id}-'
            '${medication.inventoryRecordedAt.microsecondsSinceEpoch}',
        medicationId: medication.id,
        type: InventoryEventType.correction,
        stockUnits: medication.stockAtRecord,
        effectiveAt: medication.inventoryRecordedAt,
        createdAt: medication.inventoryRecordedAt,
      );
      _eventsByMedicationId
          .putIfAbsent(medication.id, () => <InventoryEvent>[])
          .add(correction);
      _eventsByMedicationId[medication.id]?.sort(_newestFirst);
      _inventoryChanges.add(medication.id);
    }
    _emit();
  }

  @override
  Stream<List<Medication>> watchActiveMedications() async* {
    yield _activeSnapshot;
    yield* _changes.stream;
  }

  @override
  Stream<List<Medication>> watchArchivedMedications() async* {
    yield _archivedSnapshot;
    yield* _changes.stream.map((List<Medication> _) => _archivedSnapshot);
  }

  @override
  Stream<List<InventoryEvent>> watchInventoryEvents(
    String medicationId,
  ) async* {
    yield _inventorySnapshot(medicationId);
    await for (final String changedMedicationId in _inventoryChanges.stream) {
      if (changedMedicationId == medicationId) {
        yield _inventorySnapshot(medicationId);
      }
    }
  }

  void _emit() {
    _changes.add(_activeSnapshot);
  }

  List<Medication> _snapshot({required bool isArchived}) {
    return List<Medication>.unmodifiable(
      _items.where(
        (Medication medication) => medication.isArchived == isArchived,
      ),
    );
  }

  List<InventoryEvent> _inventorySnapshot(String medicationId) {
    return List<InventoryEvent>.unmodifiable(
      _eventsByMedicationId[medicationId] ?? const <InventoryEvent>[],
    );
  }

  void _setArchived({required String medicationId, required bool isArchived}) {
    final int index = _items.indexWhere(
      (Medication medication) => medication.id == medicationId,
    );
    if (index == -1) {
      throw StateError('Medication $medicationId does not exist.');
    }
    _items[index] = _items[index].copyWith(isArchived: isArchived);
    _emit();
  }

  static InventoryEvent _initialEventFor(Medication medication) {
    return InventoryEvent(
      id: 'memory-initial-${medication.id}',
      medicationId: medication.id,
      type: InventoryEventType.initial,
      stockUnits: medication.stockAtRecord,
      effectiveAt: medication.inventoryRecordedAt,
      createdAt: medication.inventoryRecordedAt,
    );
  }

  static int _newestFirst(InventoryEvent first, InventoryEvent second) {
    final int effectiveComparison = second.effectiveAt.compareTo(
      first.effectiveAt,
    );
    if (effectiveComparison != 0) {
      return effectiveComparison;
    }
    return second.createdAt.compareTo(first.createdAt);
  }
}
