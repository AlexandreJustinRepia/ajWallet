import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryPercentages;

  const CategoryPieChart({
    super.key,
    required this.categoryPercentages,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryPercentages.isEmpty) {
      return Center(
        child: Text(
          'No expense data yet',
          style: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
        ),
      );
    }

    final theme = Theme.of(context);
    
    // Premium Botanical palette
    final List<Color> colors = [
      const Color(0xFF1B5E20), // Deep Green
      const Color(0xFF2E7D32), // Forest Green
      const Color(0xFF43A047), // Material Green
      const Color(0xFF66BB6A), // Light Green
      const Color(0xFF81C784), // Pastel Green
      const Color(0xFFA5D6A7), // Soft Green
    ];

    final sections = categoryPercentages.entries.toList();
    sections.sort((a, b) => b.value.compareTo(a.value)); // Sort by size

    // Take top 5 and group others
    final List<PieChartSectionData> chartSections = [];
    double othersValue = 0;

    for (int i = 0; i < sections.length; i++) {
      if (i < 5) {
        chartSections.add(
          PieChartSectionData(
            color: colors[i % colors.length],
            value: sections[i].value,
            title: '${sections[i].value.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      } else {
        othersValue += sections[i].value;
      }
    }

    if (othersValue > 0) {
      chartSections.add(
        PieChartSectionData(
          color: Colors.grey.withValues(alpha: 0.3),
          value: othersValue,
          title: '...',
          radius: 45,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: chartSections,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Custom Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(chartSections.length, (index) {
            final isOthers = index == 5 && othersValue > 0;
            final label = isOthers ? 'Others' : sections[index].key;
            final color = isOthers ? Colors.grey.withValues(alpha: 0.3) : colors[index % colors.length];
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
