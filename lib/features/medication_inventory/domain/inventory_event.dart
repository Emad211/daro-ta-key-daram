enum InventoryEventType {
  initial,
  restock,
  correction;

  String get persianLabel {
    return switch (this) {
      InventoryEventType.initial => 'ثبت اولیه',
      InventoryEventType.restock => 'خرید مجدد',
      InventoryEventType.correction => 'اصلاح موجودی',
    };
  }
}

class InventoryEvent {
  InventoryEvent({
    required this.id,
    required this.medicationId,
    required this.type,
    required double stockUnits,
    required this.effectiveAt,
    required this.createdAt,
    String? note,
  }) : stockUnits = stockUnits,
       note = note?.trim() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'شناسه رویداد نمی‌تواند خالی باشد.');
    }
    if (medicationId.trim().isEmpty) {
      throw ArgumentError.value(
        medicationId,
        'medicationId',
        'شناسه دارو نمی‌تواند خالی باشد.',
      );
    }
    if (!stockUnits.isFinite || stockUnits < 0) {
      throw ArgumentError.value(
        stockUnits,
        'stockUnits',
        'موجودی رویداد باید عددی نامنفی باشد.',
      );
    }
  }

  final String id;
  final String medicationId;
  final InventoryEventType type;
  final double stockUnits;
  final DateTime effectiveAt;
  final DateTime createdAt;
  final String? note;
}
