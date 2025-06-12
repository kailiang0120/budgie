import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  ExpenseCardStep _currentStep = ExpenseCardStep.confirm;
  Category? _selectedCategory;
  final TextEditingController _remarkController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    _animationController.reverse().then((_) {
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
      await _animationController.reverse();
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
    final amount = widget.expenseData['amount']?.toString() ?? '0';
    final merchant = widget.expenseData['merchant']?.toString() ?? 'Unknown';
    final source = widget.expenseData['source']?.toString() ?? 'Unknown App';
    final currency = widget.expenseData['currency']?.toString() ??
        Provider.of<SettingsService>(context, listen: false).currency;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(20.0),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.15).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha((255 * 0.1).toInt()),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Auto-detected',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildStepContent(amount, merchant, source, currency),
            ),
          ],
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Detected',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Amount display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.attach_money,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
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
        const SizedBox(height: 16),

        // Details
        _buildDetailRow(Icons.store, 'Merchant', merchant),
        _buildDetailRow(Icons.source, 'Source', source),
        const SizedBox(height: 24),

        // Question
        Text(
          'Is this an expense you want to record?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _dismiss,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('No, dismiss'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextStep,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Yes, record it'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
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
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Select Category',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text(
          'What category does this expense belong to?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),

        // Category grid selection
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? categoryColor.withAlpha((255 * 0.2).toInt())
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? categoryColor
                          : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                                .withAlpha((255 * 0.7).toInt()),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            color: isSelected
                                ? categoryColor
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: categoryColor,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedCategory != null ? _nextStep : null,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
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
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Add Remark',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text(
          'Add a remark for this expense (optional)',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),

        // Remark input
        TextField(
          controller: _remarkController,
          decoration: const InputDecoration(
            hintText: 'e.g., Coffee with friends',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),

        Text(
          'Payment method: E-wallet (One-time)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withAlpha((255 * 0.7).toInt()),
              ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextStep,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save Expense'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
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
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Saving expense...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withAlpha((255 * 0.7).toInt()),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
