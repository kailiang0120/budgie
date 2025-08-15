import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/user_behavior_profile.dart';
import '../../domain/repositories/user_behavior_repository.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_dropdown_field.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/submit_button.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class FinancialProfileScreen extends StatefulWidget {
  final UserBehaviorProfile? existingProfile;
  final UserBehaviorRepository userBehaviorRepository;

  const FinancialProfileScreen({
    super.key,
    this.existingProfile,
    required this.userBehaviorRepository,
  });

  @override
  State<FinancialProfileScreen> createState() => _FinancialProfileScreenState();
}

class _FinancialProfileScreenState extends State<FinancialProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  bool _isSubmitting = false;
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form controllers and state
  IncomeStability _selectedIncomeStability = IncomeStability.stable;
  SpendingMentality _selectedSpendingMentality = SpendingMentality.balanced;
  RiskAppetite _selectedRiskAppetite = RiskAppetite.medium;
  FinancialLiteracyLevel _selectedFinancialLiteracy =
      FinancialLiteracyLevel.intermediate;

  FinancialPriority _selectedFinancialPriority = FinancialPriority.saving;
  SavingHabit _selectedSavingHabit = SavingHabit.regular;
  FinancialStressLevel _selectedFinancialStressLevel =
      FinancialStressLevel.moderate;
  Occupation _selectedOccupation = Occupation.employed;

  // Data consent preferences
  bool _dataConsentAccepted = false;

  @override
  void initState() {
    super.initState();
    _initializeFromExistingProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeFromExistingProfile() {
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      debugPrint(
          '📊 FinancialProfileScreen: Loading existing profile for user: ${profile.userId}');
      debugPrint(
          '📊 FinancialProfileScreen: Profile data - Income: ${profile.incomeStability.displayName}, Spending: ${profile.spendingMentality.displayName}');

      setState(() {
        _selectedIncomeStability = profile.incomeStability;
        _selectedSpendingMentality = profile.spendingMentality;
        _selectedRiskAppetite = profile.riskAppetite;
        _selectedFinancialLiteracy = profile.financialLiteracyLevel;
        _selectedFinancialPriority = profile.financialPriority;
        _selectedSavingHabit = profile.savingHabit;
        _selectedFinancialStressLevel = profile.financialStressLevel;
        _selectedOccupation = profile.occupation;
        _dataConsentAccepted = profile.hasDataConsent;
      });

      debugPrint(
          '📊 FinancialProfileScreen: Profile loaded successfully - Data consent: $_dataConsentAccepted');
    } else {
      debugPrint(
          '📊 FinancialProfileScreen: No existing profile found, using default values');
    }
  }

  void _nextStep() {
    // Validate data consent on the last step
    if (_currentStep == _totalSteps - 1 && !_dataConsentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the data usage policy to continue.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

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

    if (!_dataConsentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept the data usage policy to save your profile.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // First, clean up any duplicate profiles for this user
      await widget.userBehaviorRepository
          .cleanupDuplicateProfiles('guest_user');

      final profile = UserBehaviorProfile(
        id: widget.existingProfile?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'guest_user', // Use guest user ID
        incomeStability: _selectedIncomeStability,
        spendingMentality: _selectedSpendingMentality,
        riskAppetite: _selectedRiskAppetite,
        financialLiteracyLevel: _selectedFinancialLiteracy,
        financialPriority: _selectedFinancialPriority,
        savingHabit: _selectedSavingHabit,
        financialStressLevel: _selectedFinancialStressLevel,
        occupation: _selectedOccupation,
        createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        dataConsentAcceptedAt: _dataConsentAccepted ? DateTime.now() : null,
        isComplete: true,
      );

      await widget.userBehaviorRepository.saveUserBehaviorProfile(profile);

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
            _buildIncomeAndRiskStep(),
            _buildBehaviorStep(),
            _buildFinancialLiteracyStep(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavigationButtons(),
    );
  }

  Widget _buildIncomeAndRiskStep() {
    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Income & Financial Profile',
            'Tell us about your income and financial situation',
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
            title: 'Financial Priority',
            icon: Icons.priority_high_rounded,
            iconColor: AppTheme.primaryColor,
            child: Column(
              children: [
                CustomDropdownField<FinancialPriority>(
                  value: _selectedFinancialPriority,
                  items: FinancialPriority.values,
                  labelText: 'What is your current financial priority?',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFinancialPriority = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item.displayName,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    _selectedFinancialPriority.description,
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
            title: 'Saving Habit',
            icon: Icons.savings_rounded,
            iconColor: AppTheme.primaryColor,
            child: Column(
              children: [
                CustomDropdownField<SavingHabit>(
                  value: _selectedSavingHabit,
                  items: SavingHabit.values,
                  labelText: 'How often do you save?',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSavingHabit = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item.displayName,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    _selectedSavingHabit.description,
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
            title: 'Financial Stress Level',
            icon: Icons.sentiment_satisfied_alt_rounded,
            iconColor: AppTheme.warningColor,
            child: Column(
              children: [
                CustomDropdownField<FinancialStressLevel>(
                  value: _selectedFinancialStressLevel,
                  items: FinancialStressLevel.values,
                  labelText: 'How stressed do you feel about your finances?',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFinancialStressLevel = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item.displayName,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    _selectedFinancialStressLevel.description,
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
            title: 'Occupation',
            icon: Icons.work_rounded,
            iconColor: AppTheme.primaryColor,
            child: Column(
              children: [
                CustomDropdownField<Occupation>(
                  value: _selectedOccupation,
                  items: Occupation.values,
                  labelText: 'What is your current occupation?',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedOccupation = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item.displayName,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    _selectedOccupation.description,
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
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
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

  Widget _buildFinancialLiteracyStep() {
    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Financial Literacy & Data Consent',
            'Help us personalize your experience and protect your privacy',
            Icons.psychology_rounded,
          ),
          SizedBox(height: AppConstants.spacingXLarge.h),
          CustomCard.withTitle(
            title: 'Financial Knowledge Level',
            icon: Icons.school_rounded,
            iconColor: AppTheme.primaryColor,
            child: Column(
              children: [
                CustomDropdownField<FinancialLiteracyLevel>(
                  value: _selectedFinancialLiteracy,
                  items: FinancialLiteracyLevel.values,
                  labelText: 'How would you rate your financial knowledge?',
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFinancialLiteracy = value;
                      });
                    }
                  },
                  itemLabelBuilder: (item) => item.displayName,
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    _selectedFinancialLiteracy.description,
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
            title: 'Data Privacy & Consent',
            icon: Icons.privacy_tip_rounded,
            iconColor: AppTheme.warningColor,
            child: Column(
              children: [
                Container(
                  padding: AppConstants.containerPaddingMedium,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium.r),
                  ),
                  child: Text(
                    'We collect your financial data to provide personalized insights and recommendations. Your data is encrypted, never sold to third parties, and you can delete it anytime. By continuing, you consent to our data collection and usage practices.',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeSmall.sp,
                      color: AppTheme.greyTextDark,
                    ),
                  ),
                ),
                SizedBox(height: AppConstants.spacingMedium.h),
                CheckboxListTile(
                  title: Text(
                    'I agree to the data usage policy and consent to data collection',
                    style: TextStyle(
                      fontSize: AppConstants.textSizeMedium.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _dataConsentAccepted,
                  onChanged: (value) {
                    setState(() {
                      _dataConsentAccepted = value ?? false;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
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
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
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

  Widget _buildNavigationButtons() {
    return Container(
      padding: AppConstants.screenPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                  side: const BorderSide(color: AppTheme.primaryColor),
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
