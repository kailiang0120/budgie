# Core Business Objects - Budgie Finance App

## Overview
This document outlines the core business objects (entities) that form the foundation of the Budgie personal finance management application. These entities represent the key domain concepts and their relationships.

## Primary Domain Entities

### 1. Expense
**Core financial transaction entity representing user spending**

```dart
class Expense {
  String id;                    // Unique identifier
  String remark;                // Brief description/title
  double amount;                // Amount spent
  DateTime date;                // Transaction date
  Category category;            // Expense category
  PaymentMethod method;         // Payment method used
  String? description;          // Optional detailed description
  String currency;              // Currency code (default: MYR)
  RecurringDetails? recurringDetails; // Recurring configuration
}
```

**Relationships:**
- Belongs to `Category`
- Has `PaymentMethod`
- May have `RecurringDetails` (if recurring expense)
- Associated with `Budget` (for tracking against budget)

### 2. Budget
**Monthly budget management entity**

```dart
class Budget {
  double total;                           // Total budget amount
  double left;                            // Remaining budget
  Map<String, CategoryBudget> categories; // Category-wise allocations
  double saving;                          // Unallocated amount
  String currency;                        // Currency code
}
```

**Relationships:**
- Contains multiple `CategoryBudget` objects
- Associated with specific month (monthId)
- Used by `Expense` tracking

### 3. CategoryBudget
**Budget allocation for a specific category**

```dart
class CategoryBudget {
  double budget;  // Allocated budget for category
  double left;    // Remaining budget for category
}
```

**Relationships:**
- Belongs to `Budget`
- Associated with `Category`

### 4. FinancialGoal
**User's financial objectives and targets**

```dart
class FinancialGoal {
  String id;                    // Unique identifier
  String title;                 // Goal name
  double targetAmount;          // Target savings amount
  double currentAmount;         // Current saved amount
  DateTime deadline;            // Target completion date
  GoalIcon icon;                // Visual representation
  bool isCompleted;             // Completion status
  DateTime createdAt;           // Creation timestamp
  DateTime updatedAt;           // Last update timestamp
}
```

**Relationships:**
- Has `GoalIcon` for visual representation
- May have `GoalHistory` when completed
- Associated with user's savings strategy

### 5. GoalHistory
**Completed goals tracking and analysis**

```dart
class GoalHistory {
  String id;                    // Unique identifier
  String goalId;                // Original goal reference
  String title;                 // Goal name
  double targetAmount;          // Original target
  double finalAmount;           // Amount actually saved
  DateTime createdDate;         // When goal was created
  DateTime completedDate;       // When goal was completed
  GoalIcon icon;                // Visual representation
  String? notes;                // Completion notes
  DateTime updatedAt;           // Last update timestamp
}
```

**Relationships:**
- References `FinancialGoal` (original goal)
- Used for historical analysis and insights

### 6. UserBehaviorProfile
**Comprehensive user financial behavior characteristics**

```dart
class UserBehaviorProfile {
  String id;                           // Unique identifier
  String userId;                       // User reference
  IncomeStability incomeStability;     // Income pattern
  SpendingMentality spendingMentality; // Spending behavior
  RiskAppetite riskAppetite;           // Risk tolerance
  FinancialLiteracyLevel financialLiteracyLevel; // Knowledge level
  FinancialPriority financialPriority; // Priority focus
  SavingHabit savingHabit;             // Saving behavior
  FinancialStressLevel financialStressLevel; // Stress level
  Occupation occupation; // Current occupation
  DateTime createdAt;                  // Creation timestamp
  DateTime updatedAt;                  // Last update timestamp
  DateTime? dataConsentAcceptedAt;     // Privacy consent
  bool isComplete;                     // Profile completion status
}
```

**Relationships:**
- Associated with user account
- Used by AI analysis services for personalized insights
- Influences budget recommendations

## Supporting Domain Entities

### 7. Category
**Expense categorization system**

```dart
enum Category {
  food,           // Food and dining
  transportation, // Transport and travel
  rental,         // Housing and rent
  utilities,      // Bills and utilities
  shopping,       // Retail and shopping
  entertainment,  // Leisure and entertainment
  education,      // Learning and education
  travel,         // Travel and tourism
  medical,        // Healthcare and medical
  others,         // Miscellaneous expenses
}
```

**Relationships:**
- Used by `Expense` for categorization
- Associated with `CategoryBudget` for budget allocation

### 8. RecurringDetails
**Recurring expense configuration**

```dart
class RecurringDetails {
  RecurringFrequency frequency; // Weekly or monthly
  int? dayOfMonth;              // Day for monthly (1-31)
  DayOfWeek? dayOfWeek;         // Day for weekly
  DateTime? endDate;            // Optional end date
}
```

**Enums:**
```dart
enum RecurringFrequency { weekly, monthly }
enum DayOfWeek { monday, tuesday, wednesday, thursday, friday, saturday, sunday }
```

**Relationships:**
- Embedded within `Expense` (if recurring)
- Used by recurring expense processing service

### 9. GoalIcon
**Visual representation for financial goals**

```dart
class GoalIcon {
  IconData icon;    // Flutter icon data
  String name;      // Icon identifier
  Color color;      // Icon color
}
```

