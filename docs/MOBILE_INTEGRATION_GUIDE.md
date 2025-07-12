# BudgieAI FastAPI Backend - Mobile Integration Guide

**Complete Integration Documentation for Mobile Applications**

## 📋 Overview

This FastAPI backend provides three core AI-powered financial services designed for seamless mobile integration:

1. **Expense Detection Service** - Extract structured expense data from notification texts
2. **Spending Behavior Analysis Service** - Comprehensive financial behavior analysis 
3. **Budget Reallocation Service** - AI-powered budget optimization recommendations

## 🌐 Base Configuration

### Base URLs
- **Development**: `http://localhost:8000/v1`
- **Production**: `https://your-api-domain.com/v1`

### Common Headers
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

### Timeout Settings
- **Expense Detection**: 30 seconds
- **Spending Behavior Analysis**: 90 seconds  
- **Budget Reallocation**: 60 seconds
- **Health Checks**: 10 seconds

## 🔄 Integration Workflow

The services are designed to work together in sequence:

```
1. Expense Detection (Process notifications) 
2. Spending Behavior Analysis (Analyze patterns)
3. Budget Reallocation (Get recommendations)
```

---

## 💰 Expense Detection Service

### Endpoint: `POST /v1/expense-detection/extract`

**Purpose**: Extract structured expense data from notification texts (supports single or batch processing)

### Single Expense Request

```json
{
  "title": "Maybank2u: Card Transaction",
  "content": "You've just spent RM 19.60 at HORIZON MIRACLES SDN BHD with your Maybank Debit Card Visa ending 9857. View your receipt now.",
  "timestamp": "2024-09-23T14:30:00Z",
  "source": "com.maybank2u.my",
  "packageName": "com.maybank2u.my"
}
```

### Batch Expense Processing (Multiple Notifications)

For processing multiple expenses at once, send an array of notification objects:

```json
[
  {
    "title": "CIMB OCTO MY",
    "content": "CIMB: FPX Payment RM141.00 to SEAMONEY CAPITAL MALAYSIA accepted on 25-Sep-2024, 17:00:56.",
    "timestamp": "2024-09-25T17:01:00Z",
    "source": "com.cimb.octo",
    "packageName": "com.cimb.octo"
  },
  {
    "title": "Your GrabFood order",
    "content": "Your order from Tealive (RM30.50) is on its way! Your driver, Ahmad, is arriving soon.",
    "timestamp": "2024-09-24T12:35:00Z",
    "source": "com.grab.superapp",
    "packageName": "com.grab.superapp"
  }
]
```

### Response

```json
{
  "amount": 19.60,
  "currency": "MYR",
  "merchant": "HORIZON MIRACLES SDN BHD",
  "paymentMethod": "Debit Card",
  "suggestedCategory": "Shopping",
  "confidence": 0.92,
  "success": true,
  "errorMessage": null
}
```

### Response for Batch Processing

```json
[
  {
    "amount": 141.00,
    "currency": "MYR",
    "merchant": "SEAMONEY CAPITAL MALAYSIA",
    "paymentMethod": "FPX",
    "suggestedCategory": "Shopping",
    "confidence": 0.89,
    "success": true,
    "errorMessage": null
  },
  {
    "amount": 30.50,
    "currency": "MYR", 
    "merchant": "Tealive",
    "paymentMethod": "E-Wallet",
    "suggestedCategory": "Food & Dining",
    "confidence": 0.95,
    "success": true,
    "errorMessage": null
  }
]
```

### Supported Categories
- Food & Dining
- Transportation  
- Shopping
- Utilities
- Healthcare
- Entertainment
- Groceries
- General
- Others

### Error Handling

```json
{
  "amount": null,
  "currency": "MYR",
  "merchant": null,
  "paymentMethod": null,
  "suggestedCategory": null,
  "confidence": 0.2,
  "success": false,
  "errorMessage": "Merchant name not found"
}
```

### Health Check: `GET /v1/expense-detection/health`

```json
{
  "status": "healthy",
  "timestamp": "2024-09-30T10:30:00Z"
}
```

---

## 📊 Spending Behavior Analysis Service

### Endpoint: `POST /v1/spending-behavior/analyze`

**Purpose**: Perform comprehensive financial behavior analysis

### Request Structure

