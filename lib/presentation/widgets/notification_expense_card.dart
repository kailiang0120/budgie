import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/category.dart';
import '../utils/category_manager.dart';
import '../../data/infrastructure/services/settings_service.dart';
import '../../data/infrastructure/services/data_collection_service.dart';
import '../../di/injection_container.dart' as di;

enum ExpenseCardStep { confirm, category, remark, saving }

class NotificationExpenseCard extends StatefulWidget {
  final Map<String, dynamic> expenseData;
  final VoidCallback? onExpenseSaved;
  final VoidCallback? onDismissed;

  const NotificationExpenseCard({
    super.key,
    required this.expenseData,
    this.onExpenseSaved,
    this.onDismissed,
  });

  @override
  State<NotificationExpenseCard> createState() =>
      _NotificationExpenseCardState();
}

class _NotificationExpenseCardState extends State<NotificationExpenseCard>
    with TickerProviderStateMixin {
  ExpenseCardStep _currentStep = ExpenseCardStep.confirm;
  Category? _selectedCategory;
  final TextEditingController _remarkController = TextEditingController();

  // Enhanced animation controllers for spectacular rise-up effect
  late AnimationController _riseAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;

  // Individual animations for the rise effect
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize multiple animation controllers for spectacular effect
    _riseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Create slide animation - rises from bottom of screen
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.5), // Start from below screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _riseAnimationController,
      curve: Curves.elasticOut, // Bouncy effect
    ));

    // Create fade animation - starts invisible
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOutQuart,
    ));

    // Create scale animation - starts smaller and grows
    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.elasticOut,
    ));

    // Create shadow animation - shadow intensifies as card rises
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _riseAnimationController,
      curve: Curves.easeOut,
    ));

    // Start the spectacular entrance animation sequence
    _startEntranceAnimation();
  }

  void _startEntranceAnimation() async {
    // Start all animations with slight delays for a cascading effect
    _fadeAnimationController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _scaleAnimationController.forward();

    await Future.delayed(const Duration(milliseconds: 50));
    _riseAnimationController.forward();
  }

  @override
  void dispose() {
    _riseAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      switch (_currentStep) {
        case ExpenseCardStep.confirm:
          _currentStep = ExpenseCardStep.category;
          break;
        case ExpenseCardStep.category:
          _currentStep = ExpenseCardStep.remark;
          break;
        case ExpenseCardStep.remark:
          _currentStep = ExpenseCardStep.saving;
          _saveExpense();
          break;
        case ExpenseCardStep.saving:
          break;
      }
    });
  }

  void _previousStep() {
    setState(() {
      switch (_currentStep) {
        case ExpenseCardStep.confirm:
          break;
        case ExpenseCardStep.category:
          _currentStep = ExpenseCardStep.confirm;
          break;
        case ExpenseCardStep.remark:
          _currentStep = ExpenseCardStep.category;
          break;
        case ExpenseCardStep.saving:
          break;
      }
    });
  }

  void _dismiss() {
    // Spectacular exit animation
    _fadeAnimationController.reverse();
    _scaleAnimationController.reverse();
    _riseAnimationController.reverse().then((_) {
      widget.onDismissed?.call();
    });
  }

  Future<void> _saveExpense() async {
    try {
      final amount =
          double.tryParse(widget.expenseData['amount'].toString()) ?? 0.0;
      final merchant = widget.expenseData['merchant']?.toString() ?? 'Unknown';
      final currency = widget.expenseData['currency']?.toString() ??
          Provider.of<SettingsService>(context, listen: false).currency;

      // Create expense document matching the main app structure exactly
      final remarkText = _remarkController.text.trim().isEmpty
          ? 'Auto-detected from $merchant'
          : _remarkController.text.trim();

      final expenseDoc = {
        'amount': amount,
        'currency': currency,
        'date': Timestamp.fromDate(DateTime.now()),
        'category': _selectedCategory?.id ?? Category.others.id,
        'description': "One-time Payment", // Main description field
        'method': 'eWallet', // Payment method matching the enum
        'remark': remarkText, // Additional remark field
        'recurringExpenseId': null,
      };

      debugPrint('Expense document structure matches main app format');

      // Debug: Print the expense document before saving
      debugPrint('Saving expense document: $expenseDoc');

      // Check authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      debugPrint('Current user: ${currentUser.uid}');

      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection');
      }
      debugPrint('Network connectivity: $connectivityResult');

      // Save to Firestore expenses collection with detailed error handling
      // Use the same structure as the main app: users/{userId}/expenses
      String? savedExpenseId;
      try {
        final userId = widget.expenseData['userId'];
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('expenses')
            .add(expenseDoc)
            .timeout(const Duration(seconds: 10)); // Add timeout

        savedExpenseId = docRef.id; // Capture the expense ID
        debugPrint(
            'Expense saved successfully with ID: ${docRef.id} for user: $userId');
      } catch (firestoreError) {
        debugPrint('Firestore specific error: $firestoreError');

        // Try to diagnose the issue
        try {
          // Test basic Firestore connectivity using the same path structure
          final userId = widget.expenseData['userId'];
          final testQuery = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('expenses')
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 5));
          debugPrint(
              'Firestore connection test: ${testQuery.docs.length} documents found for user: $userId');
        } catch (connectivityError) {
          debugPrint('Firestore connectivity test failed: $connectivityError');
        }

        rethrow; // Re-throw the original error
      }

      // Record data for notification record service
      try {
        final dataCollector = di.sl<DataCollectionService>();
        await dataCollector.recordNotificationExpense({
          'amount': amount,
          'currency': currency,
          'category': (_selectedCategory ?? Category.others).id,
          'merchant': merchant,
          'isAutoDetected': true,
          'detectionMethod': 'notification_parsing',
          'source': widget.expenseData['source']?.toString() ?? 'Unknown App',
          'confidence': widget.expenseData['confidence'],
          'originalText':
              widget.expenseData['notificationContent']?.toString() ??
                  widget.expenseData['originalNotification']?.toString() ??
                  widget.expenseData['fullNotification']?.toString() ??
                  'Unknown notification',
          'userRemark': _remarkController.text.trim(),
          'expenseId': savedExpenseId,
          'expenseTimestamp': DateTime.now().toIso8601String(),
          'originalNotificationData': widget.expenseData,
        });
        debugPrint('📊 Notification record data recorded successfully');
      } catch (recordError) {
        // Don't fail the expense saving if notification record fails
        debugPrint(
            '📊 Failed to record notification record data: $recordError');
      }

      // Remove from auto-detected collection if it exists
      if (widget.expenseData['docId'] != null) {
        await FirebaseFirestore.instance
            .collection('auto_detected_expenses')
            .doc(widget.expenseData['docId'])
            .delete();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Expense of $currency ${amount.toStringAsFixed(2)} saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Animate out and notify parent
      await _fadeAnimationController.reverse();
      await _scaleAnimationController.reverse();
      await _riseAnimationController.reverse();
      widget.onExpenseSaved?.call();
    } catch (e, stackTrace) {
      debugPrint('Error saving expense: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final amount = widget.expenseData['amount']?.toString() ?? '0';
    final merchant = widget.expenseData['merchant']?.toString() ?? 'Unknown';
    final source = widget.expenseData['source']?.toString() ?? 'Unknown App';
    final currency = widget.expenseData['currency']?.toString() ??
        Provider.of<SettingsService>(context, listen: false).currency;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _riseAnimationController,
        _fadeAnimationController,
        _scaleAnimationController,
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: EdgeInsets.all(20.w),
                constraints: BoxConstraints(maxWidth: 400.w),
                decoration: BoxDecoration(
                  // Proper theme-aware colors
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: isDarkMode
                      ? Border.all(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.3),
                          width: 1.w,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: (isDarkMode ? Colors.black : Colors.black)
                          .withOpacity(isDarkMode ? 0.4 : 0.15),
                      blurRadius: (20 * _shadowAnimation.value).r,
                      spreadRadius: (5 * _shadowAnimation.value).r,
                      offset: Offset(0, (8 * _shadowAnimation.value).h),
                    ),
                    // Additional glow effect for dark mode
                    if (isDarkMode)
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        blurRadius: (30 * _shadowAnimation.value).r,
                        spreadRadius: (2 * _shadowAnimation.value).r,
                        offset: Offset(0, (4 * _shadowAnimation.value).h),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with improved theming
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        // Use theme-aware background colors
                        color: isDarkMode
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15)
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16.sp,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'AI Detected',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _dismiss,
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            tooltip: 'Dismiss',
                          ),
                        ],
                      ),
                    ),

                    // Content with proper theming
                    Container(
                      color: Theme.of(context)
                          .cardColor, // Ensure proper card background
                      padding: EdgeInsets.all(20.w),
                      child:
                          _buildStepContent(amount, merchant, source, currency),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(
      String amount, String merchant, String source, String currency) {
    switch (_currentStep) {
      case ExpenseCardStep.confirm:
        return _buildConfirmStep(amount, merchant, source, currency);
      case ExpenseCardStep.category:
        return _buildCategoryStep();
      case ExpenseCardStep.remark:
        return _buildRemarkStep();
      case ExpenseCardStep.saving:
        return _buildSavingStep();
    }
  }

  Widget _buildConfirmStep(
      String amount, String merchant, String source, String currency) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Detected',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        SizedBox(height: 16.h),

        // Amount display with proper theming
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            // Theme-aware background for amount container
            color: isDarkMode
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: isDarkMode
                ? Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 1.w,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.attach_money,
                color: Theme.of(context).colorScheme.primary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '$currency $amount',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Details with proper theming
        _buildDetailRow(Icons.store, 'Merchant', merchant),
        _buildDetailRow(Icons.source, 'Source', source),
        SizedBox(height: 24.h),

        // Question
        Text(
          'Is this an expense you want to record?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        SizedBox(height: 16.h),

        // Action buttons with improved styling
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _dismiss,
                icon: Icon(Icons.close, size: 16.sp),
                label: const Text('No, dismiss'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextStep,
                icon: Icon(Icons.check, size: 16.sp),
                label: const Text('Yes, record it'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _previousStep,
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Text(
                'Select Category',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        Text(
          'What category does this expense belong to?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        SizedBox(height: 24.h),

        // Category grid selection with improved theming
        Container(
          constraints: BoxConstraints(maxHeight: 300.h),
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
            ),
            itemCount: CategoryManager.allCategories.length,
            itemBuilder: (context, index) {
              final category = CategoryManager.allCategories[index];
              final isSelected = _selectedCategory == category;
              final categoryColor = CategoryManager.getColor(category);
              final categoryIcon = CategoryManager.getIcon(category);
              final categoryName = CategoryManager.getName(category);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    // Theme-aware category container background
                    color: isSelected
                        ? categoryColor.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? categoryColor
                          : Theme.of(context).dividerColor,
                      width: isSelected ? 2.w : 1.w,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        categoryIcon,
                        color: isSelected
                            ? categoryColor
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            color: isSelected
                                ? categoryColor
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: categoryColor,
                          size: 16.sp,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24.h),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: Icon(Icons.arrow_back, size: 16.sp),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedCategory != null ? _nextStep : null,
                icon: Icon(Icons.arrow_forward, size: 16.sp),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRemarkStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _previousStep,
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Text(
                'Add Remark',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        Text(
          'Add a remark for this expense (optional)',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        SizedBox(height: 16.h),

        // Remark input with proper theming
        TextField(
          controller: _remarkController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'e.g., Coffee with friends',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          maxLines: 2,
        ),
        SizedBox(height: 8.h),

        Text(
          'Payment method: E-wallet (One-time)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        SizedBox(height: 24.h),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: Icon(Icons.arrow_back, size: 16.sp),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextStep,
                icon: Icon(Icons.save, size: 16.sp),
                label: const Text('Save Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavingStep() {
    return Column(
      children: [
        SizedBox(height: 20.h),
        CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: 16.h),
        Text(
          'Saving expense...',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          SizedBox(width: 8.w),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