**Relationships:**
- Used by `FinancialGoal` and `GoalHistory`
- Provides visual identity for goals

### 10. PaymentMethod
**Payment type enumeration**

```dart
enum PaymentMethod {
  card,         // Credit/Debit card
  cash,         // Cash payment
  eWallet,      // Digital wallet
  bankTransfer, // Bank transfer
  other,        // Other methods
}
```

**Relationships:**
- Used by `Expense` to track payment method
- Used for spending pattern analysis

## User Behavior Enums

### Income Stability
```dart
enum IncomeStability {
  stable('Stable', 'Consistent monthly income (salary, pension)'),
  variable('Variable', 'Income varies but predictable (commission, freelance)'),
  irregular('Irregular', 'Unpredictable income patterns (gig work, seasonal)');
}
```

### Spending Mentality
```dart
enum SpendingMentality {
  conscious('Conscious Spender', 'Carefully consider every purchase'),
  balanced('Balanced Spender', 'Mix of planned and spontaneous spending'),
  spontaneous('Spontaneous Spender', 'Often make impulse purchases');
}
```

### Risk Appetite
```dart
enum RiskAppetite {
  low('Low Risk', 'Prefer guaranteed returns and stability'),
  medium('Medium Risk', 'Balanced approach to risk and reward'),
  high('High Risk', 'Comfortable with higher risk for potential gains');
}
```

### Financial Literacy Level
```dart
enum FinancialLiteracyLevel {
  beginner('Beginner', 'New to personal finance and investing concepts'),
  intermediate('Intermediate', 'Some knowledge of budgeting and basic investments'),
  advanced('Advanced', 'Well-versed in financial planning and investment strategies'),
  expert('Expert', 'Deep understanding of complex financial instruments and strategies');
}
```

### Financial Priority
```dart
enum FinancialPriority {
  saving('Saving', 'Building emergency funds and long-term savings'),
  spending('Spending', 'Maintaining current lifestyle and expenses'),
  investing('Investing', 'Growing wealth through investments'),
  debtRepayment('Debt Repayment', 'Paying off existing debts'),
  other('Other', 'Other financial priorities');
}
```

### Saving Habit
```dart
enum SavingHabit {
  regular('Regular Saver', 'Save consistently every month'),
  occasional('Occasional Saver', 'Save when possible but not consistently'),
  rarely('Rare Saver', 'Save infrequently or only when necessary'),
  never('Non-Saver', 'Do not save regularly');
}
```

### Financial Stress Level
```dart
enum FinancialStressLevel {
  low('Low Stress', 'Generally comfortable with financial situation'),
  moderate('Moderate Stress', 'Some financial concerns but manageable'),
  high('High Stress', 'Significant financial stress and anxiety');
}
```

### Occupation
```dart
enum Occupation {
  student('Student', 'Currently enrolled in education'),
  employed('Employed', 'Full-time or part-time employment'),
  selfEmployed('Self-Employed', 'Running own business or freelance work'),
  retired('Retired', 'No longer working, living on retirement income'),
  unemployed('Unemployed', 'Currently seeking employment'),
  homemaker('Homemaker', 'Managing household and family'),
  other('Other', 'Other occupation type');
}

## Entity Relationships Summary

### Core Relationships
1. **Expense** → **Category** (belongs to)
2. **Expense** → **PaymentMethod** (has)
3. **Expense** → **RecurringDetails** (may have)
4. **Budget** → **CategoryBudget** (contains multiple)
5. **CategoryBudget** → **Category** (associated with)
6. **FinancialGoal** → **GoalIcon** (has)
7. **GoalHistory** → **FinancialGoal** (references)
8. **UserBehaviorProfile** → **User** (belongs to)

### Business Logic Relationships
1. **Expense** → **Budget** (tracked against)
2. **UserBehaviorProfile** → **AI Services** (influences recommendations)
3. **FinancialGoal** → **Budget** (funded from savings)
4. **RecurringDetails** → **Expense Processing** (automated creation)

## Database Tables Mapping

### Core Tables
- **Expenses** - Stores `Expense` entities
- **Budgets** - Stores `Budget` entities
- **FinancialGoals** - Stores `FinancialGoal` entities
- **GoalHistory** - Stores `GoalHistory` entities
- **UserProfiles** - Stores `UserBehaviorProfile` entities
- **ExchangeRates** - Caches currency conversion rates
- **AnalysisResults** - Stores AI analysis results

### Table Relationships
- Expenses table links to Categories via category field
- Budgets table contains JSON-serialized CategoryBudget mappings
- FinancialGoals table includes GoalIcon data
- UserProfiles table stores enum values as strings

## Usage in Architecture

### Domain Layer
- All entities are defined in `lib/domain/entities/`
- Pure business objects with no external dependencies
- Used by Use Cases and Domain Services

### Data Layer
- Entities are mapped to database tables via repositories
- JSON serialization for complex nested objects
- Enum values stored as strings in database

### Presentation Layer
- ViewModels manage entity state for UI
- Entities are displayed in various screens and widgets
- State changes trigger UI updates via ChangeNotifier

### Service Layer
- Domain services operate on entities
- AI analysis services use entities for insights
- Background services process entities (e.g., recurring expenses)

This comprehensive entity model provides the foundation for all business logic, data persistence, and user interface functionality in the Budgie application. 