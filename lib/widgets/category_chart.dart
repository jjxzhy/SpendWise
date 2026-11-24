import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({
    super.key,
    required this.categoryTotals,
    this.currencyCode = 'EUR',
  });

  final Map<String, double> categoryTotals;
  final String currencyCode;

  static const List<Color> _chartColors = [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFF97316),
    Color(0xFF9333EA),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFFCA8A04),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals.values.fold(0.0, (sum, item) => sum + item);
    final entries = categoryTotals.entries.toList();

    if (entries.isEmpty || total <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No category spending recorded for this period.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 54,
              sectionsSpace: 3,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value,
                    title:
                        '${((entries[i].value / total) * 100).toStringAsFixed(0)}%',
                    radius: 72,
                    color: _chartColors[i % _chartColors.length],
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            for (var i = 0; i < entries.length; i++)
              _LegendItem(
                color: _chartColors[i % _chartColors.length],
                label: entries[i].key,
                value: CurrencyFormatter.format(
                  entries[i].value,
                  currencyCode: currencyCode,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label $value'),
      ],
    );
  }
}
