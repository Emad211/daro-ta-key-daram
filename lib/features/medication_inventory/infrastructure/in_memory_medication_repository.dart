import 'dart:async';

import '../application/medication_details_update.dart';
import '../application/medication_lifecycle.dart';
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
    final int index = _requireAllowedIndex(
      medicationId,
      MedicationLifecycleOperation.archive,
    );
    _items[index] = _items[index].copyWith(isArchived: true);
    _emit();
  }

  @override
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
    final int index = _requireAllowedIndex(
      event.medicationId,
      MedicationLifecycleOperation.recordInventoryEvent,
    );

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
    final int index = _requireAllowedIndex(
      medicationId,
      MedicationLifecycleOperation.restore,
    );
    _items[index] = _items[index].copyWith(isArchived: false);
    _emit();
  }

  @override
  Future<void> create(Medication medication) async {
    MedicationLifecyclePolicy.ensureCreatable(
      medicationId: medication.id,
      isArchived: medication.isArchived,
    );
    final bool exists = _items.any(
      (Medication item) => item.id == medication.id,
    );
    if (exists) {
      throw StateError('An aggregate with this identifier already exists.');
    }

    _items.add(medication);
    _eventsByMedicationId[medication.id] = <InventoryEvent>[
      _initialEventFor(medication),
    ];
    _inventoryChanges.add(medication.id);
    _emit();
  }

  @override
  Future<void> updateDetails(MedicationDetailsUpdate update) async {
    final int index = _requireAllowedIndex(
      update.medicationId,
      MedicationLifecycleOperation.updateDetails,
    );

    final Medication previous = _items[index];
    final bool scheduleChanged =
        previous.consumptionSchedule != update.consumptionSchedule;
    Medication updated = update.applyTo(previous);

    if (scheduleChanged) {
      final DateTime now = _clock();
      final double currentEstimatedStock = previous
          .stockAt(now)
          .estimatedRemainingUnits;
      updated = updated.copyWith(
        stockAtRecord: currentEstimatedStock,
        inventoryRecordedAt: now,
      );
      final InventoryEvent change = InventoryEvent(
        id: 'memory-schedule-${update.medicationId}-${now.microsecondsSinceEpoch}',
        medicationId: update.medicationId,
        type: InventoryEventType.scheduleChange,
        stockUnits: currentEstimatedStock,
        effectiveAt: now,
        createdAt: now,
        note: 'Boundary created after a schedule update',
      );
      _eventsByMedicationId
          .putIfAbsent(update.medicationId, () => <InventoryEvent>[])
          .add(change);
      _eventsByMedicationId[update.medicationId]?.sort(_newestFirst);
      _inventoryChanges.add(update.medicationId);
    }

    _items[index] = updated;
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

  int _requireAllowedIndex(
    String medicationId,
    MedicationLifecycleOperation operation,
  ) {
    final int index = _items.indexWhere(
      (Medication medication) => medication.id == medicationId,
    );
    MedicationLifecyclePolicy.ensureAllowed(
      medicationId: medicationId,
      isArchived: index == -1 ? null : _items[index].isArchived,
      operation: operation,
    );
    return index;
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
