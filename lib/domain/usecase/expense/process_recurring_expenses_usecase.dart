import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../entities/expense.dart';
import '../../entities/recurring_expense.dart';

import '../../repositories/expenses_repository.dart';
import '../../../data/infrastructure/errors/app_error.dart';

/// Use case for processing recurring expenses and generating automatic expenses
class ProcessRecurringExpensesUseCase {
  final ExpensesRepository _expensesRepository;

  ProcessRecurringExpensesUseCase({
    required ExpensesRepository expensesRepository,
  }) : _expensesRepository = expensesRepository;

  /// Manually trigger processing of recurring expenses
  Future<void> execute() async {
    await _processRecurringExpenses();
  }

  /// Internal method to process all expenses with recurring details
  Future<void> _processRecurringExpenses() async {
    try {
      debugPrint('🔄 Processing recurring expenses...');

      // Get all expenses and filter for those with recurring details
      final allExpenses = await _expensesRepository.getExpenses();
      final recurringExpenses =
          allExpenses.where((expense) => expense.isRecurring).toList();
      final now = DateTime.now();

      for (final expense in recurringExpenses) {
        await _processIndividualRecurringExpense(expense, now);
      }

      debugPrint('✅ Recurring expenses processing completed');
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      debugPrint('❌ Error processing recurring expenses: ${error.message}');
    }
  }

  /// Process an individual recurring expense
  Future<void> _processIndividualRecurringExpense(
    Expense originalExpense,
    DateTime now,
  ) async {
    try {
      if (!originalExpense.isRecurring ||
          originalExpense.recurringDetails == null) {
        debugPrint(
            '⚠️ Expense ${originalExpense.id} is not recurring or has no recurring details');
        return;
      }

      final recurringDetails = originalExpense.recurringDetails!;

      // Calculate the next occurrence dates that need to be processed
      final occurrences = _calculateOccurrencesSinceLastProcessed(
        originalExpense,
        recurringDetails,
        now,
      );

      for (final occurrence in occurrences) {
        await _createExpenseFromRecurring(originalExpense, occurrence);
      }

      if (occurrences.isNotEmpty) {
        debugPrint(
            '✅ Processed ${occurrences.length} occurrences for recurring expense: ${originalExpense.remark}');
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      debugPrint(
          '❌ Error processing recurring expense ${originalExpense.id}: ${error.message}');
    }
  }

  /// Calculate all occurrence dates since last processed
  List<DateTime> _calculateOccurrencesSinceLastProcessed(
    Expense originalExpense,
    RecurringDetails recurringDetails,
    DateTime now,
  ) {
    final occurrences = <DateTime>[];

    // Start from the original expense date
    DateTime currentDate = originalExpense.date;

    // Move to the next occurrence after the original date
    currentDate = _getNextOccurrence(recurringDetails, currentDate);

    while (currentDate.isBefore(now) || _isSameDay(currentDate, now)) {
      // Check if this occurrence should be added
      if (_shouldProcessOccurrence(currentDate, now)) {
        occurrences.add(currentDate);
      }

      // Move to next occurrence
      currentDate = _getNextOccurrence(recurringDetails, currentDate);

      // Safety check to prevent infinite loops
      if (occurrences.length > 100) {
        debugPrint('⚠️ Too many occurrences calculated, stopping at 100');
        break;
      }
    }

    return occurrences;
  }

  /// Determine if an occurrence should be processed
  bool _shouldProcessOccurrence(
    DateTime occurrence,
    DateTime now,
  ) {
    // Don't process future occurrences
    if (occurrence.isAfter(now)) {
      return false;
    }

    // Only process occurrences that are today or in the past
    return true;
  }

  /// Get the next occurrence date based on frequency
  DateTime _getNextOccurrence(
      RecurringDetails recurringDetails, DateTime currentDate) {
    switch (recurringDetails.frequency) {
      case RecurringFrequency.weekly:
        return _getNextWeeklyOccurrence(recurringDetails, currentDate);
      case RecurringFrequency.monthly:
        return _getNextMonthlyOccurrence(recurringDetails, currentDate);
    }
  }

  /// Calculate next weekly occurrence
  DateTime _getNextWeeklyOccurrence(
      RecurringDetails recurringDetails, DateTime currentDate) {
    if (recurringDetails.dayOfWeek == null) {
      throw Exception('Day of week is required for weekly recurring expenses');
    }

    return _getNextDateForWeekday(
        currentDate, recurringDetails.dayOfWeek!.weekday);
  }

  /// Calculate next monthly occurrence
  DateTime _getNextMonthlyOccurrence(
      RecurringDetails recurringDetails, DateTime currentDate) {
    if (recurringDetails.dayOfMonth == null) {
      throw Exception(
          'Day of month is required for monthly recurring expenses');
    }

    return _getNextDateForDayOfMonth(currentDate, recurringDetails.dayOfMonth!);
  }

  /// Get next date for a specific weekday
  DateTime _getNextDateForWeekday(DateTime currentDate, int targetWeekday) {
    int daysToAdd = (targetWeekday - currentDate.weekday + 7) % 7;
    if (daysToAdd == 0) {
      daysToAdd = 7; // Move to next week if it's the same weekday
    }
    return currentDate.add(Duration(days: daysToAdd));
  }

  /// Get next date for a specific day of month
  DateTime _getNextDateForDayOfMonth(DateTime currentDate, int targetDay) {
    // Try next month first
    DateTime nextMonth = DateTime(currentDate.year, currentDate.month + 1, 1);

    // Get the last day of next month
    DateTime lastDayOfNextMonth =
        DateTime(nextMonth.year, nextMonth.month + 1, 0);

    // Use target day or last day of month if target doesn't exist
    int dayToUse = targetDay <= lastDayOfNextMonth.day
        ? targetDay
        : lastDayOfNextMonth.day;

    DateTime nextOccurrence =
        DateTime(nextMonth.year, nextMonth.month, dayToUse);

    // If the calculated date is before or same as current date, try the month after
    if (nextOccurrence.isBefore(currentDate) ||
        _isSameDay(nextOccurrence, currentDate)) {
      nextMonth = DateTime(currentDate.year, currentDate.month + 2, 1);
      lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0);
      dayToUse = targetDay <= lastDayOfNextMonth.day
          ? targetDay
          : lastDayOfNextMonth.day;
      nextOccurrence = DateTime(nextMonth.year, nextMonth.month, dayToUse);
    }

    return nextOccurrence;
  }