```json
{
  "userProfile": {
    "userId": "user_msia_001",
    "primaryFinancialGoal": "Save for a house down payment",
    "incomeStability": "stable",
    "spendingMentality": "balanced",
    "riskAppetite": "medium",
    "monthlyIncome": 8000.0,
    "emergencyFundTarget": 24000.0,
    "categoryPreferences": {
      "essentialCategories": ["rental", "utilities", "Food", "transportation"],
      "discretionaryCategories": ["entertainment", "shopping", "travel"]
    }
  },
  "financialGoals": [
    {
      "title": "House Down Payment",
      "targetAmount": 100000.0,
      "currentAmount": 25000.0,
      "deadline": "2027-12-31T23:59:59Z",
      "isCompleted": false
    },
    {
      "title": "Build Emergency Fund",
      "targetAmount": 24000.0,
      "currentAmount": 18500.0,
      "deadline": "2025-12-31T23:59:59Z",
      "isCompleted": false
    }
  ],
  "currentBudget": {
    "total": 8000.0,
    "left": 3008.40,
    "categories": {
      "rental": {"budget": 2000.0, "left": 0.0},
      "Food": {"budget": 1500.0, "left": 1239.50},
      "utilities": {"budget": 400.0, "left": 112.90},
      "transportation": {"budget": 600.0, "left": 250.0},
      "entertainment": {"budget": 800.0, "left": 723.0},
      "shopping": {"budget": 500.0, "left": 359.0},
      "education": {"budget": 100.0, "left": 4.0},
      "medical": {"budget": 100.0, "left": 100.0},
      "travel": {"budget": 200.0, "left": 200.0},
      "others": {"budget": 450.0, "left": 420.0}
    },
    "saving": 1750.0,
    "currency": "MYR"
  },
  "historicalExpenses": [
    {
      "amount": 2000.0,
      "categoryId": "rental",
      "categoryName": "rental",
      "date": "2024-09-01T09:00:00Z",
      "description": "Monthly Apartment Rental",
      "remark": "Auto-debit",
      "currency": "MYR",
      "paymentMethod": "bank_transfer",
      "recurringDetails": {
        "frequency": "monthly",
        "endDate": null
      }
    },
    {
      "amount": 150.0,
      "categoryId": "utilities",
      "categoryName": "utilities", 
      "date": "2024-09-03T11:00:00Z",
      "description": "Wi-Fi Bill (TIME)",
      "remark": "Online payment",
      "currency": "MYR",
      "paymentMethod": "credit_card",
      "recurringDetails": {
        "frequency": "monthly",
        "endDate": null
      }
    },
    {
      "amount": 55.0,
      "categoryId": "entertainment",
      "categoryName": "entertainment",
      "date": "2024-09-10T10:00:00Z", 
      "description": "Netflix Premium",
      "remark": "Monthly subscription",
      "currency": "MYR",
      "paymentMethod": "credit_card",
      "recurringDetails": {
        "frequency": "monthly",
        "endDate": null
      }
    }
  ],
  "analysisDate": "2024-09-30T23:59:59Z"
}
```

### Response Structure

```json
{
  "analysis": "The user's spending behavior demonstrates a well-structured approach to financial management with clear priorities for essential expenses. The analysis reveals a 25% budget utilization rate (RM 4,991.60 spent out of RM 8,000 monthly budget), indicating disciplined spending habits aligned with their 'balanced' mentality...\n\n**Financial Health Overview:**\nThe user maintains excellent financial discipline with a savings rate of 21.9% (RM 1,750 monthly). Their current financial position shows strong emergency fund progress at 77% completion (RM 18,500 of RM 24,000 target) and steady house down payment accumulation at 25% (RM 25,000 of RM 100,000 target).\n\n**Spending Behavior Analysis:**\nFixed expenses dominate the spending pattern, consuming 84% of total expenditure through rental (RM 2,000) and utilities (RM 287). This demonstrates mature financial prioritization. Discretionary spending remains controlled across entertainment (RM 77), food (RM 260.5), and shopping (RM 141), totaling only RM 478.5 or 6% of monthly income.\n\n**Category Performance:**\n- Rental: 100% budget utilization (appropriate for fixed housing cost)\n- Food: 17.4% utilization (RM 260.5/RM 1,500) - significant underutilization\n- Utilities: 71.8% utilization (RM 287.1/RM 400) - normal variance\n- Transportation: 58.3% utilization (RM 350/RM 600) - potential reallocation opportunity\n\n**Goal Progress Assessment:**\nThe user is well-positioned to achieve both financial goals within their timelines. Emergency fund completion is projected for Q2 2025 (18 months ahead of schedule). House down payment progress remains on track with current savings rate supporting a 2026-2027 completion timeline.",
  "metadata": {
    "analysis_timestamp": "2024-09-30T15:45:32.123456+00:00",
    "ai_model": "gemini-2.5-pro",
    "version": "2.1.0",
    "user_id": "user_msia_001",
    "analysis_type": "spending_behavior"
  }
}
```

