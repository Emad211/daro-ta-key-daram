import 'package:uuid/uuid.dart';

import '../domain/inventory_event.dart';
import '../domain/medication.dart';
import 'medication_repository.dart';

final class InventoryEventService {
  InventoryEventService(this._repository, this._clock, {Uuid? uuid})
    : _uuid = uuid ?? Uuid();

  final MedicationRepository _repository;
  final DateTime Function() _clock;
  final Uuid _uuid;

  Future<void> record({
    required String medicationId,
    required InventoryEventType type,
    required double stockUnits,
    DateTime? effectiveAt,
    String? note,
  }) async {
    if (type == InventoryEventType.initial) {
      throw ArgumentError.value(
        type,
        'type',
        'Initial inventory events are created with the medication.',
      );
    }

    final DateTime now = _clock();
    final DateTime selectedEffectiveAt = effectiveAt ?? now;
    if (selectedEffectiveAt.isAfter(now)) {
      throw ArgumentError.value(
        effectiveAt,
        'effectiveAt',
        'Inventory events cannot become effective in the future.',
      );
    }

    final Medication? current = await _repository.findById(medicationId);
    if (current != null &&
        selectedEffectiveAt.isBefore(current.inventoryRecordedAt)) {
      throw ArgumentError.value(
        effectiveAt,
        'effectiveAt',
        'Inventory events cannot precede the current inventory baseline.',
      );
    }

    await _repository.recordInventoryEvent(
      InventoryEvent(
        id: _uuid.v4(),
        medicationId: medicationId,
        type: type,
        stockUnits: stockUnits,
        effectiveAt: selectedEffectiveAt,
        createdAt: now,
        note: note,
      ),
    );
  }
}
