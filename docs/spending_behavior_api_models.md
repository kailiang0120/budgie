# Spending Behavior Analysis API Models

This document outlines the JSON structure for the request and response of the `SpendingBehaviorAnalysisService`.

## Request Format

```json
{
  "historicalExpenses": [
    {
      "amount": "double",
      "date": "String (ISO 8601)",
      "categoryId": "String",
      "categoryName": "String",
      "paymentMethod": "String",
      "remark": "String",
      "description": "String | null",
      "currency": "String",
      "recurringDetails": {
        "frequency": "String (e.g., 'daily', 'weekly')",
        "endDate": "String (ISO 8601) | null"
      }
    }
  ],
  "currentBudget": {
    "total": "double",
    "left": "double",
    "categories": {
      "categoryId_1": {
        "budget": "double",
        "left": "double"
      },
      "categoryId_2": {
        "budget": "double",
        "left": "double"
      }
    },
    "saving": "double",
    "currency": "String"
  },
  "userProfile": {
    "userId": "String",
    "primaryFinancialGoal": "String",
    "incomeStability": "String",
    "spendingMentality": "String",
    "riskAppetite": "String",
    "monthlyIncome": "double",
    "emergencyFundTarget": "double",
    "categoryPreferences": {
      "key": "dynamic"
    }
  },
  "financialGoals": [
    {
      "title": "String",
      "targetAmount": "double",
      "currentAmount": "double",
      "deadline": "String (ISO 8601)",
      "isCompleted": "bool"
    }
    maximum of goal is 3;
  ],
  "analysisDate": "String (ISO 8601)"
}
```

## Response Format

```json
{
  "summary": {
    "overallFinancialHealth": "String",
    "keyFinding": "String",
    "nextStepRecommendation": "String"
  },
  "behavioralInsights": {
    "spendingPersona": "String",
    "keyBehavioralTraits": [
      "String"
    ],
    "profileAlignment": {
      "spendingMentalityComment": "String",
      "riskAppetiteComment": "String",
      "alignmentScore": "double"
    },
    "consistencyScore": "double"
  },
  "spendingPatterns": {
    "period": "String",
    "totalSpending": "double",
    "currency": "String",
    "byCategory": [
      {
        "categoryName": "String",
        "totalSpent": "double",
        "percentageOfTotal": "double"
      }
    ]
  },
  "goalHealth": [
    {
      "goalTitle": "String",
      "progressPercentage": "double",
      "projectedCompletionDate": "String (ISO 8601) | null",
      "onTrackStatus": "String",
      "statusComment": "String"
    }
  ],
  "budgetHealth": [
    {
      "categoryName": "String",
      "allocatedBudget": "double",
      "actualSpending": "double",
      "variance": "double",
      "status": "String"
    }
  ],
  "actionableInsights": [
    {
      "insightId": "String",
      "title": "String",
      "description": "String",
      "category": "String",
      "priority": "String",
      "estimatedImpact": {
        "monthlySavings": "String",
        "effectOnGoal": "String"
      }
    }
  ],
  "metadata": {
    "analysisTimestamp": "String (ISO 8601)",
    "aiModel": "String",
    "version": "String",
    "dataQualityScore": "double"
  }
}
``` 