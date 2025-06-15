import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          child: budget == null
              ? _buildEmptyBudget(context, themeColor)
              : _buildBudgetContent(context, themeColor),
        ),
      ),
    );
  }

  Widget _buildEmptyBudget(BuildContext context, Color themeColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48.sp,
            color: themeColor.withAlpha((255 * 0.5).toInt()),
          ),
          SizedBox(height: 16.h),
          Text(
            'Set Budget',
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap here to set your monthly budget',
            style: TextStyle(
              fontSize: 14.sp,
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
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: themeColor.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 28.sp,
                color: themeColor,
              ),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Budget',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$currencySymbol${budget!.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Text(
          'Amount left for this month',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: Text(
                '$currencySymbol${remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: statusColor.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                isNegative
                    ? 'Overspent'
                    : isLow
                        ? 'Low Budget'
                        : 'Budget Healthy',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: percentage.clamp(0, 1).toDouble(),
            minHeight: 8.h,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),
        SizedBox(height: 8.h),
        if (!isNegative)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Used ${((1 - percentage) * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ),

        // 添加类别预算详情
        if (budget!.categories.isNotEmpty) ...[
          SizedBox(height: 24.h),
          const Divider(),
          SizedBox(height: 16.h),
          Text(
            'Categories',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
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
          margin: EdgeInsets.only(bottom: 12.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  categoryIcon,
                  size: 18.sp,
                  color: categoryColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$currencySymbol${catBudget.left.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Stack(
                      children: [
                        Container(
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(45.r),
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
