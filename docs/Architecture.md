# Budgie - Flutter Clean Architecture Documentation

## 📁 Project Structure Overview

This project follows **Clean Architecture** principles with clear separation of concerns across different layers. Each layer has specific responsibilities and dependencies flow inward (toward the domain layer).

```
lib/
├── 🏗️ core/                    # Core application infrastructure
├── 🎯 domain/                  # Business logic & entities (Clean Architecture core)
├── 💾 data/                    # Data layer (repositories, services, models)
├── 🎨 presentation/            # UI layer (screens, widgets, viewmodels)
├── 🔧 di/                      # Dependency injection container
└── 📱 main.dart               # Application entry point
```

## ✅ **FASTAPI INTEGRATION COMPLETED (v3.0)**

### **1. Google AI Package Removed** ✅
- **Removed**: Direct `google_generative_ai` package dependency
- **Replaced**: Direct AI calls with FastAPI backend integration
- **Security**: No API keys exposed in mobile application
- **Scalability**: Centralized AI processing through backend services

### **2. Backend Integration** ✅
- **HTTP Client**: Robust FastAPI backend communication
- **Error Handling**: Comprehensive network and API error management
- **Health Monitoring**: Service health checking capabilities
- **Environment Config**: Development/production URL configuration

### **3. Service Modernization** ✅
- **Expense Extraction**: FastAPI backend for notification processing
- **Spending Analysis**: Backend-powered behavioral insights
- **Budget Optimization**: Server-side budget reallocation analysis
- **TFLite (Hybrid)**: Current codebase includes a hybrid path (local TFLite classifier + backend extraction). If moving to API-only, remove TFLite code and assets; otherwise keep hybrid.

### **4. Deprecated Services Cleaned** ✅
- **Removed**: `AIExpensePredictionService` (deprecated)
- **Updated**: All AI services to use FastAPI endpoints
- **Simplified**: Dependency injection configuration
- **Maintained**: Clean architecture principles

### **5. Architecture Benefits** ✅
- **Security**: API keys secured on backend
- **Performance**: Reduced mobile app size (no local ML models)
- **Maintainability**: Centralized AI logic updates
- **Scalability**: Backend can serve multiple clients

## 🏗️ **LAYER BREAKDOWN**

### **🎯 Domain Layer** (Business Logic Core)
```
domain/
├── entities/              # Pure business objects
│   ├── budget.dart       # Budget domain model
│   ├── category.dart     # Expense categories
│   ├── expense.dart      # Expense domain model
│   ├── recurring_expense.dart # Recurring expenses
│   ├── user.dart        # User domain model
│   └── constants.dart   # Domain constants
├── repositories/         # Repository contracts (interfaces)
│   ├── auth_repository.dart
│   ├── budget_repository.dart
│   ├── expenses_repository.dart
│   └── recurring_expenses_repository.dart
├── services/            # Domain business logic services
│   ├── budget_calculation_service.dart              # Business rules for budget calculations
│   ├── budget_reallocation_service.dart             # Budget optimization logic
│   ├── expense_extraction_service.dart              # Expense detection interface
│   └── spending_behavior_analysis_service.dart      # Spending pattern analysis
└── usecase/            # Single-responsibility use cases
    ├── auth/           # Authentication use cases
    ├── budget/         # Budget management use cases
    └── expense/        # Expense management use cases
```

