from pathlib import Path


def replace_once(path_string: str, old: str, new: str) -> None:
    path = Path(path_string)
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected block count 1, got {count}")
    path.write_text(text.replace(old, new))


for path_string, key in (
    (
        "lib/features/medication_inventory/presentation/screens/"
        "add_medication_screen.dart",
        "add-medication-unit",
    ),
    (
        "lib/features/medication_inventory/presentation/screens/"
        "edit_medication_screen.dart",
        "edit-medication-unit",
    ),
):
    replace_once(
        path_string,
        f"""              DropdownButtonFormField<MedicationUnit>(
                key: const Key('{key}'),
                initialValue: _selectedUnit,
""",
        f"""              DropdownButtonFormField<MedicationUnit>(
                key: const Key('{key}'),
                initialValue: _selectedUnit,
                isExpanded: true,
""",
    )
    replace_once(
        path_string,
        """                        child: Text(unit.persianLabel),
""",
        """                        child: Text(
                          unit.persianLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
""",
    )

schedule_path = (
    "lib/features/medication_inventory/presentation/widgets/"
    "consumption_schedule_input.dart"
)
replace_once(
    schedule_path,
    """            DropdownButtonFormField<ConsumptionScheduleKind>(
              key: const Key('schedule-kind'),
              initialValue: _kind,
""",
    """            DropdownButtonFormField<ConsumptionScheduleKind>(
              key: const Key('schedule-kind'),
              initialValue: _kind,
              isExpanded: true,
""",
)
replace_once(
    schedule_path,
    """                          child: Text(kind.persianLabel),
""",
    """                          child: Text(
                            kind.persianLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
""",
)
