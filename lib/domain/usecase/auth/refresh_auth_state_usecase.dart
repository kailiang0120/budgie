import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../../../data/infrastructure/monitoring/performance_monitor.dart';
import '../../../presentation/viewmodels/theme_viewmodel.dart';

/// Use case for refreshing authentication state
class RefreshAuthStateUseCase {
  final AuthRepository _authRepository;
  final ThemeViewModel _themeViewModel;

  RefreshAuthStateUseCase({
    required AuthRepository authRepository,
    required ThemeViewModel themeViewModel,
  })  : _authRepository = authRepository,
        _themeViewModel = themeViewModel;

  /// Execute the refresh auth state use case
  Future<User?> execute() async {
    debugPrint('🔥 Refreshing auth state');
    PerformanceMonitor.startTimer('refresh_auth_state');

    try {
      // Get fresh user data
      final currentUser = await _authRepository.getCurrentUser();

      // Additional debug info
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      debugPrint('🔥 Firebase user: ${firebaseUser?.uid ?? 'Not logged in'}');

      // Handle potential state mismatch
      if (firebaseUser != null && currentUser == null) {
        debugPrint(
            '🔥 State mismatch detected: Firebase user exists but domain user is null');
        await firebaseUser.reload();
        final refreshedUser = await _authRepository.getCurrentUser();

        // Initialize theme if user is authenticated
        if (refreshedUser != null) {
          debugPrint(
              '🔥 Initializing theme for authenticated user: ${refreshedUser.id}');
          await _themeViewModel.initializeForUser(refreshedUser.id);
          debugPrint('🔥 Theme initialization completed for refreshed user');
        }

        return refreshedUser;
      }

      // Initialize theme if user is authenticated
      if (currentUser != null) {
        debugPrint(
            '🔥 Initializing theme for authenticated user: ${currentUser.id}');
        await _themeViewModel.initializeForUser(currentUser.id);
        debugPrint('🔥 Theme initialization completed for refreshed user');
      }

      return currentUser;
    } catch (e) {
      debugPrint('🔥 Error refreshing auth state: $e');
      throw Exception('Failed to refresh authentication state');
    } finally {
      PerformanceMonitor.stopTimer('refresh_auth_state');
    }
  }
}
