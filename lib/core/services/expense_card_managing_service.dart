import 'package:flutter/material.dart';
import '../../presentation/widgets/notification_expense_card.dart';
import '../router/app_router.dart';

class ExpenseCardManager {
  static final ExpenseCardManager _instance = ExpenseCardManager._internal();
  factory ExpenseCardManager() => _instance;
  ExpenseCardManager._internal();

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
        '[ExpenseCardManager] Attempting to show card. Context: $context');

    _currentOverlay = OverlayEntry(
      builder: (overlayContext) {
        debugPrint(
            '[ExpenseCardManager] OverlayEntry builder called. Overlay Context: $overlayContext');
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
      debugPrint('[ExpenseCardManager] PostFrameCallback executing...');
      if (!_isShowing) {
        debugPrint('[ExpenseCardManager] Not showing anymore, aborting...');
        return;
      }
      if (_currentOverlay == null) {
        debugPrint('[ExpenseCardManager] Current overlay is null, aborting...');
        return;
      }

      bool inserted = false;

      // Method 1: Try using navigatorKey
      try {
        final navigatorState = navigatorKey.currentState;
        if (navigatorState?.overlay != null) {
          debugPrint(
              '[ExpenseCardManager] Trying insertion via navigatorKey...');
          navigatorState!.overlay!.insert(_currentOverlay!);
          debugPrint(
              '[ExpenseCardManager] SUCCESS: Overlay inserted via navigatorKey.');
          inserted = true;
        }
      } catch (e) {
        debugPrint('[ExpenseCardManager] navigatorKey method failed: $e');
      }

      // Method 2: Try using Overlay.of() with context if first method failed
      if (!inserted) {
        try {
          debugPrint(
              '[ExpenseCardManager] Trying insertion via Overlay.of(context)...');
          Overlay.of(context).insert(_currentOverlay!);
          debugPrint(
              '[ExpenseCardManager] SUCCESS: Overlay inserted via Overlay.of(context).');
          inserted = true;
        } catch (e) {
          debugPrint(
              '[ExpenseCardManager] Overlay.of(context) method failed: $e');
        }
      }

      // Method 3: Try finding OverlayState directly
      if (!inserted) {
        try {
          debugPrint(
              '[ExpenseCardManager] Trying insertion via findAncestorStateOfType...');
          final overlayState = context.findAncestorStateOfType<OverlayState>();
          if (overlayState != null) {
            overlayState.insert(_currentOverlay!);
            debugPrint(
                '[ExpenseCardManager] SUCCESS: Overlay inserted via findAncestorStateOfType.');
            inserted = true;
          } else {
            debugPrint(
                '[ExpenseCardManager] No OverlayState found via findAncestorStateOfType.');
          }
        } catch (e) {
          debugPrint(
              '[ExpenseCardManager] findAncestorStateOfType method failed: $e');
        }
      }

      if (!inserted) {
        debugPrint(
            '[ExpenseCardManager] ERROR: All overlay insertion methods failed!');
        _isShowing = false;
      }
    });
  }

  /// Hide the current expense card
  void _hideCard() {
    debugPrint(
        '[ExpenseCardManager] Attempting to hide card. Current Overlay: $_currentOverlay');
    // If hiding is called before postFrameCallback runs, ensure we nullify overlay
    if (_currentOverlay != null && _currentOverlay!.mounted) {
      _currentOverlay!.remove();
    }
    _currentOverlay = null; // Always nullify
    _isShowing = false;
    debugPrint('[ExpenseCardManager] Card hide processed.');
  }

  /// Force hide any visible card
  void hideCard() {
    _hideCard();
  }

  /// Check if card is currently showing
  bool get isShowing => _isShowing;
}