  /// Create an expense from a recurring expense template
  Future<void> _createExpenseFromRecurring(
    Expense originalExpense,
    DateTime occurrenceDate,
  ) async {
    try {
      final expense = Expense(
        id: '', // Let repository assign ID
        remark: originalExpense.remark,
        amount: originalExpense.amount,
        date: occurrenceDate,
        category: originalExpense.category,
        method: originalExpense.method,
        description: originalExpense.description,
        currency: originalExpense.currency,
        recurringDetails:
            null, // Generated expenses are not recurring themselves
      );

      await _expensesRepository.addExpense(expense);
      debugPrint(
          '✅ Created recurring expense: ${expense.remark} for ${occurrenceDate.toIso8601String()}');
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      debugPrint('❌ Failed to create expense from recurring: ${error.message}');
      rethrow;
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Calculate the next occurrence date for a recurring expense (public method for UI)
  Future<DateTime?> calculateNextOccurrence(String expenseId) async {
    try {
      final expenses = await _expensesRepository.getExpenses();
      final originalExpense = expenses.firstWhere(
        (expense) => expense.id == expenseId && expense.isRecurring,
        orElse: () =>
            throw Exception('Recurring expense not found: $expenseId'),
      );

      return _getNextOccurrence(
          originalExpense.recurringDetails!, originalExpense.date);
    } catch (e) {
      debugPrint('❌ Error calculating next occurrence: $e');
      return null;
    }
  }

  /// Check if a recurring expense is due for processing
  Future<bool> isDueForProcessing(String expenseId) async {
    try {
      final expenses = await _expensesRepository.getExpenses();
      final originalExpense = expenses.firstWhere(
        (expense) => expense.id == expenseId && expense.isRecurring,
        orElse: () =>
            throw Exception('Recurring expense not found: $expenseId'),
      );

      final now = DateTime.now();
      final occurrences = _calculateOccurrencesSinceLastProcessed(
        originalExpense,
        originalExpense.recurringDetails!,
        now,
      );

      return occurrences.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking if due for processing: $e');
      return false;
    }
  }
}
