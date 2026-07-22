from pathlib import Path


def replace_once(path_string: str, old: str, new: str) -> None:
    path = Path(path_string)
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected block count 1, got {count}")
    path.write_text(text.replace(old, new))


replace_once(
    "lib/app/app.dart",
    """      supportedLocales: const <Locale>[Locale('fa', 'IR'), Locale('en', 'US')],
""",
    """      supportedLocales: const <Locale>[Locale('fa', 'IR')],
""",
)

replace_once(
    "lib/features/privacy/presentation/privacy_center_screen.dart",
    """          const _AdvertisingBoundaryCard(),
          const SizedBox(height: 18),
          _DataDeletionCard(
""",
    """          const _AdvertisingBoundaryCard(),
          const SizedBox(height: 12),
          const _OpenSourceLicensesCard(),
          const SizedBox(height: 18),
          _DataDeletionCard(
""",
)

replace_once(
    "lib/features/privacy/presentation/privacy_center_screen.dart",
    """class _InfoCard extends StatelessWidget {
""",
    """class _OpenSourceLicensesCard extends StatelessWidget {
  const _OpenSourceLicensesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.code_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('مجوزهای متن‌باز'),
        subtitle: const Text(
          'فهرست کتابخانه‌های استفاده‌شده و متن مجوزهای آن‌ها',
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          showLicensePage(
            context: context,
            applicationName: 'دارو تا کی دارم؟',
            applicationVersion: '۱.۰.۰',
            applicationLegalese: '© ۲۰۲۶ — تمامی حقوق محفوظ است.',
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
""",
)
