import 'package:flutter/material.dart';
import '../widgets/notification_expense_card.dart';
import '../../core/router/app_router.dart';

class ExpenseCardManagerService {
  static final ExpenseCardManagerService _instance =
      ExpenseCardManagerService._internal();
  factory ExpenseCardManagerService() => _instance;
  ExpenseCardManagerService._internal();

  OverlayEntry? _currentOverlay;
  bool _isShowing = false;

  /// Show enhanced expense card as overlay
  void showExpenseCard(
    BuildContext context,
    Map<String, dynamic> expenseData, {
    VoidCallback? onExpenseSaved,
    VoidCallback? onDismissed,
  }) {
    // Don't show if already showing
    if (_isShowing) return;

    _isShowing = true;
    debugPrint(
        '[ExpenseCardManagerService] Attempting to show card. Context: $context');

    _currentOverlay = OverlayEntry(
      builder: (overlayContext) {
        debugPrint(
            '[ExpenseCardManagerService] OverlayEntry builder called. Overlay Context: $overlayContext');
        return Material(
          color: Colors.black
              .withAlpha((255 * 0.2).toInt()), // Semi-transparent background
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: NotificationExpenseCard(
                  expenseData: expenseData,
                  onExpenseSaved: () {
                    _hideCard();
                    onExpenseSaved?.call();
                  },
                  onDismissed: () {
                    _hideCard();
                    onDismissed?.call();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    // Try multiple approaches to insert the overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[ExpenseCardManagerService] PostFrameCallback executing...');
      if (!_isShowing) {
        debugPrint(
            '[ExpenseCardManagerService] Not showing anymore, aborting...');
        return;
      }
      if (_currentOverlay == null) {
        debugPrint(
            '[ExpenseCardManagerService] Current overlay is null, aborting...');
        return;
      }

      bool inserted = false;

      // Method 1: Try using navigatorKey
      try {
        final navigatorState = navigatorKey.currentState;
        if (navigatorState?.overlay != null) {
          debugPrint(
              '[ExpenseCardManagerService] Trying insertion via navigatorKey...');
          navigatorState!.overlay!.insert(_currentOverlay!);
          debugPrint(
              '[ExpenseCardManagerService] SUCCESS: Overlay inserted via navigatorKey.');
          inserted = true;
        }
      } catch (e) {
        debugPrint(
            '[ExpenseCardManagerService] navigatorKey method failed: $e');
      }

      // Method 2: Try using Overlay.of() with context if first method failed
      if (!inserted) {
        try {
          debugPrint(
              '[ExpenseCardManagerService] Trying insertion via Overlay.of(context)...');
          Overlay.of(context).insert(_currentOverlay!);
          debugPrint(
              '[ExpenseCardManagerService] SUCCESS: Overlay inserted via Overlay.of(context).');
          inserted = true;
        } catch (e) {
          debugPrint(
              '[ExpenseCardManagerService] Overlay.of(context) method failed: $e');
        }
      }

      // Method 3: Try finding OverlayState directly
      if (!inserted) {
        try {
          debugPrint(
              '[ExpenseCardManagerService] Trying insertion via findAncestorStateOfType...');
          final overlayState = context.findAncestorStateOfType<OverlayState>();
          if (overlayState != null) {
            overlayState.insert(_currentOverlay!);
            debugPrint(
                '[ExpenseCardManagerService] SUCCESS: Overlay inserted via findAncestorStateOfType.');
            inserted = true;
          } else {
            debugPrint(
                '[ExpenseCardManagerService] No OverlayState found via findAncestorStateOfType.');
          }
        } catch (e) {
          debugPrint(
              '[ExpenseCardManagerService] findAncestorStateOfType method failed: $e');
        }
      }

      if (!inserted) {
        debugPrint(
            '[ExpenseCardManagerService] ERROR: All overlay insertion methods failed!');
        _isShowing = false;
      }
    });
  }

  /// Hide the current expense card
  void _hideCard() {
    debugPrint(
        '[ExpenseCardManagerService] Attempting to hide card. Current Overlay: $_currentOverlay');
    // If hiding is called before postFrameCallback runs, ensure we nullify overlay
    if (_currentOverlay != null && _currentOverlay!.mounted) {
      _currentOverlay!.remove();
    }
    _currentOverlay = null; // Always nullify
    _isShowing = false;
    debugPrint('[ExpenseCardManagerService] Card hide processed.');
  }

  /// Force hide any visible card
  void hideCard() {
    _hideCard();
  }

  /// Check if card is currently showing
  bool get isShowing => _isShowing;
}
