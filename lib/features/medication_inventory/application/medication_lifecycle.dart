enum MedicationLifecycleState { active, archived, missing }

enum MedicationLifecycleOperation {
  create,
  updateDetails,
  recordInventoryEvent,
  archive,
  restore,
  deletePermanently,
}

final class MedicationNotFoundException implements Exception {
  const MedicationNotFoundException(this.medicationId, this.operation);

  final String medicationId;
  final MedicationLifecycleOperation operation;

  @override
  String toString() {
    return 'MedicationNotFoundException('
        'medicationId: $medicationId, operation: ${operation.name})';
  }
}

final class MedicationLifecycleViolation implements Exception {
  const MedicationLifecycleViolation({
    required this.medicationId,
    required this.state,
    required this.operation,
  });

  final String medicationId;
  final MedicationLifecycleState state;
  final MedicationLifecycleOperation operation;

  @override
  String toString() {
    return 'MedicationLifecycleViolation('
        'medicationId: $medicationId, state: ${state.name}, '
        'operation: ${operation.name})';
  }
}

abstract final class MedicationLifecyclePolicy {
  static void ensureCreatable({
    required String medicationId,
    required bool isArchived,
  }) {
    if (isArchived) {
      throw MedicationLifecycleViolation(
        medicationId: medicationId,
        state: MedicationLifecycleState.archived,
        operation: MedicationLifecycleOperation.create,
      );
    }
  }

  static void ensureAllowed({
    required String medicationId,
    required bool? isArchived,
    required MedicationLifecycleOperation operation,
  }) {
    if (isArchived == null) {
      throw MedicationNotFoundException(medicationId, operation);
    }

    final MedicationLifecycleState state = isArchived
        ? MedicationLifecycleState.archived
        : MedicationLifecycleState.active;
    final bool allowed = switch ((state, operation)) {
      (
        MedicationLifecycleState.active,
        MedicationLifecycleOperation.updateDetails ||
            MedicationLifecycleOperation.recordInventoryEvent ||
            MedicationLifecycleOperation.archive ||
            MedicationLifecycleOperation.deletePermanently,
      ) => true,
      (
        MedicationLifecycleState.archived,
        MedicationLifecycleOperation.restore ||
            MedicationLifecycleOperation.deletePermanently,
      ) => true,
      _ => false,
    };

    if (!allowed) {
      throw MedicationLifecycleViolation(
        medicationId: medicationId,
        state: state,
        operation: operation,
      );
    }
  }
}