### **💾 Data Layer** (External Concerns)
```
data/
├── datasources/         # Data source abstractions
│   ├── local_data_source.dart      # Local database interface
│   └── local_data_source_impl.dart # SQLite implementation
├── infrastructure/     # External service integrations
│   ├── config/         # Configuration files
│   │   └── firebase_options.dart
│   ├── errors/         # Error handling
│   │   └── app_error.dart
│   ├── monitoring/     # Performance monitoring
│   │   └── performance_monitor.dart
│   ├── network/        # Network services
│   │   └── connectivity_service.dart
│   └── services/       # Infrastructure services
│       ├── background_task_service.dart        # Background processing
│       ├── currency_conversion_service.dart    # External currency API
│       ├── data_collection_service.dart        # Analytics & telemetry
│       ├── expense_extraction_service_impl.dart # FastAPI expense extraction
│       ├── gemini_api_client.dart              # FastAPI backend client
│       ├── notification_listener_service.dart  # Platform notification listener
│       ├── notification_service.dart           # Notification management
│       ├── permission_handler_service.dart     # Platform permissions
│       ├── settings_service.dart               # User preferences
│       └── sync_service.dart                   # Data synchronization
├── local/              # Local storage implementations
│   └── database/       # Floor database
│       ├── app_database.dart
│       └── app_database.g.dart
├── models/             # Data transfer objects
│   ├── budget_reallocation_models.dart  # Budget optimization models
│   ├── exceptions.dart                  # Data layer exceptions
│   ├── expense_detection_models.dart    # Expense detection models
│   └── spending_behavior_models.dart    # Spending analysis models
└── repositories/       # Repository implementations
    ├── auth_repository_impl.dart
    ├── budget_repository_impl.dart
    ├── expenses_repository_impl.dart
    └── recurring_expenses_repository_impl.dart
```

### **🎨 Presentation Layer** (UI & User Interaction)
```
presentation/
├── screens/            # Application screens
│   ├── add_budget_screen.dart     # Budget creation
│   ├── add_expense_screen.dart    # Expense entry
│   ├── analytic_screen.dart       # Data analytics
│   ├── edit_expense_screen.dart   # Expense editing
│   ├── home_screen.dart           # Main dashboard
│   ├── login_screen.dart          # Authentication
│   ├── notification_test_screen.dart # Notification testing
│   ├── profile_screen.dart        # User profile
│   ├── setting_screen.dart        # App settings
│   └── splash_screen.dart         # App startup
├── services/           # UI-specific services
│   ├── expense_card_manager_service.dart # UI card management
│   └── ui_overlay_service.dart          # UI overlays
├── utils/              # Presentation utilities
│   ├── app_constants.dart         # UI constants
│   ├── app_theme.dart            # Theme configuration
│   ├── auth_utils.dart           # Authentication helpers
│   ├── category_manager.dart     # Category management
│   ├── currency_formatter.dart   # Currency formatting
│   └── dialog_utils.dart         # Dialog utilities
├── viewmodels/         # State management (MVVM)
│   ├── auth_viewmodel.dart       # Authentication state
│   ├── budget_viewmodel.dart     # Budget state
│   ├── expenses_viewmodel.dart   # Expenses state
│   └── theme_viewmodel.dart      # Theme state
└── widgets/            # Reusable UI components
    ├── animated_float_button.dart (uses global observer from core/router)
    ├── auth_button.dart
    ├── bottom_nav_bar.dart
    ├── budget_card.dart
    ├── category_selector.dart
    ├── custom_card.dart
    ├── custom_dropdown_field.dart
    ├── custom_text_field.dart
    ├── date_picker_button.dart
    ├── date_time_picker_field.dart
    ├── dropdown_tile.dart
    ├── expense_card.dart
    ├── expense_pie_chart.dart
    ├── legend_card.dart
    ├── legend_item.dart
    ├── month_display.dart
    ├── notification_expense_card.dart
    ├── recurring_expense_config.dart
    ├── submit_button.dart
    └── switch_tile.dart
```

### **🏗️ Core Layer** (Shared Infrastructure)
```
core/
├── constants/          # Application constants
│   └── routes.dart    # Route definitions
└── router/            # Navigation infrastructure
    ├── app_router.dart        # Route configuration
    ├── navigation_helper.dart  # Navigation utilities
    └── page_transition.dart    # Custom transitions
```

### **🔧 Dependency Injection**
```
di/
└── injection_container.dart  # Service locator setup
```

## 🎯 **CLEAN ARCHITECTURE PRINCIPLES**

