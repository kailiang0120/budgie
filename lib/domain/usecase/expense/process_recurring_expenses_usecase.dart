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
      if (kDebugMode) {
        debugPrint('🔄 Processing recurring expenses...');
      }

      // Get all expenses and filter for those with recurring details
      final allExpenses = await _expensesRepository.getExpenses();
      final recurringExpenses =
          allExpenses.where((expense) => expense.isRecurring).toList();
      final now = DateTime.now();

      for (final expense in recurringExpenses) {
        await _processIndividualRecurringExpense(expense, now);
      }

      if (kDebugMode) {
        debugPrint('✅ Recurring expenses processing completed');
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      if (kDebugMode) {
        debugPrint('❌ Error processing recurring expenses: ${error.message}');
      }
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
        if (kDebugMode) {
          debugPrint(
              '⚠️ Expense ${originalExpense.id} is not recurring or has no recurring details');
        }
        return;
      }

      final recurringDetails = originalExpense.recurringDetails!;

      // Check if this recurring expense has reached its end date
      if (recurringDetails.endDate != null && 
          now.isAfter(recurringDetails.endDate!)) {
        if (kDebugMode) {
          debugPrint(
              '⏰ Recurring expense ${originalExpense.id} has ended on ${recurringDetails.endDate}');
        }
        return;
      }

      // Calculate only NEW occurrences since last processed date
      final newOccurrences = _calculateNewOccurrencesSinceLastProcessed(
        originalExpense,
        recurringDetails,
        now,
      );

      if (newOccurrences.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              '✅ No new occurrences for recurring expense: ${originalExpense.remark}');
        }
        return;
      }

      // Check for potential duplicates before creating expenses
      final existingExpenses = await _expensesRepository.getExpenses();
      final filteredOccurrences = await _filterOutDuplicates(
        newOccurrences,
        originalExpense,
        existingExpenses,
      );

      if (filteredOccurrences.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              '✅ All occurrences for ${originalExpense.remark} already exist as expenses');
        }
        // Still update the last processed date to prevent future duplicate checks
        await _updateLastProcessedDate(originalExpense, newOccurrences.last);
        return;
      }

      // Create expenses for filtered occurrences
      for (final occurrence in filteredOccurrences) {
        await _createExpenseFromRecurring(originalExpense, occurrence);
      }

      // Update the last processed date in the original recurring expense
      await _updateLastProcessedDate(originalExpense, filteredOccurrences.last);

      if (kDebugMode) {
        debugPrint(
            '✅ Processed ${filteredOccurrences.length} new occurrences for recurring expense: ${originalExpense.remark}');
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      if (kDebugMode) {
        debugPrint(
            '❌ Error processing recurring expense ${originalExpense.id}: ${error.message}');
      }
    }
  }

  /// Calculate only NEW occurrence dates since last processed
  List<DateTime> _calculateNewOccurrencesSinceLastProcessed(
    Expense originalExpense,
    RecurringDetails recurringDetails,
    DateTime now,
  ) {
    final occurrences = <DateTime>[];

    // Determine the start date for calculation
    DateTime startDate;
    if (recurringDetails.lastProcessedDate != null) {
      // Start from the day after the last processed date
      startDate = recurringDetails.lastProcessedDate!.add(const Duration(days: 1));
    } else {
      // If never processed, start from the day after the original expense date
      startDate = originalExpense.date.add(const Duration(days: 1));
    }

    // Calculate the first occurrence after start date
    DateTime currentDate = _getNextOccurrence(recurringDetails, startDate.subtract(const Duration(days: 1)));

    while (currentDate.isBefore(now) || _isSameDay(currentDate, now)) {
      // Check if this occurrence should be added
      if (_shouldProcessOccurrence(currentDate, now)) {
        // Additional check: don't include dates that are too far in the past (beyond 1 year)
        final oneYearAgo = now.subtract(const Duration(days: 365));
        if (currentDate.isAfter(oneYearAgo)) {
          occurrences.add(currentDate);
        }
      }

      // Move to next occurrence
      currentDate = _getNextOccurrence(recurringDetails, currentDate);

      // Safety check to prevent infinite loops
      if (occurrences.length > 50) {
        if (kDebugMode) {
          debugPrint('⚠️ Too many new occurrences calculated, stopping at 50');
        }
        break;
      }
    }

    return occurrences;
  }

  /// Filter out duplicate expenses that already exist
  Future<List<DateTime>> _filterOutDuplicates(
    List<DateTime> occurrences,
    Expense originalExpense,
    List<Expense> existingExpenses,
  ) async {
    final filteredOccurrences = <DateTime>[];

    for (final occurrence in occurrences) {
      // Check if an expense with similar details already exists for this date
      final duplicateExists = existingExpenses.any((expense) =>
          _isSameDay(expense.date, occurrence) &&
          expense.remark == originalExpense.remark &&
          expense.amount == originalExpense.amount &&
          expense.category == originalExpense.category &&
          !expense.isRecurring); // Generated expenses should not be recurring

      if (!duplicateExists) {
        filteredOccurrences.add(occurrence);
      } else if (kDebugMode) {
        debugPrint(
            '🔍 Duplicate expense found for ${originalExpense.remark} on ${occurrence.toIso8601String()}, skipping');
      }
    }

    return filteredOccurrences;
  }

  /// Update the last processed date in the original recurring expense
  Future<void> _updateLastProcessedDate(
    Expense originalExpense,
    DateTime lastProcessedDate,
  ) async {
    try {
      // Create updated recurring details with new last processed date
      final updatedRecurringDetails = originalExpense.recurringDetails!.copyWith(
        lastProcessedDate: lastProcessedDate,
      );

      // Create updated expense with new recurring details
      final updatedExpense = originalExpense.copyWith(
        recurringDetails: updatedRecurringDetails,
      );

      // Update the expense in the repository
      await _expensesRepository.updateExpense(updatedExpense);

      if (kDebugMode) {
        debugPrint(
            '✅ Updated last processed date for ${originalExpense.remark} to ${lastProcessedDate.toIso8601String()}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update last processed date: $e');
      }
      // Don't rethrow - this is not critical for the main functionality
    }
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
      if (kDebugMode) {
        debugPrint(
            '✅ Created recurring expense: ${expense.remark} for ${occurrenceDate.toIso8601String()}');
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      if (kDebugMode) {
        debugPrint('❌ Failed to create expense from recurring: ${error.message}');
      }
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
      if (kDebugMode) {
        debugPrint('❌ Error calculating next occurrence: $e');
      }
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
      final occurrences = _calculateNewOccurrencesSinceLastProcessed(
        originalExpense,
        originalExpense.recurringDetails!,
        now,
      );

      return occurrences.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking if due for processing: $e');
      }
      return false;
    }
  }

  /// Get pending occurrences count for a recurring expense (for UI display)
  Future<int> getPendingOccurrencesCount(String expenseId) async {
    try {
      final expenses = await _expensesRepository.getExpenses();
      final originalExpense = expenses.firstWhere(
        (expense) => expense.id == expenseId && expense.isRecurring,
        orElse: () =>
            throw Exception('Recurring expense not found: $expenseId'),
      );

      final now = DateTime.now();
      final newOccurrences = _calculateNewOccurrencesSinceLastProcessed(
        originalExpense,
        originalExpense.recurringDetails!,
        now,
      );

      // Filter out duplicates
      final filteredOccurrences = await _filterOutDuplicates(
        newOccurrences,
        originalExpense,
        expenses,
      );

      return filteredOccurrences.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting pending occurrences count: $e');
      }
      return 0;
    }
  }
}
