from pathlib import Path


def replace_once(path_string: str, old: str, new: str) -> None:
    path = Path(path_string)
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected block count 1, got {count}")
    path.write_text(text.replace(old, new))


replace_once(
    "test/features/medication_inventory/presentation/error_recovery_widget_test.dart",
    """  @override
  Future<Medication?> findById(String medicationId) {
    return _delegate.findById(medicationId);
  }
""",
    """  @override
  Future<void> deleteAll() {
    return _delegate.deleteAll();
  }

  @override
  Future<Medication?> findById(String medicationId) {
    return _delegate.findById(medicationId);
  }
""",
)

replace_once(
    "test/features/privacy/presentation/privacy_center_widget_test.dart",
    """      overrides: <Override>[
""",
    """      overrides: [
""",
)
