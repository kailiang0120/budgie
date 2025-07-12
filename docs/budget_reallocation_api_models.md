# Budget Reallocation API Models

This document outlines the JSON structure for the request and response of the `BudgetReallocationService`.

## Request Format

```json
{
  "userProfile": {
    "userId": "string",
    "primaryFinancialGoal": "string",
    "incomeStability": "string",
    "spendingMentality": "string",
    "riskAppetite": "string",
    "monthlyIncome": "double",
    "emergencyFundTarget": "double",
    "aiPreferences": {
      "automationLevel": "string",
      "preferredReallocationStrategy": "string"
    },
    "categoryPreferences": {
      "essentialCategories": ["string"],
      "discretionaryCategories": ["string"],
      "savingsAndInvestments": ["string"]
    }
  },
  "currentBudget": {
    "total": "double",
    "left": "double",
    "categories": {
      "categoryId_1": {
        "budget": "double",
        "left": "double"
      }
      "categoryId_2": {
        "budget": "double",
        "left": "double"
      }
    },
    "saving": "double",
    "currency": "string"
  },
  "recentExpenses": [
    {
      "amount": "double",
      "categoryId": "string",
      "date": "string (ISO 8601)",
      "currency": "string",
      "remark": "string",
      "description": "string | null",
      "method": "string",
      "recurringDetails": {
        "frequency": "string",
        "endDate": "string (ISO 8601) | null"
      } | null
    }
  ],
  "goals": [
    {
      "title": "string",
      "targetAmount": "double",
      "currentAmount": "double",
      "deadline": "string (ISO 8601)",
      "isCompleted": "bool"
    }
  ],
  "spendingAnalysis": {
    "summary": {
      "overallFinancialHealth": "string",
      "keyFinding": "string",
      "nextStepRecommendation": "string"
    },
    "behavioralInsights": {
      "spendingPersona": "string",
      "keyBehavioralTraits": ["string"],
      "profileAlignment": {
        "spendingMentalityComment": "string",
        "riskAppetiteComment": "string",
        "alignmentScore": "double"
      },
      "consistencyScore": "double"
    },
    "spendingPatterns": {
      "period": "string",
      "totalSpending": "double",
      "currency": "string",
      "byCategory": [
        {
          "categoryName": "string",
          "totalSpent": "double",
          "percentageOfTotal": "double"
        }
      ]
    },
    "goalHealth": [
      {
        "goalTitle": "string",
        "healthStatus": "string",
        "progressPercentage": "double",
        "projectedCompletionDate": "string (ISO 8601)",
        "recommendation": "string"
      }
    ],
    "budgetHealth": [
      {
        "categoryName": "string",
        "healthStatus": "string",
        "spent": "double",
        "budgeted": "double",
        "recommendation": "string"
      }
    ],
    "actionableInsights": [
      {
        "insightType": "string",
        "description": "string",
        "action": "string",
        "priority": "string"
      }
    ],
    "metadata": {
      "analysisId": "string",
      "generatedAt": "string (ISO 8601)",
      "modelVersion": "string"
    }
  }
}
```

## Response Format

```json
{
  "suggestions": [
    {
      "fromCategory": "string",
      "toCategory": "string",
      "amount": "double",
      "criticality": "string",
      "reason": "string"
    }
  ]
}
``` 