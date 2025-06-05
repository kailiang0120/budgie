import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/recurring_expenses_repository.dart';
import '../errors/app_error.dart';

/// Service for processing recurring expenses and generating automatic expenses
class RecurringExpenseService {
  final ExpensesRepository _expensesRepository;
  final RecurringExpensesRepository _recurringExpensesRepository;
  Timer? _processingTimer;

  RecurringExpenseService({
    required ExpensesRepository expensesRepository,
    required RecurringExpensesRepository recurringExpensesRepository,
  })  : _expensesRepository = expensesRepository,
        _recurringExpensesRepository = recurringExpensesRepository;

  /// Start the recurring expense processing service
  void startProcessing() {
    if (_processingTimer != null) {
      return; // Already running
    }

    // Process recurring expenses every hour
    _processingTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _processRecurringExpenses();
    });

    // Also process immediately when service starts
    _processRecurringExpenses();
  }

  /// Stop the recurring expense processing service
  void stopProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  /// Manually trigger processing of recurring expenses
  Future<void> processRecurringExpenses() async {
    await _processRecurringExpenses();
  }

  /// Internal method to process all active recurring expenses
  Future<void> _processRecurringExpenses() async {
    try {
      debugPrint('🔄 Processing recurring expenses...');

      final activeRecurringExpenses =
          await _recurringExpensesRepository.getActiveRecurringExpenses();
      final now = DateTime.now();

      for (final recurringExpense in activeRecurringExpenses) {
        await _processIndividualRecurringExpense(recurringExpense, now);
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
    RecurringExpense recurringExpense,
    DateTime now,
  ) async {
    try {
      // Calculate the next occurrence dates that need to be processed
      final occurrences =
          _calculateOccurrencesSinceLastProcessed(recurringExpense, now);

      for (final occurrence in occurrences) {
        await _createExpenseFromRecurring(recurringExpense, occurrence);
      }

      // Update the last processed date
      if (occurrences.isNotEmpty) {
        await _recurringExpensesRepository.updateLastProcessedDate(
          recurringExpense.id,
          occurrences.last,
        );
        debugPrint(
            '✅ Processed ${occurrences.length} occurrences for recurring expense: ${recurringExpense.expenseRemark}');
      }
    } catch (e, stackTrace) {
      final error = AppError.from(e, stackTrace);
      error.log();
      debugPrint(
          '❌ Error processing recurring expense ${recurringExpense.id}: ${error.message}');
    }
  }

  /// Calculate all occurrence dates since last processed
  List<DateTime> _calculateOccurrencesSinceLastProcessed(
    RecurringExpense recurringExpense,
    DateTime now,
  ) {
    final occurrences = <DateTime>[];

    if (recurringExpense.frequency == RecurringFrequency.oneTime) {
      // One-time expenses don't repeat
      return occurrences;
    }

    // Start from last processed date or start date
    DateTime currentDate =
        recurringExpense.lastProcessedDate ?? recurringExpense.startDate;

    // If this is the first time processing and we're past the start date,
    // begin from the next occurrence after start date
    if (recurringExpense.lastProcessedDate == null &&
        now.isAfter(recurringExpense.startDate)) {
      currentDate =
          _getNextOccurrence(recurringExpense, recurringExpense.startDate);
    }

    while (currentDate.isBefore(now) || _isSameDay(currentDate, now)) {
      // Check if we've reached the end date
      if (recurringExpense.endDate != null &&
          currentDate.isAfter(recurringExpense.endDate!)) {
        break;
      }

      // Check if this occurrence should be added
      if (_shouldProcessOccurrence(recurringExpense, currentDate, now)) {
        occurrences.add(currentDate);
      }

      // Move to next occurrence
      currentDate = _getNextOccurrence(recurringExpense, currentDate);
    }

    return occurrences;
  }

  /// Determine if an occurrence should be processed
  bool _shouldProcessOccurrence(
    RecurringExpense recurringExpense,
    DateTime occurrence,
    DateTime now,
  ) {
    // Don't process future occurrences
    if (occurrence.isAfter(now)) {
      return false;
    }

    // Don't process if before start date
    if (occurrence.isBefore(recurringExpense.startDate)) {
      return false;
    }

    // Don't process if after end date
    if (recurringExpense.endDate != null &&
        occurrence.isAfter(recurringExpense.endDate!)) {
      return false;
    }

    // If this is the first processing and occurrence is start date, process it
    if (recurringExpense.lastProcessedDate == null &&
        _isSameDay(occurrence, recurringExpense.startDate)) {
      return true;
    }

    // Process if this occurrence is after the last processed date
    return recurringExpense.lastProcessedDate == null ||
        occurrence.isAfter(recurringExpense.lastProcessedDate!);
  }

  /// Get the next occurrence date based on frequency
  DateTime _getNextOccurrence(
      RecurringExpense recurringExpense, DateTime currentDate) {
    switch (recurringExpense.frequency) {
      case RecurringFrequency.weekly:
        return _getNextWeeklyOccurrence(recurringExpense, currentDate);
      case RecurringFrequency.monthly:
        return _getNextMonthlyOccurrence(recurringExpense, currentDate);
      case RecurringFrequency.oneTime:
        return currentDate; // Won't be used for one-time
    }
  }

  /// Calculate next weekly occurrence
  DateTime _getNextWeeklyOccurrence(
      RecurringExpense recurringExpense, DateTime currentDate) {
    if (recurringExpense.dayOfWeek == null) {
      // If no day specified, use the start date's day of week
      final startDayOfWeek = recurringExpense.startDate.weekday;
      return _getNextDateForWeekday(currentDate, startDayOfWeek);
    }

    return _getNextDateForWeekday(
        currentDate, recurringExpense.dayOfWeek!.weekday);
  }

  /// Calculate next monthly occurrence
  DateTime _getNextMonthlyOccurrence(
      RecurringExpense recurringExpense, DateTime currentDate) {
    if (recurringExpense.dayOfMonth == null) {
      // If no day specified, use the start date's day
      return _getNextDateForDayOfMonth(
          currentDate, recurringExpense.startDate.day);
    }

    return _getNextDateForDayOfMonth(currentDate, recurringExpense.dayOfMonth!);
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
    RecurringExpense recurringExpense,
    DateTime occurrenceDate,
  ) async {
    try {
      // Convert category ID to Category enum
      final category = app_category.CategoryExtension.fromId(
              recurringExpense.expenseCategoryId) ??
          app_category.Category.others;

      // Convert payment method string to PaymentMethod enum
      final paymentMethod = PaymentMethod.values.firstWhere(
        (method) =>
            method.toString().split('.').last ==
            recurringExpense.expensePaymentMethod,
        orElse: () => PaymentMethod.cash,
      );

      final expense = Expense(
        id: '', // Let repository assign ID
        remark: recurringExpense.expenseRemark,
        amount: recurringExpense.expenseAmount,
        date: occurrenceDate,
        category: category,
        method: paymentMethod,
        description: recurringExpense.expenseDescription,
        currency: recurringExpense.expenseCurrency,
        recurringExpenseId: recurringExpense.id,
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
  DateTime? calculateNextOccurrence(RecurringExpense recurringExpense) {
    if (recurringExpense.frequency == RecurringFrequency.oneTime) {
      return null;
    }

    final now = DateTime.now();
    final lastProcessed =
        recurringExpense.lastProcessedDate ?? recurringExpense.startDate;

    return _getNextOccurrence(recurringExpense, lastProcessed);
  }

  /// Check if a recurring expense is due for processing
  bool isDueForProcessing(RecurringExpense recurringExpense) {
    if (recurringExpense.frequency == RecurringFrequency.oneTime) {
      return false;
    }

    final now = DateTime.now();
    final occurrences =
        _calculateOccurrencesSinceLastProcessed(recurringExpense, now);

    return occurrences.isNotEmpty;
  }
}
