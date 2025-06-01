import 'package:flutter/material.dart';
import '../../domain/entities/budget.dart';
import '../utils/category_manager.dart';
import '../utils/currency_formatter.dart';

class BudgetCard extends StatelessWidget {
  final Budget? budget;
  final VoidCallback onTap;

  const BudgetCard({required this.budget, required this.onTap, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFF57C00);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withAlpha((255 * 0.1).toInt()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: budget == null
              ? _buildEmptyBudget(themeColor)
              : _buildBudgetContent(context, themeColor),
        ),
      ),
    );
  }

  Widget _buildEmptyBudget(Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: themeColor.withAlpha((255 * 0.5).toInt()),
          ),
          const SizedBox(height: 16),
          const Text(
            'Set Budget',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap here to set your monthly budget',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetContent(BuildContext context, Color themeColor) {
    final remaining = budget!.left;
    final percentage = budget!.total > 0 ? (remaining / budget!.total) : 0;
    final isLow = percentage < 0.3 && percentage > 0;
    final isNegative = remaining <= 0;
    final currencySymbol =
        CurrencyFormatter.getCurrencySymbol(budget!.currency);

    final statusColor = isNegative
        ? Colors.red
        : isLow
            ? Colors.orange
            : Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 28,
                color: themeColor,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Budget',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currencySymbol${budget!.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Amount left for this month',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '$currencySymbol${remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isNegative
                    ? 'Overspent'
                    : isLow
                        ? 'Low Budget'
                        : 'Budget Healthy',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage.clamp(0, 1).toDouble(),
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),
        const SizedBox(height: 8),
        if (!isNegative)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Used ${((1 - percentage) * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),

        // 添加类别预算详情
        if (budget!.categories.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryList(),
        ],
      ],
    );
  }

  Widget _buildCategoryList() {
    final categories = budget!.categories.entries.toList();
    final currencySymbol =
        CurrencyFormatter.getCurrencySymbol(budget!.currency);

    // 按剩余预算百分比排序（从低到高）
    categories.sort((a, b) {
      final percentA = a.value.left / a.value.budget;
      final percentB = b.value.left / b.value.budget;
      return percentA.compareTo(percentB);
    });

    return Column(
      children: categories.map((entry) {
        final catId = entry.key;
        final catBudget = entry.value;

        // 尝试获取类别信息
        final category = CategoryManager.getCategoryFromId(catId);
        final categoryIcon = category != null
            ? CategoryManager.getIcon(category)
            : Icons.category;
        final categoryColor =
            category != null ? CategoryManager.getColor(category) : Colors.grey;
        final categoryName =
            category != null ? CategoryManager.getName(category) : catId;

        // 计算百分比
        final percentage = catBudget.budget > 0
            ? (catBudget.left / catBudget.budget).clamp(0.0, 1.0)
            : 0.0;

        // 状态颜色
        final statusColor = catBudget.left <= 0
            ? Colors.red
            : percentage < 0.3
                ? Colors.orange
                : Colors.green.shade700;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  categoryIcon,
                  size: 18,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$currencySymbol${catBudget.left.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
