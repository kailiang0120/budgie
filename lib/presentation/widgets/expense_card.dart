import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense.dart';
import '../utils/category_manager.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: CategoryManager.getColor(expense.category),
          child: Icon(
            CategoryManager.getIcon(expense.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          expense.remark,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${dateFormat.format(expense.date)} at ${timeFormat.format(expense.date)}',
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              expense.method == PaymentMethod.creditCard
                  ? 'Credit Card'
                  : 'Cash',
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