### Multiple Expenses Processing

When sending historical expenses, include all relevant transactions for the analysis period (typically 1-6 months). The service can handle large arrays efficiently:

```json
{
  "historicalExpenses": [
    // Include 20-200+ expense records for comprehensive analysis
    // The service will identify patterns, trends, and anomalies
  ]
}
```

### Health Check: `GET /v1/spending-behavior/health`

```json
{
  "status": "healthy",
  "timestamp": "2024-09-30T10:30:00Z",
  "checks": {
    "ai_model": true,
    "analytics_engine": true,
    "data_processing": true
  }
}
```

---

## 💡 Budget Reallocation Service

### Endpoint: `POST /v1/budget-reallocation/analyze`

**Purpose**: Generate AI-powered budget reallocation recommendations

### Request Structure

```json
{
  "userProfile": {
    "userId": "user_msia_001",
    "primaryFinancialGoal": "Save for a house down payment",
    "incomeStability": "stable",
    "spendingMentality": "balanced",
    "riskAppetite": "medium",
    "monthlyIncome": 8000.0,
    "emergencyFundTarget": 24000.0,
    "aiPreferences": {
      "automationLevel": "moderate",
      "preferredReallocationStrategy": "goal-focused"
    },
    "categoryPreferences": {
      "essentialCategories": ["rental", "utilities", "Food", "transportation"],
      "discretionaryCategories": ["entertainment", "shopping", "travel"],
      "savingsAndInvestments": ["House Down Payment", "Emergency Fund"]
    }
  },
  "currentBudget": {
    "total": 8000.0,
    "left": 3008.40,
    "categories": {
      "rental": {"budget": 2000.0, "left": 0.0},
      "Food": {"budget": 1500.0, "left": 1239.50},
      "utilities": {"budget": 400.0, "left": 112.90},
      "transportation": {"budget": 600.0, "left": 250.0},
      "entertainment": {"budget": 800.0, "left": 723.0},
      "shopping": {"budget": 500.0, "left": 359.0},
      "education": {"budget": 100.0, "left": 4.0},
      "medical": {"budget": 100.0, "left": 100.0},
      "travel": {"budget": 200.0, "left": 200.0},
      "others": {"budget": 450.0, "left": 420.0}
    },
    "saving": 1750.0,
    "currency": "MYR"
  },
  "recentExpenses": [
    {
      "amount": 15.50,
      "categoryId": "Food",
      "date": "2024-09-20T13:00:00Z",
      "currency": "MYR",
      "remark": "Mee goreng",
      "description": "Lunch at Mamak",
      "method": "qr_payment",
      "recurringDetails": null
    },
    {
      "amount": 80.0,
      "categoryId": "Food", 
      "date": "2024-09-21T19:30:00Z",
      "currency": "MYR",
      "remark": "",
      "description": "Pizza Hut with friends",
      "method": "credit_card",
      "recurringDetails": null
    },
    {
      "amount": 22.0,
      "categoryId": "entertainment",
      "date": "2024-09-23T15:00:00Z",
      "currency": "MYR",
      "remark": "Baldur's Gate 3",
      "description": "Steam Game Purchase",
      "method": "online_banking",
      "recurringDetails": null
    },
    {
      "amount": 141.0,
      "categoryId": "shopping",
      "date": "2024-09-25T17:00:56Z",
      "currency": "MYR",
      "remark": "Electronics",
      "description": "Shopee Purchase", 
      "method": "online_banking",
      "recurringDetails": null
    },
    {
      "amount": 350.0,
      "categoryId": "transportation",
      "date": "2024-09-28T10:00:00Z",
      "currency": "MYR",
      "remark": "",
      "description": "Monthly Petrol (Petronas)",
      "method": "credit_card",
      "recurringDetails": {
        "frequency": "monthly",
        "endDate": null
      }
    }
  ],
  "goals": [
    {
      "title": "House Down Payment",
      "targetAmount": 100000.0,
      "currentAmount": 25000.0,
      "deadline": "2027-12-31T23:59:59Z",
      "isCompleted": false
    },
    {
      "title": "Build Emergency Fund",
      "targetAmount": 24000.0,
      "currentAmount": 18500.0,
      "deadline": "2025-12-31T23:59:59Z",
      "isCompleted": false
    }
  ],
  "spendingAnalysis": "The user's spending behavior demonstrates a well-structured approach to financial management with clear priorities for essential expenses. The analysis reveals a 25% budget utilization rate (RM 4,991.60 spent out of RM 8,000 monthly budget), indicating disciplined spending habits aligned with their 'balanced' mentality...\n\n**Financial Health Overview:**\nThe user maintains excellent financial discipline with a savings rate of 21.9% (RM 1,750 monthly). Their current financial position shows strong emergency fund progress at 77% completion (RM 18,500 of RM 24,000 target) and steady house down payment accumulation at 25% (RM 25,000 of RM 100,000 target).\n\n**Spending Behavior Analysis:**\nFixed expenses dominate the spending pattern, consuming 84% of total expenditure through rental (RM 2,000) and utilities (RM 287). This demonstrates mature financial prioritization. Discretionary spending remains controlled across entertainment (RM 77), food (RM 260.5), and shopping (RM 141), totaling only RM 478.5 or 6% of monthly income."
}
```

