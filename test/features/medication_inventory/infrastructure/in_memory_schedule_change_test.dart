import 'package:daro_ta_key_daram/features/medication_inventory/application/medication_details_update.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/consumption_schedule.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/inventory_event.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/domain/medication_unit.dart';
import 'package:daro_ta_key_daram/features/medication_inventory/infrastructure/in_memory_medication_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'in-memory repository preserves current stock on schedule change',
    () async {
      final DateTime baseline = DateTime(2026, 7, 1, 8);
      final DateTime changeTime = DateTime(2026, 7, 3, 8);
      final Medication initial = Medication(
        id: 'medication-1',
        name: 'Test',
        unit: MedicationUnit.tablet,
        stockAtRecord: 10,
        consumptionSchedule: DailyConsumptionSchedule(
          amountPerOccurrence: 1,
          occurrencesPerDay: 1,
        ),
        inventoryRecordedAt: baseline,
      );
      final InMemoryMedicationRepository repository =
          InMemoryMedicationRepository(
            seed: <Medication>[initial],
            clock: () => changeTime,
          );

      await repository.updateDetails(
        MedicationDetailsUpdate(
          medicationId: initial.id,
          name: initial.name,
          unit: initial.unit,
          consumptionSchedule: WeeklyConsumptionSchedule(
            amountPerOccurrence: 1,
            weekdays: <int>{DateTime.friday},
          ),
          alertLeadDays: initial.alertLeadDays,
          notes: initial.notes,
        ),
      );

      final Medication updated = (await repository.findById(initial.id))!;
      final List<InventoryEvent> events = await repository
          .watchInventoryEvents(initial.id)
          .first;

      expect(updated.stockAtRecord, 8);
      expect(updated.inventoryRecordedAt, changeTime);
      expect(events, hasLength(2));
      expect(
        events.where(
          (InventoryEvent event) =>
              event.type == InventoryEventType.scheduleChange,
        ),
        hasLength(1),
      );
      expect(
        events
            .singleWhere(
              (InventoryEvent event) =>
                  event.type == InventoryEventType.scheduleChange,
            )
            .stockUnits,
        8,
      );
    },
  );
}
