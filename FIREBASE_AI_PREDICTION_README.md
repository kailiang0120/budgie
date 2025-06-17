# Firebase AI Prediction System

This document explains the enhanced AI prediction system that fetches data from Firebase, generates predictions, and stores results for historical analysis.

## Overview

The AI prediction system has been enhanced with the following components:

1. **Firebase Data Fetcher Service** - Centralized data fetching with offline support
2. **Enhanced AI Prediction Card** - Improved UI with Firebase integration
3. **Prediction Storage** - Historical tracking of AI predictions
4. **Budget Reallocation Service** - Smart budget redistribution based on AI insights

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     AI Prediction Flow                         │
├─────────────────────────────────────────────────────────────────┤
│ 1. User triggers prediction                                     │
│ 2. Firebase Data Fetcher gets expenses & budget                │
│ 3. AI Service analyzes data & generates predictions            │
│ 4. Predictions stored in Firebase for historical analysis      │
│ 5. User can apply budget reallocation suggestions              │
│ 6. Reallocation results stored for tracking                    │
└─────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Firebase Data Fetcher Service

**Location**: `lib/data/infrastructure/services/firebase_data_fetcher_service.dart`

**Features**:
- Fetches expenses and budget data from Firebase
- Provides offline fallback using local database
- Handles network connectivity gracefully
- Stores AI predictions for historical analysis
- Retrieves historical predictions for trend analysis

**Usage**:
```dart
final firebaseDataFetcher = di.sl<FirebaseDataFetcherService>();

// Fetch recent expenses
final expensesResult = await firebaseDataFetcher.fetchExpensesData(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  limit: 100,
  forceRefresh: true,
);

// Fetch budget data
final budgetResult = await firebaseDataFetcher.fetchBudgetData(
  monthId: '2024-01',
  forceRefresh: false,
);
```

### 2. Enhanced AI Response Models

**Location**: `lib/data/models/ai_response_models.dart`

**New Features**:
- Added `toFirebaseDocument()` method for proper Firebase storage
- Enhanced metadata tracking
- Version control for prediction data

### 3. AI Prediction Card

**Location**: `lib/presentation/widgets/ai_prediction_card.dart`

**Enhanced Features**:
- Uses Firebase Data Fetcher for reliable data access
- Stores prediction results automatically
- Shows data source information (Firebase vs cached)
- Improved error handling and user feedback
- Refreshes predictions after budget reallocation

**UI Improvements**:
- Better loading states
- Comprehensive error messages
- Data source indicators
- Reallocation success feedback

### 4. Budget Reallocation Service

**Location**: `lib/domain/services/budget_reallocation_service.dart`

**Enhanced Features**:
- Improved logging and debugging
- Better validation of reallocation scenarios
- More sophisticated surplus/shortfall analysis
- Enhanced error handling with specific error codes

## Data Structure

### Firebase Collections

#### 1. Expenses Collection
```
users/{userId}/expenses/{expenseId}
{
  "remark": "Lunch",
  "amount": 15.50,
  "date": Timestamp,
  "category": "food",
  "method": "cash",
  "description": "Daily meal",
  "currency": "MYR",
  "recurringDetails": {...} // Optional
}
```

#### 2. Budgets Collection
```
users/{userId}/budgets/{monthId}
{
  "total": 1000.0,
  "left": 750.0,
  "categories": {
    "food": {"budget": 300.0, "left": 200.0},
    "transport": {"budget": 200.0, "left": 150.0}
  },
  "saving": 500.0,
  "currency": "MYR"
}
```

#### 3. AI Predictions Collection (New)
```
users/{userId}/ai_predictions/{predictionId}
{
  "userId": "user123",
  "monthId": "2024-01",
  "predictionDate": Timestamp,
  "targetDate": "2024-01-15",
  "predictionData": {
    "predictedExpenses": [...],
    "summary": {...},
    "insights": [...],
    "metadata": {
      "aiModel": "gemma-3-27b-it",
      "version": "1.0",
      "predictionType": "daily"
    }
  },
  "createdAt": ServerTimestamp,
  "reallocationApplied": false // Optional
}
```

