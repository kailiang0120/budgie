import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/category_manager.dart';

class ExpensePieChart extends StatelessWidget {
  // Updated to accept string category IDs
  final Map<String, double> data;

  const ExpensePieChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<double>(0, (sum, v) => sum + v);
    return PieChart(
      PieChartData(
        sections: data.entries.map((entry) {
          final categoryId = entry.key;
          final percent = total > 0 ? (entry.value / total * 100) : 0;
          return PieChartSectionData(
            value: entry.value,
            title: '${percent.toStringAsFixed(0)}%',
            color: CategoryManager.getColor(categoryId),
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}
