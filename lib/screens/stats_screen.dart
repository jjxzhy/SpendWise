import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_chart.dart';
import '../widgets/empty_state.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpenseProvider, SettingsProvider>(
      builder: (context, expenseProvider, settingsProvider, _) {
        final expenses = expenseProvider.expenses;
        final currencyCode = settingsProvider.currencyCode;

        if (expenses.isEmpty) {
          return const EmptyState(
            icon: Icons.pie_chart_outline,
            title: 'No statistics yet',
            message: 'Add expenses to unlock category and monthly insights.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
          children: [
            Text(
              'Statistics',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Current spending patterns and simple insights.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _MetricGrid(provider: expenseProvider, currencyCode: currencyCode),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Current-month category breakdown',
              child: CategoryChart(
                categoryTotals: expenseProvider.currentMonthExpensesByCategory,
                currencyCode: currencyCode,
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'This week',
              child: _WeeklyBarChart(
                totals: expenseProvider.weeklyTotals,
                currencyCode: currencyCode,
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Six-month trend',
              child: _MonthlyTrendChart(
                totals: expenseProvider.monthlyExpenses,
                currencyCode: currencyCode,
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Spending insights',
              child: _InsightsList(
                provider: expenseProvider,
                budget: settingsProvider.monthlyBudget,
                currencyCode: currencyCode,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.provider, required this.currencyCode});

  final ExpenseProvider provider;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final highest = provider.highestExpense;
    final items = [
      _MetricItem(
        icon: Icons.category_outlined,
        label: 'Highest category',
        value: provider.highestCategory ?? 'No data',
      ),
      _MetricItem(
        icon: Icons.arrow_upward_outlined,
        label: 'Highest expense',
        value: highest == null
            ? 'No data'
            : CurrencyFormatter.format(
                highest.amount,
                currencyCode: currencyCode,
              ),
      ),
      _MetricItem(
        icon: Icons.receipt_long_outlined,
        label: 'Transactions',
        value: provider.expenses.length.toString(),
      ),
      _MetricItem(
        icon: Icons.calculate_outlined,
        label: 'Average',
        value: CurrencyFormatter.format(
          provider.averageTransactionAmount,
          currencyCode: currencyCode,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 4 ? 1.55 : 1.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: items,
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
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
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.totals, required this.currencyCode});

  final Map<String, double> totals;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final entries = totals.entries.toList();
    final maxValue = entries.fold(0.0, (max, entry) {
      return entry.value > max ? entry.value : max;
    });

    if (maxValue == 0) {
      return const _MiniEmpty(message: 'No spending recorded this week.');
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.25,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(entries[index].key),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  CurrencyFormatter.format(rod.toY, currencyCode: currencyCode),
                  TextStyle(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].value,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.totals, required this.currencyCode});

  final Map<String, double> totals;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final entries = totals.entries.toList();
    final maxValue = entries.fold(0.0, (max, entry) {
      return entry.value > max ? entry.value : max;
    });

    if (maxValue == 0) {
      return const _MiniEmpty(message: 'No monthly trend is available yet.');
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxValue * 1.25,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(entries[index].key.split(' ').first),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    CurrencyFormatter.format(
                      spot.y,
                      currencyCode: currencyCode,
                    ),
                    TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 4,
              color: Theme.of(context).colorScheme.primary,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.14),
              ),
              spots: [
                for (var i = 0; i < entries.length; i++)
                  FlSpot(i.toDouble(), entries[i].value),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsList extends StatelessWidget {
  const _InsightsList({
    required this.provider,
    required this.budget,
    required this.currencyCode,
  });

  final ExpenseProvider provider;
  final double budget;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();
    return Column(
      children: [
        for (final insight in insights)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lightbulb_outline),
            title: Text(insight),
          ),
      ],
    );
  }

  List<String> _buildInsights() {
    final current = provider.currentMonthTotal;
    final previous = provider.previousMonthTotal;
    final highestCategory = provider.highestCategory;
    final highestExpense = _highestCurrentMonthExpense();
    final budgetPercent = budget <= 0 ? 0.0 : (current / budget) * 100;
    final insights = <String>[];

    if (highestCategory != null) {
      insights.add(
        '$highestCategory is your highest spending category this month.',
      );
    }
    if (previous > 0) {
      final difference = current - previous;
      final percent = (difference.abs() / previous) * 100;
      final formatted = CurrencyFormatter.format(
        difference.abs(),
        currencyCode: currencyCode,
      );
      if (difference >= 0) {
        insights.add('You spent $formatted more than last month.');
      } else {
        insights.add(
          'Your spending is ${percent.toStringAsFixed(0)}% lower than last month.',
        );
      }
    } else if (current > 0) {
      insights.add('This is your first month with recorded spending.');
    }
    if (highestExpense != null) {
      insights.add(
        'Your largest expense this month was ${highestExpense.title}.',
      );
    }
    if (budget > 0) {
      insights.add(
        'You have used ${budgetPercent.toStringAsFixed(0)}% of your monthly budget.',
      );
    } else {
      insights.add(
        'Set a monthly budget in Settings to track your budget usage.',
      );
    }

    return insights;
  }

  Expense? _highestCurrentMonthExpense() {
    final expenses = provider.currentMonthExpenses;
    if (expenses.isEmpty) {
      return null;
    }
    return expenses.reduce(
      (current, next) => current.amount >= next.amount ? current : next,
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
