import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/input/localized_number_parser.dart';
import '../../domain/inventory_event.dart';
import '../../domain/medication.dart';
import '../providers/medication_providers.dart';

class InventoryEventFormSheet extends ConsumerStatefulWidget {
  const InventoryEventFormSheet({
    required this.medication,
    required this.type,
    super.key,
  });

  final Medication medication;
  final InventoryEventType type;

  @override
  ConsumerState<InventoryEventFormSheet> createState() {
    return _InventoryEventFormSheetState();
  }
}

class _InventoryEventFormSheetState
    extends ConsumerState<InventoryEventFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _stockController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRestock = widget.type == InventoryEventType.restock;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        isRestock ? 'ثبت خرید مجدد' : 'اصلاح موجودی',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving ? null : Navigator.of(context).pop,
                      tooltip: 'بستن',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isRestock
                      ? 'تعداد کل ${widget.medication.unit.persianLabel} را '
                            'بعد از خرید وارد کنید؛ نه فقط مقدار خریداری‌شده.'
                      : 'موجودی فعلی را دوباره بشمارید و عدد واقعی را وارد کنید.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _stockController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'موجودی کل جدید',
                    suffixText: widget.medication.unit.persianLabel,
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (String? value) {
                    final double? number = LocalizedNumberParser.tryParseDouble(
                      value,
                    );
                    if (number == null || !number.isFinite || number < 0) {
                      return 'یک عدد نامنفی معتبر وارد کنید.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'توضیح اختیاری',
                    hintText: 'مثلاً خرید از داروخانه یا شمارش مجدد',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),
                const _SafetyNotice(),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'در حال ثبت...' : 'ثبت موجودی جدید'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final double stockUnits = LocalizedNumberParser.tryParseDouble(
        _stockController.text,
      )!;
      await ref
          .read(inventoryEventServiceProvider)
          .record(
            medicationId: widget.medication.id,
            type: widget.type,
            stockUnits: stockUnits,
            note: _noteController.text,
          );

      ref.invalidate(medicationByIdProvider(widget.medication.id));
      ref.invalidate(activeMedicationsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ثبت موجودی انجام نشد. دوباره تلاش کنید.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'این عملیات فقط مبنای محاسبه موجودی را به‌روزرسانی می‌کند و '
            'هیچ تغییری در مقدار مصرف روزانه ایجاد نمی‌کند.',
            style: TextStyle(height: 1.55),
          ),
        ),
      ],
    );
  }
}