### Multiple Budget Processing

For applications managing multiple budgets or family accounts, send separate requests for each budget profile, or structure the request with family member data:

```json
{
  "userProfile": {
    // Primary account holder profile
    "userId": "family_primary_001",
    "categoryPreferences": {
      "essentialCategories": ["rental", "utilities", "Food", "transportation"],
      "familyCategories": ["childcare", "education", "medical"], 
      "discretionaryCategories": ["entertainment", "shopping", "travel"]
    }
  },
  "currentBudget": {
    // Combined family budget
    "total": 15000.0,
    "categories": {
      "childcare": {"budget": 1200.0, "left": 800.0},
      "education": {"budget": 800.0, "left": 200.0}
      // ... other categories
    }
  }
}
```

### Response Structure

```json
{
  "suggestions": [
    {
      "fromCategory": "Food",
      "toCategory": "Emergency Fund",
      "amount": 500.0,
      "criticality": "Medium",
      "reason": "Food budget shows 82.6% underutilization (RM 1,239.50 remaining). Reallocating RM 500 to emergency fund accelerates goal completion by 3 months while maintaining adequate food budget of RM 1,000."
    },
    {
      "fromCategory": "entertainment",
      "toCategory": "House Down Payment",
      "amount": 300.0,
      "criticality": "Low", 
      "reason": "Entertainment budget has RM 723 unused with minimal spending pattern. Redirecting RM 300 to house savings maintains entertainment flexibility while boosting long-term goal progress."
    },
    {
      "fromCategory": "others",
      "toCategory": "transportation",
      "amount": 100.0,
      "criticality": "Medium",
      "reason": "Transportation shows consistent RM 350 monthly spending against RM 600 budget. Others category is underutilized. Optimizing transportation budget prevents future overspend."
    }
  ],
  "metadata": {
    "analysis_id": "ba2e7f89-4d6c-4b8a-9e5a-1c3d7f9b2e4a",
    "generated_at": "2024-09-30T15:45:32.123456+00:00",
    "model_version": "2.3.0"
  }
}
```

### Health Check: `GET /v1/budget-reallocation/health`

```json
{
  "status": "healthy",
  "timestamp": "2024-09-30T10:30:00Z",
  "checks": {
    "ai_model": true,
    "optimization_engine": true,
    "data_processing": true
  }
}
```

---

## 🔄 Complete Integration Workflow

### Step 1: Expense Detection (Process Multiple Notifications)

```typescript
// Mobile app collects notifications and sends batch for processing
const notifications = [
  {
    title: "Bank notification 1",
    content: "Transaction details...",
    timestamp: "2024-09-30T10:00:00Z",
    source: "com.bank.app",
    packageName: "com.bank.app"
  },
  // ... more notifications
];

const expenseResults = await fetch('/v1/expense-detection/extract', {
  method: 'POST',
  body: JSON.stringify(notifications),
  headers: { 'Content-Type': 'application/json' }
});
```

### Step 2: Spending Behavior Analysis

```typescript
// Use expense results + existing user data for analysis
const behaviorRequest = {
  userProfile: userProfile,
  financialGoals: goals,
  currentBudget: budget,
  historicalExpenses: [...existingExpenses, ...newExpenses],
  analysisDate: new Date().toISOString()
};

const behaviorAnalysis = await fetch('/v1/spending-behavior/analyze', {
  method: 'POST', 
  body: JSON.stringify(behaviorRequest),
  headers: { 'Content-Type': 'application/json' }
});
```

