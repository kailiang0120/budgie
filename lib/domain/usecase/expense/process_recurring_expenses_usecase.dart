import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../entities/expense.dart';
import '../../entities/recurring_expense.dart';
import '../../entities/category.dart';

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

      // Get all expenses and stabilise recurring templates before processing
      final allExpenses = await _expensesRepository.getExpenses();
      await _stabilizeRecurringTemplates(allExpenses);

      // Reload after stabilisation so we work with the latest state
      final refreshedExpenses = await _expensesRepository.getExpenses();
      final recurringExpenses = refreshedExpenses
          .where((expense) => expense.isRecurring)
          .toList();
      final now = DateTime.now();
      final existingExpenses = List<Expense>.from(refreshedExpenses);

      for (final expense in recurringExpenses) {
        await _processIndividualRecurringExpense(
          expense,
          now,
          existingExpenses,
        );
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

  Future<void> _stabilizeRecurringTemplates(List<Expense> allExpenses) async {
    final Map<_RecurringTemplateKey, List<Expense>> groupedTemplates = {};

    for (final expense in allExpenses) {
      if (!expense.isRecurring || expense.recurringDetails == null) {
        continue;
      }

      final key = _RecurringTemplateKey.fromExpense(expense);
      groupedTemplates.putIfAbsent(key, () => <Expense>[]).add(expense);
    }

    for (final entry in groupedTemplates.entries) {
      final templates = entry.value;
      if (templates.length <= 1) {
        continue;
      }

      templates.sort((a, b) {
        final dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) {
          return dateComparison;
        }

        final aProcessed = a.recurringDetails!.lastProcessedDate;
        final bProcessed = b.recurringDetails!.lastProcessedDate;

        if (aProcessed != null && bProcessed != null) {
          final processedComparison = aProcessed.compareTo(bProcessed);
          if (processedComparison != 0) {
            return processedComparison;
          }
        } else if (aProcessed != null) {
          return 1;
        } else if (bProcessed != null) {
          return -1;
        }

        return a.id.compareTo(b.id);
      });

      final canonical = templates.first;
      final latestProcessed = templates
          .map((expense) => expense.recurringDetails!.lastProcessedDate)
          .whereType<DateTime>()
          .fold<DateTime?>(
              canonical.recurringDetails!.lastProcessedDate, (current, next) {
        if (current == null || next.isAfter(current)) {
          return next;
        }
        return current;
      });

      if (latestProcessed != null) {
        await _updateLastProcessedDate(canonical, latestProcessed);
      }

      for (final duplicate in templates.skip(1)) {
        if (duplicate.recurringDetails != null) {
          final cleanedDuplicate =
              duplicate.copyWith(clearRecurringDetails: true);
          await _expensesRepository.updateExpense(cleanedDuplicate);
        }
      }
    }
  }

  /// Process an individual recurring expense
  Future<void> _processIndividualRecurringExpense(
    Expense originalExpense,
    DateTime now,
    List<Expense> existingExpenses,
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
      final filteredOccurrences = _filterOutDuplicates(
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
        final updated = await _updateLastProcessedDate(
          originalExpense,
          newOccurrences.last,
        );
        if (updated != null) {
          _replaceExpenseInCache(existingExpenses, updated);
        }
        return;
      }

      // Create expenses for filtered occurrences
      for (final occurrence in filteredOccurrences) {
        await _createExpenseFromRecurring(originalExpense, occurrence);
      }

      // Update the last processed date in the original recurring expense
      final updated = await _updateLastProcessedDate(
        originalExpense,
        filteredOccurrences.last,
      );
      if (updated != null) {
        _replaceExpenseInCache(existingExpenses, updated);
      }

      await _refreshExistingExpenses(existingExpenses);

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
  List<DateTime> _filterOutDuplicates(
    List<DateTime> occurrences,
    Expense originalExpense,
    List<Expense> existingExpenses,
  ) {
    final filteredOccurrences = <DateTime>[];

    for (final occurrence in occurrences) {
      final duplicateExists = existingExpenses.any((expense) =>
          expense.id != originalExpense.id &&
          _isSameDay(expense.date, occurrence) &&
          expense.remark == originalExpense.remark &&
          expense.amount == originalExpense.amount &&
          expense.category == originalExpense.category &&
          expense.method == originalExpense.method &&
          expense.currency == originalExpense.currency &&
          expense.description == originalExpense.description);

      if (!duplicateExists) {
        filteredOccurrences.add(occurrence);
      } else if (kDebugMode) {
        debugPrint(
            '🔍 Duplicate expense found for ${originalExpense.remark} on ${occurrence.toIso8601String()}, skipping');
      }
    }

    return filteredOccurrences;
  }

  void _replaceExpenseInCache(List<Expense> cache, Expense updatedExpense) {
    final index = cache.indexWhere((expense) => expense.id == updatedExpense.id);
    if (index == -1) {
      cache.add(updatedExpense);
      return;
    }
    cache[index] = updatedExpense;
  }

  Future<void> _refreshExistingExpenses(List<Expense> cache) async {
    final refreshedExpenses = await _expensesRepository.getExpenses();
    cache
      ..clear()
      ..addAll(refreshedExpenses);
  }

  /// Update the last processed date in the original recurring expense
  Future<Expense?> _updateLastProcessedDate(
    Expense originalExpense,
    DateTime lastProcessedDate,
  ) async {
    try {
      final existingDetails = originalExpense.recurringDetails!;
      final currentLastProcessed = existingDetails.lastProcessedDate;

      if (currentLastProcessed != null) {
        if (_isSameDay(currentLastProcessed, lastProcessedDate) ||
            currentLastProcessed.isAfter(lastProcessedDate)) {
          return null;
        }
      }

      // Create updated recurring details with new last processed date
      final updatedRecurringDetails = existingDetails.copyWith(
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
      return updatedExpense;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update last processed date: $e');
      }
      // Don't rethrow - this is not critical for the main functionality
      return null;
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
      final filteredOccurrences = _filterOutDuplicates(
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

class _RecurringTemplateKey {
  final String remark;
  final double amount;
  final String categoryId;
  final PaymentMethod method;
  final String currency;
  final String? description;
  final RecurringFrequency frequency;
  final int? dayOfMonth;
  final DayOfWeek? dayOfWeek;
  final DateTime? endDate;

  const _RecurringTemplateKey({
    required this.remark,
    required this.amount,
    required this.categoryId,
    required this.method,
    required this.currency,
    required this.description,
    required this.frequency,
    required this.dayOfMonth,
    required this.dayOfWeek,
    required this.endDate,
  });

  factory _RecurringTemplateKey.fromExpense(Expense expense) {
    final details = expense.recurringDetails!;
    return _RecurringTemplateKey(
      remark: expense.remark,
      amount: expense.amount,
      categoryId: expense.category.id,
      method: expense.method,
      currency: expense.currency,
      description: expense.description,
      frequency: details.frequency,
      dayOfMonth: details.dayOfMonth,
      dayOfWeek: details.dayOfWeek,
      endDate: details.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _RecurringTemplateKey) return false;
    return remark == other.remark &&
        amount == other.amount &&
        categoryId == other.categoryId &&
        method == other.method &&
        currency == other.currency &&
        description == other.description &&
        frequency == other.frequency &&
        dayOfMonth == other.dayOfMonth &&
        dayOfWeek == other.dayOfWeek &&
        endDate == other.endDate;
  }

  @override
  int get hashCode => Object.hash(
        remark,
        amount,
    categoryId,
        method,
        currency,
        description,
        frequency,
        dayOfMonth,
        dayOfWeek,
        endDate,
      );
}
