# Budget Reallocation Feature

## Overview

The Budget Reallocation feature uses AI predictions to automatically redistribute your budget between categories when certain categories are predicted to exceed their limits while others have surplus funds.

## How It Works

### 1. AI Analysis
- The Google AI service analyzes your spending patterns
- It predicts future expenses for tomorrow based on your historical data
- The AI identifies categories that might exceed their budget limits
- It also identifies categories with surplus budget that won't be fully used

### 2. Smart Reallocation Logic
- **Categories Needing More**: Categories where predicted expenses exceed available budget
- **Categories With Surplus**: Categories where predicted expenses are significantly less than available budget (>5 units surplus)
- **Safety Margin**: Only 80% of surplus is used for reallocation to maintain safety buffer

### 3. Reallocation Process
- Money is transferred from surplus categories to categories needing more budget
- Both the category budget amounts and remaining amounts are updated
- The total budget amount stays the same - only redistribution occurs
- Changes are automatically saved to your budget

## When Reallocation is Available

The reallocate button (⇄) appears in the AI prediction card when:
1. AI has generated expense predictions
2. At least one category is predicted to exceed its budget
3. At least one category has meaningful surplus (>5 currency units)
4. Total surplus can cover the total shortfall

## When Reallocation is NOT Possible

Reallocation will not work when:
- All categories are predicted to exceed their limits (no surplus available)
- No meaningful surplus exists in any category
- No predictions are available from AI
- Total shortfall exceeds total available surplus

## User Interface

### Analytics Screen
- Navigate to Analytics tab
- Tap the lightbulb icon (💡) to get AI predictions
- If reallocation is possible, you'll see an orange swap icon (⇄) next to refresh/dismiss buttons
- Tap the swap icon to automatically reallocate your budget

### Visual Feedback
- **Success**: Green notification showing successful reallocation
- **Error**: Red notification explaining why reallocation failed
- **Loading**: Button shows loading spinner during reallocation process

## Example Scenario

**Original Budget:**
- Food: $200 (remaining: $150)
- Transportation: $100 (remaining: $30)
- Entertainment: $50 (remaining: $50)

**AI Predictions for Tomorrow:**
- Food: $25 (within budget)
- Transportation: $45 (exceeds remaining $30 by $15)
- Entertainment: $10 (large surplus of $40)

**After Reallocation:**
- Food: $200 (remaining: $150) - unchanged
- Transportation: $115 (remaining: $45) - gained $15
- Entertainment: $35 (remaining: $35) - lost $15 to transportation

## Technical Implementation

### Service Location
- **Service**: `lib/domain/services/budget_reallocation_service.dart`
- **Use Case**: Integrated into analytics screen
- **Dependencies**: Budget repository, AI prediction service

### Error Handling
- Validates budget and prediction data
- Provides specific error messages for different failure scenarios
- Graceful fallback when reallocation is not possible

### Data Safety
- Only redistributes existing budget (no new money created)
- Maintains budget total integrity
- Uses conservative approach (80% of surplus only)
- Automatic saving to preserve changes

## Benefits

1. **Proactive Budget Management**: Prevents budget overruns before they happen
2. **Optimized Spending**: Makes better use of underutilized category budgets
3. **AI-Powered**: Uses intelligent predictions based on your spending patterns
4. **One-Click Solution**: Simple interface for complex budget optimization
5. **Safe Operations**: Conservative approach protects your financial planning

## Tips for Best Results

1. **Regular Use**: Use the AI prediction feature regularly for better accuracy
2. **Consistent Categories**: Use consistent categories for your expenses
3. **Recent Data**: The AI works best with recent expense history (last 14 days)
4. **Budget Balance**: Maintain reasonable budget allocations across categories

This feature helps you stay within budget by intelligently redistributing funds where they're needed most, powered by AI insights into your spending patterns. 