### Step 3: Budget Reallocation

```typescript
// Use spending analysis result for reallocation recommendations
const reallocationRequest = {
  userProfile: userProfile,
  currentBudget: budget,
  recentExpenses: recentExpenses,
  goals: goals,
  spendingAnalysis: behaviorAnalysis.analysis // Text from step 2
};

const suggestions = await fetch('/v1/budget-reallocation/analyze', {
  method: 'POST',
  body: JSON.stringify(reallocationRequest),
  headers: { 'Content-Type': 'application/json' }
});
```

---

## 🛡️ Error Handling & Best Practices

### HTTP Status Codes

- **200**: Success
- **400**: Bad Request (Invalid input data)
- **422**: Validation Error (Schema mismatch)
- **500**: Internal Server Error
- **503**: Service Unavailable (AI service down)

### Error Response Format

```json
{
  "detail": "Validation error description",
  "errors": [
    {
      "field": "amount",
      "message": "Field required"
    }
  ]
}
```

### Retry Logic

```typescript
async function callWithRetry(endpoint, data, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        body: JSON.stringify(data),
        headers: { 'Content-Type': 'application/json' }
      });
      
      if (response.ok) return await response.json();
      if (response.status >= 500) {
        // Server error - retry
        await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, i)));
        continue;
      } else {
        // Client error - don't retry
        throw new Error(`HTTP ${response.status}: ${await response.text()}`);
      }
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, i)));
    }
  }
}
```

### Health Monitoring

```typescript
// Check service health before critical operations
async function checkServiceHealth() {
  const endpoints = [
    '/v1/expense-detection/health',
    '/v1/spending-behavior/health', 
    '/v1/budget-reallocation/health'
  ];
  
  const healthChecks = await Promise.allSettled(
    endpoints.map(endpoint => fetch(endpoint))
  );
  
  return healthChecks.every(result => 
    result.status === 'fulfilled' && 
    result.value.ok
  );
}
```

---

## 📊 Performance Optimization

### Batch Processing

- **Expense Detection**: Process up to 50 notifications per request
- **Historical Expenses**: Include 1-6 months of data (20-200 transactions)
- **Recent Expenses**: Limit to last 10-20 transactions

### Caching Strategy

```typescript
// Cache spending analysis for reallocation requests
const CACHE_DURATION = 1000 * 60 * 30; // 30 minutes

class AnalysisCache {
  private cache = new Map();
  
  async getSpendingAnalysis(userKey: string, forceRefresh = false) {
    const cached = this.cache.get(userKey);
    if (!forceRefresh && cached && Date.now() - cached.timestamp < CACHE_DURATION) {
      return cached.analysis;
    }
    
    // Fetch new analysis
    const analysis = await this.fetchSpendingAnalysis(userKey);
    this.cache.set(userKey, { analysis, timestamp: Date.now() });
    return analysis;
  }
}
```

### Rate Limiting

- Implement client-side rate limiting (60 requests/minute)
- Use exponential backoff for retries
- Monitor response times and adjust timeout values

---

## 🔐 Security Considerations

### Input Validation

- Validate all monetary amounts (positive numbers)
- Sanitize text inputs (titles, descriptions)
- Verify timestamp formats (ISO 8601)
- Limit payload sizes (max 10MB per request)

### Data Privacy

- Never log sensitive financial data
- Use HTTPS for all communications
- Implement request/response encryption if required
- Follow local data protection regulations

### Authentication (Future Enhancement)

```typescript
// Prepare for future API key or OAuth integration
const headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer your-api-key', // When implemented
  'X-User-ID': 'user-identifier' // For multi-tenant setups
};
```

---

## 🧪 Testing & Validation

### Unit Test Examples

```typescript
describe('Expense Detection Integration', () => {
  test('should handle single notification', async () => {
    const notification = {
      title: "Bank Alert",
      content: "You spent RM 25.50 at Starbucks",
      timestamp: "2024-09-30T10:00:00Z",
      source: "com.bank.app",
      packageName: "com.bank.app"
    };
    
    const result = await expenseDetectionService.extract(notification);
    expect(result.success).toBe(true);
    expect(result.amount).toBe(25.50);
    expect(result.merchant).toBe("Starbucks");
  });
  
  test('should handle batch processing', async () => {
    const notifications = [/* multiple notifications */];
    const results = await expenseDetectionService.extractBatch(notifications);
    expect(Array.isArray(results)).toBe(true);
    expect(results.length).toBe(notifications.length);
  });
});
```

