import 'package:flutter/foundation.dart';

@immutable
class BudgetSuggestion {
  final int? id;
  final String monthId;
  final String userId;
  final String suggestions;
  final DateTime timestamp;
  final bool isRead;

  const BudgetSuggestion({
    this.id,
    required this.monthId,
    required this.userId,
    required this.suggestions,
    required this.timestamp,
    this.isRead = false,
  });
}
