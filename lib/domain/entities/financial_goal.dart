import 'package:flutter/material.dart';

/// Represents a financial goal icon
class GoalIcon {
  final IconData icon;
  final String name;
  final Color color;

  GoalIcon({
    required this.icon,
    required this.name,
    required this.color,
  });

  /// Convert icon name and color value to a GoalIcon
  static GoalIcon fromNameAndColor(String iconName, String colorValue) {
    final color = Color(int.parse(colorValue));
    final icon = _getIconFromName(iconName);
    return GoalIcon(icon: icon, name: iconName, color: color);
  }

  /// Get IconData from string name
  static IconData _getIconFromName(String name) {
    switch (name) {
      case 'security':
        return Icons.security;
      case 'flight':
        return Icons.flight;
      case 'car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.favorite;
      case 'tech':
        return Icons.devices;
      case 'savings':
        return Icons.savings;
      case 'vacation':
        return Icons.beach_access;
      case 'gift':
        return Icons.card_giftcard;
      case 'investment':
        return Icons.trending_up;
      case 'baby':
        return Icons.child_care;
      case 'wedding':
        return Icons.celebration;
      case 'pet':
        return Icons.pets;
      case 'fitness':
        return Icons.fitness_center;
      case 'business':
        return Icons.business;
      case 'emergency':
        return Icons.emergency;
      case 'retirement':
        return Icons.elderly;
      case 'charity':
        return Icons.volunteer_activism;
      default:
        return Icons.savings;
    }
  }

  /// Get all available icons
  static List<GoalIcon> getAllIcons({Color defaultColor = Colors.blue}) {
    return [
      GoalIcon(icon: Icons.savings, name: 'savings', color: defaultColor),
      GoalIcon(icon: Icons.security, name: 'security', color: defaultColor),
      GoalIcon(icon: Icons.flight, name: 'flight', color: defaultColor),
      GoalIcon(icon: Icons.directions_car, name: 'car', color: defaultColor),
      GoalIcon(icon: Icons.home, name: 'home', color: defaultColor),
      GoalIcon(icon: Icons.school, name: 'school', color: defaultColor),
      GoalIcon(icon: Icons.shopping_bag, name: 'shopping', color: defaultColor),
      GoalIcon(icon: Icons.favorite, name: 'health', color: defaultColor),
      GoalIcon(icon: Icons.devices, name: 'tech', color: defaultColor),
      GoalIcon(icon: Icons.beach_access, name: 'vacation', color: defaultColor),
      GoalIcon(icon: Icons.card_giftcard, name: 'gift', color: defaultColor),
      GoalIcon(
          icon: Icons.trending_up, name: 'investment', color: defaultColor),
      GoalIcon(icon: Icons.child_care, name: 'baby', color: defaultColor),
      GoalIcon(icon: Icons.celebration, name: 'wedding', color: defaultColor),
      GoalIcon(icon: Icons.pets, name: 'pet', color: defaultColor),
      GoalIcon(
          icon: Icons.fitness_center, name: 'fitness', color: defaultColor),
      GoalIcon(icon: Icons.business, name: 'business', color: defaultColor),
      GoalIcon(icon: Icons.emergency, name: 'emergency', color: defaultColor),
      GoalIcon(icon: Icons.elderly, name: 'retirement', color: defaultColor),
      GoalIcon(
          icon: Icons.volunteer_activism, name: 'charity', color: defaultColor),
    ];
  }

  /// Get all available colors for goal icons
  static List<Color> getAllColors() {
    return [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.lime,
      Colors.brown,
      Colors.blueGrey,
      Colors.grey,
      Colors.black,
    ];
  }

  /// Get a specific icon by name with a custom color
  static GoalIcon getIconWithColor(String name, Color color) {
    return GoalIcon(
      icon: _getIconFromName(name),
      name: name,
      color: color,
    );
  }

  /// Convert to string representation for storage
  String get iconName => name;