### Integration Test Scenarios

1. **End-to-End Workflow**: Test complete flow from expense detection to budget reallocation
2. **Error Handling**: Test invalid inputs, network failures, service timeouts
3. **Performance**: Test with large datasets, concurrent requests
4. **Edge Cases**: Empty datasets, extreme values, malformed data

---

## 📱 Mobile App Implementation Examples

### React Native Example

```typescript
class BudgieAPIClient {
  private baseURL = 'https://your-api-domain.com/v1';
  
  async detectExpenses(notifications: Notification[]): Promise<ExpenseResult[]> {
    const response = await fetch(`${this.baseURL}/expense-detection/extract`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(notifications),
      timeout: 30000
    });
    
    if (!response.ok) {
      throw new Error(`Expense detection failed: ${response.statusText}`);
    }
    
    return await response.json();
  }
  
  async analyzeSpendingBehavior(request: SpendingAnalysisRequest): Promise<AnalysisResult> {
    const response = await fetch(`${this.baseURL}/spending-behavior/analyze`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request),
      timeout: 90000
    });
    
    if (!response.ok) {
      throw new Error(`Spending analysis failed: ${response.statusText}`);
    }
    
    return await response.json();
  }
  
  async getBudgetRecommendations(request: ReallocationRequest): Promise<ReallocationResult> {
    const response = await fetch(`${this.baseURL}/budget-reallocation/analyze`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request),
      timeout: 60000
    });
    
    if (!response.ok) {
      throw new Error(`Budget reallocation failed: ${response.statusText}`);
    }
    
    return await response.json();
  }
}
```

### Flutter Example

```dart
class BudgieAPIService {
  static const String baseUrl = 'https://your-api-domain.com/v1';
  final Dio _dio = Dio();
  
  Future<List<ExpenseResult>> detectExpenses(List<NotificationModel> notifications) async {
    try {
      final response = await _dio.post(
        '$baseUrl/expense-detection/extract',
        data: notifications.map((n) => n.toJson()).toList(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
        ),
      );
      
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((item) => ExpenseResult.fromJson(item))
            .toList();
      } else {
        throw APIException('Expense detection failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw APIException('Network error: ${e.toString()}');
    }
  }
  
  Future<SpendingAnalysisResult> analyzeSpendingBehavior(SpendingAnalysisRequest request) async {
    try {
      final response = await _dio.post(
        '$baseUrl/spending-behavior/analyze',
        data: request.toJson(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: Duration(seconds: 90),
          receiveTimeout: Duration(seconds: 90),
        ),
      );
      
      if (response.statusCode == 200) {
        return SpendingAnalysisResult.fromJson(response.data);
      } else {
        throw APIException('Spending analysis failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw APIException('Network error: ${e.toString()}');
    }
  }
  
  Future<BudgetReallocationResult> getBudgetRecommendations(BudgetReallocationRequest request) async {
    try {
      final response = await _dio.post(
        '$baseUrl/budget-reallocation/analyze',
        data: request.toJson(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: Duration(seconds: 60),
          receiveTimeout: Duration(seconds: 60),
        ),
      );
      
      if (response.statusCode == 200) {
        return BudgetReallocationResult.fromJson(response.data);
      } else {
        throw APIException('Budget reallocation failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw APIException('Network error: ${e.toString()}');
    }
  }
}
```

---

## 📋 Summary

This FastAPI backend provides three core services optimized for mobile integration:

1. **Expense Detection**: Process single/multiple notifications to extract structured expense data
2. **Spending Behavior Analysis**: Comprehensive financial behavior analysis with detailed insights
3. **Budget Reallocation**: AI-powered budget optimization recommendations

### Key Integration Points:

- **Batch Processing**: All services support processing multiple items for efficiency
- **Sequential Workflow**: Services work together - spending analysis feeds into budget reallocation
- **Comprehensive Error Handling**: Robust error responses with retry logic
- **Performance Optimized**: Appropriate timeouts and batch limits for mobile use
- **Future-Ready**: Designed for authentication, caching, and scaling

### Next Steps:

1. Implement the mobile client using provided examples
2. Test with sample data from the integration guide
3. Implement error handling and retry logic
4. Add health monitoring and performance tracking
5. Prepare for production deployment with proper security measures

This integration guide provides everything needed for a mobile application to successfully integrate with the BudgieAI FastAPI backend services. 