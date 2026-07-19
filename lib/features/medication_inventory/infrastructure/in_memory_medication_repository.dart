import 'dart:async';

import '../application/medication_details_update.dart';
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
    final int index = _indexOf(medicationId);
    if (index == -1) {
      throw StateError('The requested aggregate does not exist.');
    }
    _items.removeAt(index);
    _eventsByMedicationId.remove(medicationId);
    _emit();
    _inventoryChanges.add(medicationId);
  }

  @override
  Future<Medication?> findById(String medicationId) async {
    final int index = _indexOf(medicationId);
    return index == -1 ? null : _items[index];
  }

  @override
  Future<void> recordInventoryEvent(InventoryEvent event) async {
    final int index = _indexOf(event.medicationId);
    if (index == -1) {
      throw StateError('The requested aggregate does not exist.');
    }
    final Medication current = _items[index];
    _requireActive(current);
    if (event.effectiveAt.isAfter(_clock())) {
      throw ArgumentError.value(
        event.effectiveAt,
        'event.effectiveAt',
        'An event cannot become effective in the future.',
      );
    }
    if (_containsEventId(event.id)) {
      throw StateError('An event with this identifier already exists.');
    }

    final List<InventoryEvent> events = _eventsByMedicationId.putIfAbsent(
      event.medicationId,
      () => <InventoryEvent>[],
    );
    events.add(event);
    events.sort(_newestFirst);

    _items[index] = current.copyWith(
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
  Future<void> create(Medication medication) async {
    if (medication.isArchived) {
      throw ArgumentError.value(
        medication.isArchived,
        'medication.isArchived',
        'A new aggregate must start active.',
      );
    }
    if (medication.inventoryRecordedAt.isAfter(_clock())) {
      throw ArgumentError.value(
        medication.inventoryRecordedAt,
        'medication.inventoryRecordedAt',
        'The initial baseline cannot become effective in the future.',
      );
    }
    if (_indexOf(medication.id) != -1) {
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
    final int index = _indexOf(update.medicationId);
    if (index == -1) {
      throw StateError('The requested aggregate does not exist.');
    }

    final Medication previous = _items[index];
    _requireActive(previous);
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
      if (_containsEventId(change.id)) {
        throw StateError('An event with this identifier already exists.');
      }
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

  int _indexOf(String medicationId) {
    return _items.indexWhere(
      (Medication medication) => medication.id == medicationId,
    );
  }

  bool _containsEventId(String eventId) {
    return _eventsByMedicationId.values.any(
      (List<InventoryEvent> events) =>
          events.any((InventoryEvent event) => event.id == eventId),
    );
  }

  void _requireActive(Medication medication) {
    if (medication.isArchived) {
      throw StateError('Archived aggregates are read-only.');
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
    final int index = _indexOf(medicationId);
    if (index == -1) {
      throw StateError('The requested aggregate does not exist.');
    }
    if (_items[index].isArchived == isArchived) {
      return;
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
