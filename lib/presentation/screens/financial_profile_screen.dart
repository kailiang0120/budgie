import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/user_behavior_profile.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/submit_button.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class FinancialProfileScreen extends StatefulWidget {
  final UserBehaviorProfile? existingProfile;

  const FinancialProfileScreen({
    Key? key,
    this.existingProfile,
  }) : super(key: key);

  @override
  State<FinancialProfileScreen> createState() => _FinancialProfileScreenState();
}

class _FinancialProfileScreenState extends State<FinancialProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  bool _isSubmitting = false;
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers and state
  final _monthlyIncomeController = TextEditingController();
  final _emergencyFundController = TextEditingController();

  FinancialGoalType _selectedFinancialGoal = FinancialGoalType.balancedGrowth;
  IncomeStability _selectedIncomeStability = IncomeStability.stable;
  SpendingMentality _selectedSpendingMentality = SpendingMentality.balanced;
  RiskAppetite _selectedRiskAppetite = RiskAppetite.medium;

  // AI Automation preferences
  bool _enableBudgetReallocation = true;
  bool _enableSpendingAlerts = true;
  bool _enableGoalRecommendations = true;
  bool _enableExpenseClassification = true;
  bool _enableSavingsOptimization = true;
  double _automationAggressiveness = 0.5;
  double _alertSensitivity = 0.5;

  @override
  void initState() {
    super.initState();
    _initializeFromExistingProfile();
  }

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    _emergencyFundController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeFromExistingProfile() {
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      _monthlyIncomeController.text = profile.monthlyIncome.toString();
      _emergencyFundController.text = profile.emergencyFundTarget.toString();
      _selectedFinancialGoal = profile.primaryFinancialGoal;
      _selectedIncomeStability = profile.incomeStability;
      _selectedSpendingMentality = profile.spendingMentality;
      _selectedRiskAppetite = profile.riskAppetite;

      final aiPrefs = profile.aiPreferences;
      _enableBudgetReallocation = aiPrefs.enableBudgetReallocation;
      _enableSpendingAlerts = aiPrefs.enableSpendingAlerts;
      _enableGoalRecommendations = aiPrefs.enableGoalRecommendations;
      _enableExpenseClassification = aiPrefs.enableExpenseClassification;
      _enableSavingsOptimization = aiPrefs.enableSavingsOptimization;
      _automationAggressiveness = aiPrefs.automationAggressiveness;
      _alertSensitivity = aiPrefs.alertSensitivity;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: AppConstants.animationDurationMedium,
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: AppConstants.animationDurationMedium,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Implement actual save logic through repository/service
      await Future.delayed(const Duration(seconds: 2)); // Simulate save

      final profile = UserBehaviorProfile(
        id: widget.existingProfile?.id ?? '',
        userId: 'current_user_id', // TODO: Get from auth service
        primaryFinancialGoal: _selectedFinancialGoal,
        incomeStability: _selectedIncomeStability,
        spendingMentality: _selectedSpendingMentality,
        riskAppetite: _selectedRiskAppetite,
        monthlyIncome: double.parse(_monthlyIncomeController.text),
        emergencyFundTarget: double.parse(_emergencyFundController.text),
        aiPreferences: AIAutomationPreferences(
          enableBudgetReallocation: _enableBudgetReallocation,
          enableSpendingAlerts: _enableSpendingAlerts,
          enableGoalRecommendations: _enableGoalRecommendations,
          enableExpenseClassification: _enableExpenseClassification,
          enableSavingsOptimization: _enableSavingsOptimization,
          automationAggressiveness: _automationAggressiveness,
          alertSensitivity: _alertSensitivity,
        ),
        categoryPreferences:
            const CategoryPreferences(), // TODO: Implement category preferences
        createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isComplete: true,
      );

      print('Saving financial profile: ${profile.toMap()}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Financial profile saved successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Your Financial Profile',
          style: TextStyle(
            fontSize: AppConstants.textSizeXLarge.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Column(
            children: [
              Padding(
                padding: AppConstants.screenPaddingHorizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeSmall.sp,
                        color: AppTheme.greyTextLight,
                      ),
                    ),
                    Text(
                      '${((_currentStep + 1) / _totalSteps * 100).round()}% Complete',
                      style: TextStyle(
                        fontSize: AppConstants.textSizeSmall.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppConstants.spacingMedium.h),
              Container(
                margin: AppConstants.screenPaddingHorizontal,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_currentStep + 1) / _totalSteps,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppConstants.spacingMedium.h),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFinancialGoalsStep(),
            _buildIncomeAndRiskStep(),
            _buildBehaviorStep(),
            _buildAutomationStep(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationButtons(),
    );
  }

  Widget _buildFinancialGoalsStep() {
    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Financial Goals & Income',
            'Tell us about your financial priorities and monthly income',
            Icons.account_balance_wallet_rounded,
          ),
          SizedBox(height: AppConstants.spacingXLarge.h),
          CustomCard.withTitle(
            title: 'Primary Financial Goal',
            icon: Icons.flag_rounded,
            iconColor: AppTheme.primaryColor,
            child: Column(
              children: [
                CustomDropdownField<FinancialGoalType>(
                  value: _selectedFinancialGoal,
                  items: FinancialGoalType.values,
                  labelText: 'What\'s your main financial priority?',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFinancialGoal = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item.displayName,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    _selectedFinancialGoal.description,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: AppTheme.greyTextDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppConstants.spacingLarge.h),
          CustomCard.withTitle(
            title: 'Monthly Income',
            icon: Icons.payments_rounded,
            iconColor: AppTheme.successColor,
            child: CustomTextField.currency(
              controller: _monthlyIncomeController,
              labelText: 'Your monthly income',
              currencySymbol: CurrencyFormatter.getCurrencySymbol('MYR'),
              isRequired: true,
              allowZero: false,
            ),
          ),
          SizedBox(height: AppConstants.spacingLarge.h),
          CustomCard.withTitle(
            title: 'Emergency Fund Target',
            icon: Icons.security_rounded,
            iconColor: AppTheme.warningColor,
            child: Column(
              children: [
                CustomTextField.number(
                  controller: _emergencyFundController,
                  labelText: 'Target emergency fund (months of expenses)',
                  isRequired: true,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    'Financial experts recommend 3-6 months of expenses for emergencies.',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: AppTheme.greyTextDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeAndRiskStep() {
    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Income & Risk Profile',
            'Help us understand your income patterns and risk tolerance',
            Icons.trending_up_rounded,
          ),
          SizedBox(height: AppConstants.spacingXLarge.h),
          CustomCard.withTitle(
            title: 'Income Stability',
            icon: Icons.work_rounded,
            iconColor: AppTheme.primaryColor,
            child: Column(
              children: [
                CustomDropdownField<IncomeStability>(
                  value: _selectedIncomeStability,
                  items: IncomeStability.values,
                  labelText: 'How stable is your income?',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedIncomeStability = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item.displayName,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    _selectedIncomeStability.description,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: AppTheme.greyTextDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppConstants.spacingLarge.h),
          CustomCard.withTitle(
            title: 'Risk Appetite',
            icon: Icons.psychology_rounded,
            iconColor: AppTheme.warningColor,
            child: Column(
              children: [
                CustomDropdownField<RiskAppetite>(
                  value: _selectedRiskAppetite,
                  items: RiskAppetite.values,
                  labelText: 'Your comfort level with financial risk',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRiskAppetite = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item.displayName,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    _selectedRiskAppetite.description,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: AppTheme.greyTextDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorStep() {
    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Spending Behavior',
            'Tell us about your spending habits and mentality',
            Icons.shopping_cart_rounded,
          ),
          SizedBox(height: AppConstants.spacingXLarge.h),
          CustomCard.withTitle(
            title: 'Spending Mentality',
            icon: Icons.psychology_rounded,
            iconColor: AppTheme.primaryColor,
            child: Column(
              children: [
                CustomDropdownField<SpendingMentality>(
                  value: _selectedSpendingMentality,
                  items: SpendingMentality.values,
                  labelText: 'How would you describe your spending style?',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSpendingMentality = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item.displayName,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    _selectedSpendingMentality.description,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: AppTheme.greyTextDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationStep() {
    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'AI Automation Preferences',
            'Configure how our AI should help manage your finances',
            Icons.smart_toy_rounded,
          ),
          SizedBox(height: AppConstants.spacingXLarge.h),
          CustomCard.withTitle(
            title: 'AI Features',
            icon: Icons.auto_awesome_rounded,
            iconColor: AppTheme.primaryColor,
            child: Column(
              children: [
                _buildSwitchTile(
                  'Budget Reallocation',
                  'Automatically suggest budget adjustments based on spending patterns',
                  _enableBudgetReallocation,
                  (value) => setState(() => _enableBudgetReallocation = value),
                ),
                _buildSwitchTile(
                  'Spending Alerts',
                  'Get notified when spending exceeds normal patterns',
                  _enableSpendingAlerts,
                  (value) => setState(() => _enableSpendingAlerts = value),
                ),
                _buildSwitchTile(
                  'Goal Recommendations',
                  'Receive personalized financial goal suggestions',
                  _enableGoalRecommendations,
                  (value) => setState(() => _enableGoalRecommendations = value),
                ),
                _buildSwitchTile(
                  'Expense Classification',
                  'Automatically categorize expenses from notifications',
                  _enableExpenseClassification,
                  (value) =>
                      setState(() => _enableExpenseClassification = value),
                ),
                _buildSwitchTile(
                  'Savings Optimization',
                  'Get suggestions for optimizing your savings allocation',
                  _enableSavingsOptimization,
                  (value) => setState(() => _enableSavingsOptimization = value),
                ),
              ],
            ),
          ),
          SizedBox(height: AppConstants.spacingLarge.h),
          CustomCard.withTitle(
            title: 'Automation Settings',
            icon: Icons.tune_rounded,
            iconColor: AppTheme.warningColor,
            child: Column(
              children: [
                _buildSliderSetting(
                  'Automation Aggressiveness',
                  'How proactive should AI recommendations be?',
                  _automationAggressiveness,
                  (value) => setState(() => _automationAggressiveness = value),
                  ['Conservative', 'Balanced', 'Aggressive'],
                ),
                SizedBox(height: AppConstants.spacingLarge.h),
                _buildSliderSetting(
                  'Alert Sensitivity',
                  'How sensitive should spending alerts be?',
                  _alertSensitivity,
                  (value) => setState(() => _alertSensitivity = value),
                  ['Low', 'Medium', 'High'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.spacingMedium.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusLarge.r),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: AppConstants.iconSizeLarge.sp,
              ),
            ),
            SizedBox(width: AppConstants.spacingMedium.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeXLarge.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingXSmall.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: AppTheme.greyTextLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingMedium.h),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: AppConstants.textSizeMedium.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: AppConstants.textSizeSmall.sp,
            color: AppTheme.greyTextLight,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSliderSetting(String title, String subtitle, double value,
      ValueChanged<double> onChanged, List<String> labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppConstants.textSizeMedium.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppConstants.spacingXSmall.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppConstants.textSizeSmall.sp,
            color: AppTheme.greyTextLight,
          ),
        ),
        SizedBox(height: AppConstants.spacingMedium.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.3),
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
            divisions: 10,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map((label) => Text(
                    label,
                    style: TextStyle(
                      fontSize: AppConstants.textSizeXSmall.sp,
                      color: AppTheme.greyTextLight,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: AppConstants.screenPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      vertical: AppConstants.spacingLarge.h),
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: AppConstants.textSizeMedium.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppConstants.spacingMedium.w),
          ],
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: SubmitButton(
              text: _currentStep == _totalSteps - 1 ? 'Save Profile' : 'Next',
              isLoading: _isSubmitting,
              onPressed:
                  _currentStep == _totalSteps - 1 ? _saveProfile : _nextStep,
              icon: _currentStep == _totalSteps - 1
                  ? Icons.save
                  : Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }
}
