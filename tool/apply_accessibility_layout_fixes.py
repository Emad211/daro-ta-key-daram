from pathlib import Path


def replace_once(path_string: str, old: str, new: str) -> None:
    path = Path(path_string)
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected block count 1, got {count}")
    path.write_text(text.replace(old, new))


list_path = (
    "lib/features/medication_inventory/presentation/screens/"
    "medication_list_screen.dart"
)
replace_once(
    list_path,
    """          IconButton(
            tooltip: 'مدیریت آرشیو',
            onPressed: () => context.goNamed('archived-medications'),
            icon: const Icon(Icons.archive_outlined),
          ),
          IconButton(
            tooltip: 'فعال‌کردن یادآوری موجودی',
            onPressed: () => _requestNotificationPermission(context, ref),
            icon: const Icon(Icons.notifications_active_outlined),
          ),
""",
    """          Semantics(
            container: true,
            label: 'مدیریت آرشیو',
            button: true,
            enabled: true,
            onTap: () => context.goNamed('archived-medications'),
            excludeSemantics: true,
            child: IconButton(
              tooltip: 'مدیریت آرشیو',
              onPressed: () => context.goNamed('archived-medications'),
              icon: const Icon(Icons.archive_outlined),
            ),
          ),
          Semantics(
            container: true,
            label: 'فعال‌کردن یادآوری موجودی',
            button: true,
            enabled: true,
            onTap: () => _requestNotificationPermission(context, ref),
            excludeSemantics: true,
            child: IconButton(
              tooltip: 'فعال‌کردن یادآوری موجودی',
              onPressed: () => _requestNotificationPermission(context, ref),
              icon: const Icon(Icons.notifications_active_outlined),
            ),
          ),
""",
)
replace_once(
    list_path,
    """    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
""",
    """    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
""",
)

card_path = (
    "lib/features/medication_inventory/presentation/widgets/medication_card.dart"
)
replace_once(
    card_path,
    """                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyStyle.background,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      snapshot.urgency.persianLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: urgencyStyle.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
""",
    """                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyStyle.background,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    snapshot.urgency.persianLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: urgencyStyle.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
""",
)

details_path = (
    "lib/features/medication_inventory/presentation/screens/"
    "medication_details_screen.dart"
)
replace_once(
    details_path,
    """                IconButton(
                  tooltip: 'ویرایش مشخصات',
                  onPressed: _isArchiveBusy
                      ? null
                      : () => context.goNamed(
                          'edit-medication',
                          pathParameters: <String, String>{
                            'medicationId': medication.id,
                          },
                        ),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  key: Key('archive-${medication.id}'),
                  tooltip: 'آرشیو دارو',
                  onPressed: _isArchiveBusy ? null : _archive,
                  icon: _isArchiving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.archive_outlined),
                ),
""",
    """                Semantics(
                  container: true,
                  label: 'ویرایش مشخصات',
                  button: true,
                  enabled: !_isArchiveBusy,
                  onTap: _isArchiveBusy
                      ? null
                      : () => context.goNamed(
                          'edit-medication',
                          pathParameters: <String, String>{
                            'medicationId': medication.id,
                          },
                        ),
                  excludeSemantics: true,
                  child: IconButton(
                    tooltip: 'ویرایش مشخصات',
                    onPressed: _isArchiveBusy
                        ? null
                        : () => context.goNamed(
                            'edit-medication',
                            pathParameters: <String, String>{
                              'medicationId': medication.id,
                            },
                          ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
                Semantics(
                  container: true,
                  label: 'آرشیو دارو',
                  button: true,
                  enabled: !_isArchiveBusy,
                  onTap: _isArchiveBusy ? null : _archive,
                  excludeSemantics: true,
                  child: IconButton(
                    key: Key('archive-${medication.id}'),
                    tooltip: 'آرشیو دارو',
                    onPressed: _isArchiveBusy ? null : _archive,
                    icon: _isArchiving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.archive_outlined),
                  ),
                ),
""",
)
replace_once(
    details_path,
    """        child: Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: onRestock,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('خرید مجدد'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCorrection,
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('اصلاح موجودی'),
              ),
            ),
          ],
        ),
""",
    """        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FilledButton.icon(
              onPressed: onRestock,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('خرید مجدد'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onCorrection,
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('اصلاح موجودی'),
            ),
          ],
        ),
""",
)

archive_path = (
    "lib/features/medication_inventory/presentation/screens/"
    "archived_medications_screen.dart"
)
replace_once(
    archive_path,
    """                IconButton.filledTonal(
                  key: Key('delete-${medication.id}'),
                  tooltip: 'حذف دائمی',
                  onPressed: isBusy ? null : onDelete,
                  icon: const Icon(Icons.delete_forever_outlined),
                ),
""",
    """                Semantics(
                  container: true,
                  label: 'حذف دائمی',
                  button: true,
                  enabled: !isBusy,
                  onTap: isBusy ? null : onDelete,
                  excludeSemantics: true,
                  child: IconButton.filledTonal(
                    key: Key('delete-${medication.id}'),
                    tooltip: 'حذف دائمی',
                    onPressed: isBusy ? null : onDelete,
                    icon: const Icon(Icons.delete_forever_outlined),
                  ),
                ),
""",
)