### **Dependency Rule**
- **Domain** depends on nothing
- **Data** depends only on Domain
- **Presentation** depends on Domain and Data abstractions
- **Core** provides shared utilities to all layers

### **Service Organization**
- **Domain Services**: Pure business logic (no I/O, no external dependencies)
- **Infrastructure Services**: External integrations (APIs, databases, platform features)
- **Presentation Services**: UI-specific functionality

### **Use Case Pattern**
Each use case handles a single business operation:
```dart
// Example: Single responsibility use case
class AddExpenseUseCase {
  final ExpensesRepository expensesRepository;
  final BudgetRepository budgetRepository;
  final BudgetCalculationService budgetCalculationService;
  
  Future<void> execute(Expense expense) async {
    // Single, focused business operation
  }
}
```

## 🚦 **CURRENT STATUS**

### **Architecture Quality: ✅ EXCELLENT**
- ✅ Clear separation of concerns
- ✅ Proper dependency injection
- ✅ Clean interfaces and abstractions
- ✅ Single responsibility principle
- ✅ Enterprise-level error handling
- ✅ Consistent naming conventions

### **Service Optimization: ✅ CURRENT**
- ✅ Centralized API client for backend
- ⚠️ Hybrid detection active (TFLite classifier + API extraction)
- ⚠️ Consider consolidating to API-only to reduce app size and complexity, or document hybrid explicitly

### **Code Quality: ✅ HIGH**
- ✅ Consistent error handling
- ✅ Proper logging throughout
- ✅ Clean model separation
- ✅ Enterprise standards compliance

## 🎯 **NOTIFICATION DETECTION FLOW**

```
📱 Notification Received
     ↓
🔔 NotificationManagerService
     ↓
🧠 ExpenseDetector (Domain)
     ↓
🤖 AI/ML API Service
     ↓
💰 Amount Extraction Only
     ↓
💾 Firebase Storage
```

**Key Features:**
- **API-Only Detection**: No fallback pattern matching
- **Amount-Only**: No merchant detection (simplified)
- **Clean Failure**: Graceful handling when API unavailable
- **Enterprise Logging**: Comprehensive tracking and debugging

## 🏆 **BEST PRACTICES IMPLEMENTED**

1. **Single Responsibility**: Each service has one clear purpose
2. **Dependency Inversion**: All dependencies flow inward to domain
3. **Interface Segregation**: Clean, focused interfaces
4. **Open/Closed Principle**: Extensible without modification
5. **Don't Repeat Yourself**: No duplicate functionality
6. **Fail Fast**: Early validation and clear error messages
7. **Enterprise Logging**: Comprehensive debugging information

This architecture provides a solid foundation for maintainable, testable, and scalable Flutter applications.

# Budgie App - Component Library

This document summarizes the reusable components and utility classes in the Budgie application to help developers better understand and use these components.

## Utility Classes

### AppTheme

`lib/presentation/utils/app_theme.dart`

Centrally manages the application's theme styles, including colors, fonts, border radius, etc. Provides both light and dark themes.

```dart
// Usage example
final primaryColor = AppTheme.primaryColor;
final themeData = AppTheme.lightTheme;
```

### AppConstants

`lib/presentation/utils/app_constants.dart`

Centrally manages constants in the application, including currency lists, payment methods, date formats, message texts, etc.

```dart
// Usage example
final currencies = AppConstants.currencies;
final dateFormat = AppConstants.dateFormat;
```

### CategoryManager

`lib/presentation/utils/category_manager.dart`

Unified category management utility class that provides category-related colors, icons, names, and other properties and methods.

```dart
// Usage example
final color = CategoryManager.getColor(Category.food);
final icon = CategoryManager.getIcon(Category.food);
final name = CategoryManager.getName(Category.food);

// Get category from ID
final category = CategoryManager.getCategoryFromId('food');

// Get all categories
final allCategories = CategoryManager.allCategories;
```

## Category System

