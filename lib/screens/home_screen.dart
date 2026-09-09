import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/category_utils.dart';
import '../utils/currency_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  ExpensePeriod _selectedPeriod = ExpensePeriod.allTime;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
      _selectedPeriod = ExpensePeriod.allTime;
    });
  }

  Future<void> _openEditExpense(Expense expense) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Edit Expense')),
          body: SafeArea(
            child: AddExpenseScreen(onSaved: () {}, expense: expense),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final provider = context.read<ExpenseProvider>();
    try {
      await provider.deleteExpense(expense.id);
      HapticFeedback.selectionClick();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await provider.restoreExpense(expense);
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Expense restored')));
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete expense. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpenseProvider, SettingsProvider>(
      builder: (context, expenseProvider, settingsProvider, _) {
        final filteredExpenses = expenseProvider.filteredExpenses(
          searchQuery: _searchController.text,
          category: _selectedCategory,
          period: _selectedPeriod,
        );
        final hasFilters =
            _searchController.text.trim().isNotEmpty ||
            _selectedCategory != 'All' ||
            _selectedPeriod != ExpensePeriod.allTime;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Here is your spending overview.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _BudgetCard(
                      spent: expenseProvider.currentMonthTotal,
                      budget: settingsProvider.monthlyBudget,
                      currencyCode: settingsProvider.currencyCode,
                    ),
                    const SizedBox(height: 14),
                    _SummaryGrid(
                      provider: expenseProvider,
                      budget: settingsProvider.monthlyBudget,
                      currencyCode: settingsProvider.currencyCode,
                    ),
                    const SizedBox(height: 22),
                    _SearchAndFilters(
                      controller: _searchController,
                      selectedCategory: _selectedCategory,
                      selectedPeriod: _selectedPeriod,
                      onChanged: () => setState(() {}),
                      onCategoryChanged: (category) =>
                          setState(() => _selectedCategory = category),
                      onPeriodChanged: (period) =>
                          setState(() => _selectedPeriod = period),
                      onClear: _clearFilters,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent expenses',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (hasFilters)
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.filter_alt_off_outlined),
                            label: const Text('Clear'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (expenseProvider.expenses.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No expenses yet',
                  message: 'Tap Add to record your first expense.',
                ),
              )
            else if (filteredExpenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'No matching expenses',
                  message: 'Try a different search or clear your filters.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                sliver: SliverList.builder(
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];
                    return Dismissible(
                      key: ValueKey(expense.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      onDismissed: (_) => _deleteExpense(expense),
                      child: ExpenseCard(
                        expense: expense,
                        currencyCode: settingsProvider.currencyCode,
                        onEdit: () => _openEditExpense(expense),
                        onDelete: () => _deleteExpense(expense),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.spent,
    required this.budget,
    required this.currencyCode,
  });

  final double spent;
  final double budget;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = budget <= 0 ? 0.0 : spent / budget;
    final remaining = budget - spent;
    final progressColor = percent >= 0.9
        ? colorScheme.error
        : percent >= 0.7
        ? Colors.orange.shade700
        : colorScheme.primary;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: const Icon(Icons.savings_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Monthly overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              CurrencyFormatter.format(spent, currencyCode: currencyCode),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'of ${CurrencyFormatter.format(budget, currencyCode: currencyCode)} budget',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: LinearProgressIndicator(
                value: percent.clamp(0, 1).toDouble(),
                color: progressColor,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.55),
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BudgetMetric(
                    label: 'Remaining',
                    value: CurrencyFormatter.format(
                      remaining,
                      currencyCode: currencyCode,
                    ),
                  ),
                ),
                Expanded(
                  child: _BudgetMetric(
                    label: 'Used',
                    value: '${(percent * 100).toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.72))),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.provider,
    required this.budget,
    required this.currencyCode,
  });

  final ExpenseProvider provider;
  final double budget;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final remaining = budget - provider.currentMonthTotal;
    final cards = [
      _SummaryItem(
        icon: Icons.payments_outlined,
        label: 'Spent this month',
        value: CurrencyFormatter.format(
          provider.currentMonthTotal,
          currencyCode: currencyCode,
        ),
      ),
      _SummaryItem(
        icon: Icons.receipt_long_outlined,
        label: 'Transactions',
        value: provider.currentMonthTransactionCount.toString(),
      ),
      _SummaryItem(
        icon: Icons.trending_up_outlined,
        label: 'Daily average',
        value: CurrencyFormatter.format(
          provider.currentMonthDailyAverage,
          currencyCode: currencyCode,
        ),
      ),
      _SummaryItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Remaining',
        value: CurrencyFormatter.format(remaining, currencyCode: currencyCode),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 4 ? 1.55 : 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const Spacer(),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.controller,
    required this.selectedCategory,
    required this.selectedPeriod,
    required this.onChanged,
    required this.onCategoryChanged,
    required this.onPeriodChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String selectedCategory;
  final ExpensePeriod selectedPeriod;
  final VoidCallback onChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<ExpensePeriod> onPeriodChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: 'Search expenses',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in CategoryUtils.filterOptions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    avatar: category == 'All'
                        ? const Icon(Icons.all_inclusive, size: 18)
                        : Icon(CategoryUtils.iconFor(category), size: 18),
                    selected: selectedCategory == category,
                    onSelected: (_) => onCategoryChanged(category),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<ExpensePeriod>(
          initialValue: selectedPeriod,
          decoration: const InputDecoration(
            labelText: 'Date period',
            prefixIcon: Icon(Icons.date_range_outlined),
          ),
          items: ExpensePeriod.values
              .map(
                (period) =>
                    DropdownMenuItem(value: period, child: Text(period.label)),
              )
              .toList(),
          onChanged: (period) {
            if (period != null) {
              onPeriodChanged(period);
            }
          },
        ),
      ],
    );
  }
}