  /// Convert color to string representation for storage
  String get colorValue => color.value.toString();
}

/// Financial goal entity
class FinancialGoal {
  /// Unique identifier
  final String id;

  /// Goal title
  final String title;

  /// Target amount to save
  final double targetAmount;

  /// Current saved amount
  final double currentAmount;

  /// Deadline for achieving the goal
  final DateTime deadline;

  /// Icon and color for the goal
  final GoalIcon icon;

  /// Whether the goal has been completed
  final bool isCompleted;

  /// When the goal was created
  final DateTime createdAt;

  /// When the goal was last updated
  final DateTime updatedAt;

  /// Create a new financial goal
  FinancialGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.icon,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Calculate progress percentage as int (0-100)
  int get progressPercentage => (progress * 100).round();

  /// Check if goal is overdue
  bool get isOverdue => !isCompleted && DateTime.now().isAfter(deadline);

  /// Days remaining until deadline
  int get daysRemaining {
    if (isCompleted) return 0;
    return deadline.difference(DateTime.now()).inDays;
  }

  /// Amount remaining to reach target
  double get amountRemaining => targetAmount - currentAmount;

  /// Update current amount
  FinancialGoal copyWithNewAmount(double newAmount) {
    return FinancialGoal(
      id: id,
      title: title,
      targetAmount: targetAmount,
      currentAmount: newAmount,
      deadline: deadline,
      icon: icon,
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark as completed
  FinancialGoal markAsCompleted() {
    return FinancialGoal(
      id: id,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      icon: icon,
      isCompleted: true,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'iconName': icon.iconName,
      'colorValue': icon.colorValue,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map
  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num).toDouble(),
      deadline: DateTime.parse(map['deadline'] as String),
      icon: GoalIcon.fromNameAndColor(
        map['iconName'] as String,
        map['colorValue'] as String,
      ),
      isCompleted: map['isCompleted'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

/// Completed goal history record
class GoalHistory {
  /// Unique identifier for the history record
  final String id;

  /// Original goal ID
  final String goalId;

  /// Goal title
  final String title;

  /// Original target amount
  final double targetAmount;

  /// Final amount achieved
  final double finalAmount;

  /// When the goal was created
  final DateTime createdDate;

  /// When the goal was completed
  final DateTime completedDate;

  /// Icon and color for the goal
  final GoalIcon icon;

  /// Optional notes about completion
  final String? notes;

  /// When the record was last updated
  final DateTime updatedAt;

  /// Create a new goal history record
  GoalHistory({
    required this.id,
    required this.goalId,
    required this.title,
    required this.targetAmount,
    required this.finalAmount,
    required this.createdDate,
    required this.completedDate,
    required this.icon,
    this.notes,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Calculate achievement percentage (0.0 to 1.0)
  double get achievementRate =>
      targetAmount > 0 ? (finalAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Calculate achievement percentage as int (0-100)
  int get achievementPercentage => (achievementRate * 100).round();

  /// Duration taken to complete the goal
  Duration get completionDuration => completedDate.difference(createdDate);

  /// Days taken to complete the goal
  int get daysTaken => completionDuration.inDays;

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'targetAmount': targetAmount,
      'finalAmount': finalAmount,
      'createdDate': createdDate.toIso8601String(),
      'completedDate': completedDate.toIso8601String(),
      'iconName': icon.iconName,
      'colorValue': icon.colorValue,
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map
  factory GoalHistory.fromMap(Map<String, dynamic> map) {
    return GoalHistory(
      id: map['id'] as String,
      goalId: map['goalId'] as String,
      title: map['title'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      finalAmount: (map['finalAmount'] as num).toDouble(),
      createdDate: DateTime.parse(map['createdDate'] as String),
      completedDate: DateTime.parse(map['completedDate'] as String),
      icon: GoalIcon.fromNameAndColor(
        map['iconName'] as String,
        map['colorValue'] as String,
      ),
      notes: map['notes'] as String?,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