The application uses a unified category system, defined in the `lib/domain/entities/category.dart` file:

```dart
enum Category {
  food,
  transportation,
  rental,
  utilities,
  shopping,
  entertainment,
  education,
  travel,
  medical,
  others,
}
```

Main advantages of the category system:
- Unified management of all category colors, icons, and names
- Easy to add, remove, or modify categories
- Supports filtering categories in different scenarios
- Supports use in budgets and other places that require string keys through string IDs

For detailed information, please refer to `lib/domain/entities/README.md`.

## Reusable Components

### CustomTextField

`lib/presentation/widgets/custom_text_field.dart`

Universal text input field component that supports multiple types of input, such as plain text, numbers, currency, etc.

```dart
// Basic usage
CustomTextField(
  labelText: 'Label',
  prefixIcon: Icons.person,
  isRequired: true,
)

// Number input
CustomTextField.number(
  labelText: 'Amount',
  allowDecimal: true,
  isRequired: true,
)

// Currency input
CustomTextField.currency(
  labelText: 'Budget',
  currencySymbol: 'MYR',
  isRequired: true,
)
```

### CustomDropdownField

`lib/presentation/widgets/custom_dropdown_field.dart`

Universal dropdown selector component that can be used to select currency, payment methods, etc.

```dart
CustomDropdownField<String>(
  value: selectedValue,
  items: itemsList,
  labelText: 'Label',
  onChanged: (value) => setState(() => selectedValue = value!),
  itemLabelBuilder: (item) => item,
  prefixIcon: Icons.payment,
)
```

### DateTimePickerField

`lib/presentation/widgets/date_time_picker_field.dart`

Date and time picker component that provides date and time selection functionality, as well as a "Current Time" button.

```dart
DateTimePickerField(
  dateTime: selectedDateTime,
  onDateChanged: (date) => setState(() => selectedDateTime = date),
  onTimeChanged: (time) => setState(() => selectedDateTime = time),
  onCurrentTimePressed: () => setState(() => selectedDateTime = DateTime.now()),
)
```

### CategorySelector

`lib/presentation/widgets/category_selector.dart`

Category selector component used to select categories, displaying category icons and names.

```dart
CategorySelector(
  selectedCategory: selectedCategory,
  onCategorySelected: (category) => setState(() => selectedCategory = category),
  // Optional: filter categories
  categories: [Category.food, Category.entertainment, Category.others],
)
```

### SubmitButton

`lib/presentation/widgets/submit_button.dart`

Submit button component that supports loading states and icons.

```dart
SubmitButton(
  text: 'Save',
  loadingText: 'Saving...',
  isLoading: isSubmitting,
  onPressed: submit,
  icon: Icons.save,
)
```

### CustomCard

`lib/presentation/widgets/custom_card.dart`

Custom card component that provides consistent card styling, supports click events, titles, and action buttons.

```dart
// Basic card
CustomCard(
  child: Text('Content'),
  onTap: () => print('Card clicked'),
)

// Card with title
CustomCard.withTitle(
  title: 'Title',
  icon: Icons.info,
  child: Text('Content'),
)

// Card with action button
CustomCard.withAction(
  child: Text('Content'),
  actionText: 'View More',
  onActionPressed: () => print('Action button clicked'),
)
```

## Example Pages

### AddExpenseScreen

`lib/presentation/screens/add_expense_screen.dart`

Add expense page that demonstrates how to use various reusable components to build form pages.

### AddBudgetScreen

`lib/presentation/screens/add_budget_screen.dart`

Add budget page that demonstrates how to use various reusable components to build form pages, and how to use ValueNotifier to manage state.

## Usage Guidelines

1. Prioritize using reusable components instead of recreating similar functionality
2. Follow the application's theme and style guidelines, using colors and styles defined in AppTheme
3. Use constants defined in AppConstants instead of hardcoding strings
4. Use CategoryManager to manage all category-related operations
5. If you need to create new reusable components, please follow the design patterns and naming conventions of existing components 