## How to Use

### 1. Run the Firebase Data Fetching Script

```bash
dart run scripts/firebase_data_fetch_script.dart
```

This script will:
- Test Firebase connectivity
- Fetch expenses and budget data
- Store sample predictions
- Retrieve historical predictions

### 2. Use AI Predictions in the App

1. **Navigate to Home Screen**: The AI prediction card appears when you have sufficient expense history
2. **Trigger Prediction**: Tap the lightbulb icon to generate predictions
3. **Review Results**: See predicted expenses, insights, and risk levels
4. **Apply Reallocation**: If suggested, tap the reallocation button to optimize your budget
5. **Historical Analysis**: Predictions are automatically stored for future reference

### 3. Budget Reallocation Process

1. **Analysis**: AI analyzes spending patterns and predicts shortfalls
2. **Suggestions**: System generates reallocation recommendations
3. **Validation**: Checks if reallocation is mathematically possible
4. **Execution**: Moves budget between categories and saving
5. **Storage**: Results stored for historical tracking

## Error Handling

The system handles various error scenarios:

- **Network Issues**: Falls back to local cached data
- **Authentication Errors**: Clear error messages for user
- **Insufficient Data**: Informative messages about data requirements
- **Reallocation Failures**: Specific error codes for different scenarios

## Configuration

### Environment Setup

1. Ensure Firebase is properly configured
2. User must be authenticated
3. Recent expense data (within 14 days) required for daily predictions
4. Valid budget data required for reallocation

### Dependencies

The system requires these services to be registered in DI container:
- `FirebaseDataFetcherService`
- `AIExpensePredictionService`
- `BudgetReallocationService`
- `ConnectivityService`
- `LocalDataSource`

## Testing

### Manual Testing

1. Use the Firebase data fetching script to test connectivity
2. Create test expenses and budgets
3. Generate AI predictions through the UI
4. Verify predictions are stored in Firebase
5. Test budget reallocation functionality

### Integration Testing

The system integrates with:
- Firebase Firestore for data storage
- Local SQLite database for offline support
- Google AI (Gemini) for predictions
- Flutter state management (Provider)

## Performance Considerations

- **Caching**: Uses local database for offline performance
- **Batching**: Fetches data in configurable batches
- **Timeouts**: All Firebase operations have appropriate timeouts
- **Background Storage**: Prediction storage doesn't block UI

## Security

- **Authentication Required**: All operations require authenticated user
- **User Isolation**: Data is properly scoped to individual users
- **Error Sanitization**: Sensitive information not exposed in error messages

## Future Enhancements

1. **Batch Predictions**: Generate predictions for multiple days
2. **Trend Analysis**: Compare predictions with actual spending
3. **Machine Learning**: Improve predictions based on historical accuracy
4. **Notifications**: Alert users about budget risks
5. **Export/Import**: Data export functionality for analysis

## Troubleshooting

### Common Issues

1. **"No authenticated user"**: Ensure user is signed in to Firebase
2. **"Insufficient data"**: Add more recent expense entries
3. **"Network timeout"**: Check internet connectivity
4. **"Reallocation impossible"**: All categories may be over budget

### Debug Logging

The system provides comprehensive debug logging with prefixes:
- `🔥` Firebase Data Fetcher operations
- `🤖` AI prediction operations
- `🔄` Budget reallocation operations

Enable debug mode to see detailed operation logs.

## Support

For issues or questions:
1. Check the debug logs for specific error messages
2. Verify Firebase configuration and authentication
3. Ensure all required services are properly registered
4. Test with the provided Firebase data fetching script

## Contributing

When contributing to this system:
1. Follow the established error handling patterns
2. Add comprehensive logging for debugging
3. Update this README for any new features
4. Test both online and offline scenarios
5. Maintain backward compatibility with existing data structures 