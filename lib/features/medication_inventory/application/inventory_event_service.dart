import 'package:uuid/uuid.dart';

import '../domain/inventory_event.dart';
import 'medication_repository.dart';

final class InventoryEventService {
  InventoryEventService({
    required MedicationRepository repository,
    required DateTime Function() clock,
    Uuid? uuid,
  }) : _repository = repository,
       _clock = clock,
       _uuid = uuid ?? Uuid();

  final MedicationRepository _repository;
  final DateTime Function() _clock;
  final Uuid _uuid;

  Future<void> record({
    required String medicationId,
    required InventoryEventType type,
    required double stockUnits,
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
    await _repository.recordInventoryEvent(
      InventoryEvent(
        id: _uuid.v4(),
        medicationId: medicationId,
        type: type,
        stockUnits: stockUnits,
        effectiveAt: now,
        createdAt: now,
        note: note,
      ),
    );
  }
}
