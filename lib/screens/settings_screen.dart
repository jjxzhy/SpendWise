import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_formatter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _budgetController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _syncBudgetField(context.read<SettingsProvider>().monthlyBudget);
      _initialized = true;
    }
  }

  void _syncBudgetField(double budget) {
    _budgetController.text = budget > 0 ? budget.toStringAsFixed(2) : '';
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final raw = _budgetController.text.trim().replaceAll(',', '.');
    final value = raw.isEmpty ? 0.0 : double.tryParse(raw);
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid non-negative budget amount'),
        ),
      );
      return;
    }

    try {
      await context.read<SettingsProvider>().saveMonthlyBudget(value);
      if (!mounted) {
        return;
      }
      _syncBudgetField(value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value > 0 ? 'Budget saved' : 'Monthly budget cleared'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save budget. Try again.')),
      );
    }
  }

  Future<void> _deleteAllExpenses() async {
    final confirmed = await _confirm(
      title: 'Delete all expenses?',
      message:
          'This permanently removes every recorded expense from local storage. '
          'Your budget, currency, and theme preferences will be kept.',
      actionLabel: 'Delete expenses',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await context.read<ExpenseProvider>().clearAllExpenses();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All expenses deleted')));
  }

  Future<void> _resetAllData() async {
    final confirmed = await _confirm(
      title: 'Reset all data?',
      message:
          'This permanently wipes all expenses, your monthly budget, currency, '
          'and theme preferences from local/browser storage and resets '
          'SpendWise to a fresh state.',
      actionLabel: 'Reset everything',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    final expenseProvider = context.read<ExpenseProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    await expenseProvider.clearAllExpenses();
    await settingsProvider.resetAllSettings();

    if (!mounted) {
      return;
    }
    _syncBudgetField(settingsProvider.monthlyBudget);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data has been reset to a fresh state')),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        )
                      : null,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(actionLabel),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
          children: [
            Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage your budget, appearance, and local data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _SettingsCard(
              title: 'Monthly budget',
              icon: Icons.savings_outlined,
              child: Column(
                children: [
                  TextField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Budget',
                      hintText: '0.00',
                      prefixText:
                          '${CurrencyFormatter.symbolFor(settingsProvider.currencyCode)} ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveBudget,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save budget'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SettingsCard(
              title: 'Currency',
              icon: Icons.payments_outlined,
              child: DropdownButtonFormField<String>(
                key: ValueKey(settingsProvider.currencyCode),
                initialValue: settingsProvider.currencyCode,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: CurrencyFormatter.symbols.keys
                    .map(
                      (code) => DropdownMenuItem(
                        value: code,
                        child: Text(
                          '$code (${CurrencyFormatter.symbolFor(code)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value == null) {
                    return;
                  }
                  await settingsProvider.saveCurrencyCode(value);
                },
              ),
            ),
            const SizedBox(height: 14),
            _SettingsCard(
              title: 'Theme',
              icon: Icons.dark_mode_outlined,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark'),
                  ),
                ],
                selected: {settingsProvider.themeMode},
                onSelectionChanged: (selection) {
                  settingsProvider.saveThemeMode(selection.first);
                },
              ),
            ),
            const SizedBox(height: 14),
            _SettingsCard(
              title: 'Data management',
              icon: Icons.storage_outlined,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleteAllExpenses,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Delete all expenses'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                      ),
                      onPressed: _resetAllData,
                      icon: const Icon(Icons.restart_alt_outlined),
                      label: const Text('Reset All Data'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SettingsCard(
              title: 'About SpendWise',
              icon: Icons.info_outline,
              child: const Text(
                'SpendWise is a student expense tracker that works completely '
                'offline. It helps students save expenses, review recent '
                'spending, and understand category totals with clear statistics.',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
