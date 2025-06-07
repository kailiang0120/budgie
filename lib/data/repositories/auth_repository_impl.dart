import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of AuthRepository using Firebase Authentication
class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? _initFirebaseAuth(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            ),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize Firebase Auth with persistence settings
  static firebase_auth.FirebaseAuth _initFirebaseAuth() {
    final auth = firebase_auth.FirebaseAuth.instance;

    // Set persistence to LOCAL (this helps with auth state persistence)
    auth.setPersistence(firebase_auth.Persistence.LOCAL);

    debugPrint('Firebase Auth initialized with LOCAL persistence');
    return auth;
  }

  @override
  Stream<domain.User?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _mapFirebaseUserToDomain(firebaseUser);
    });
  }

  /// Map Firebase user to domain User - handle potential null values
  Future<domain.User> _mapFirebaseUserToDomain(firebase_auth.User user) async {
    final displayName = user.displayName?.isNotEmpty == true
        ? user.displayName
        : 'User ${user.uid.substring(0, 5)}';

    // Get user settings from Firestore
    String currency = 'MYR';
    String theme = 'light';

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          currency = userData['currency'] ?? 'MYR';
          theme = userData['theme'] ?? 'light';
        }
      }
    } catch (e) {
      debugPrint('Error fetching user settings: $e');
    }

    return domain.User(
      id: user.uid,
      email: user.email ?? '', // Handle null email
      displayName: displayName,
      photoUrl: user.photoURL,
      currency: currency,
      theme: theme,
    );
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    try {
      // First reload to ensure we have the latest user data
      await _auth.currentUser?.reload();

      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('getCurrentUser: No current user found');
        return null;
      }

      debugPrint(
          'getCurrentUser: Found user: ${user.uid}, email: ${user.email}');
      return await _mapFirebaseUserToDomain(user);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      // Return null instead of throwing to avoid crashes
      return null;
    }
  }

  @override
  Future<domain.User> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in: No user returned');
      }
      return await _mapFirebaseUserToDomain(user);
    } catch (e) {
      debugPrint('Email sign-in error: $e');
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<domain.User> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user: No user returned');
      }
      return await _mapFirebaseUserToDomain(user);
    } catch (e) {
      debugPrint('Create user error: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<domain.User> signInWithGoogle() async {
    try {
      debugPrint('Starting Google sign-in flow');

      // Check if current user is anonymous - if so, link accounts
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint('Current user is anonymous, attempting to link with Google');
        return await linkAnonymousWithGoogle();
      }

      // 1. Always sign out from Google first to ensure we get fresh tokens
      try {
        await _googleSignIn.signOut();
        // Also disconnect to completely clear the previous session
        await _googleSignIn.disconnect();
        debugPrint('Cleared previous Google session');
      } catch (e) {
        debugPrint('Error clearing Google session: $e');
        // Continue anyway
      }

      // 2. Start Google sign-in process with fresh session
      debugPrint('Showing Google sign-in dialog');
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('User canceled Google sign-in');
        throw Exception('Sign-in canceled');
      }

      debugPrint('Google sign-in successful: ${googleUser.email}');

      // 3. Get authentication tokens with server auth code if available
      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('Failed to get Google ID token');
        throw Exception('Authentication failed - missing ID token');
      }

      // 4. Create Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase with try-catch to handle token expiration
      debugPrint('Signing in to Firebase with Google credential');

      firebase_auth.UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } catch (e) {
        debugPrint('Error during credential sign-in: $e');

        // If we get a stale token error, try signing in again with a fresh token
        if (e.toString().contains('stale') ||
            e.toString().contains('expired') ||
            e.toString().contains('invalid-credential')) {
          debugPrint(
              'Got token expiration error, trying again with fresh token');

          // Force disconnect and reconnect
          await _googleSignIn.disconnect();

          // Try the sign-in flow again but don't go into an infinite loop
          final freshGoogleUser = await _googleSignIn.signIn();

          if (freshGoogleUser == null) {
            throw Exception('Failed to get fresh Google account');
          }

          final freshAuth = await freshGoogleUser.authentication;
          final freshCredential = firebase_auth.GoogleAuthProvider.credential(
            accessToken: freshAuth.accessToken,
            idToken: freshAuth.idToken,
          );

          userCredential = await _auth.signInWithCredential(freshCredential);
        } else {
          // Rethrow other errors
          rethrow;
        }
      }

      final user = userCredential.user;

      if (user == null) {
        debugPrint('Firebase sign-in failed - null user');
        throw Exception('Sign-in failed');
      }

      debugPrint('Firebase sign-in successful: ${user.uid}');

      // 6. Immediately return the mapped user without any additional processing
      final domainUser = await _mapFirebaseUserToDomain(user);

      debugPrint('Returning user: ${domainUser.id}');
      return domainUser;
    } catch (e) {
      debugPrint('Google sign-in error: $e');

      if (e.toString().contains('network_error') ||
          e.toString().contains('ApiException: 7')) {
        throw Exception(
            'Network connection issue. Check your internet connection and try again.');
      } else if (e.toString().contains('stale') ||
          e.toString().contains('expired') ||
          e.toString().contains('invalid-credential')) {
        throw Exception(
            'Authentication token expired. Please try signing in again.');
      }

      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Helper method to link anonymous account with Google
  Future<domain.User> linkAnonymousWithGoogle() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      if (!currentUser.isAnonymous) {
        throw Exception('Current user is not an anonymous user');
      }

      debugPrint('Linking anonymous account to Google');

      // Store anonymous user ID for potential data migration
      final anonymousUserId = currentUser.uid;

      // Clear any previous Google sessions to get fresh tokens
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
        debugPrint('Cleared previous Google session for linking');
      } catch (e) {
        debugPrint('Error clearing Google session for linking: $e');
        // Continue anyway
      }

      // Start Google sign-in flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in canceled');
        throw Exception('Google sign-in canceled');
      }

      // Get Google authentication tokens
      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link anonymous account with Google credential with token expiration handling
      firebase_auth.UserCredential userCredential;
      try {
        userCredential = await currentUser.linkWithCredential(credential);

        // If linking succeeds, update the user document
        final user = userCredential.user;
        if (user != null) {
          // Update user document to remove guest flag
          await _firestore.collection('users').doc(user.uid).update({
            'isGuest': false,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint('Successfully linked anonymous account to Google');
          return await _mapFirebaseUserToDomain(user);
        } else {
          throw Exception('Failed to link account: No user returned');
        }
      } catch (e) {
        debugPrint('Error during credential linking: $e');

        // If we get a credential-already-in-use error, handle data migration
        if (e is firebase_auth.FirebaseAuthException &&
            e.code == 'credential-already-in-use') {
          debugPrint('Detected credential already in use. Migrating data...');

          // Get the credential from the error
          final pendingCredential = e.credential;
          if (pendingCredential == null) {
            throw Exception('Failed to get pending credential for migration');
          }

          // Store the anonymous user's data before signing in with the existing account
          Map<String, dynamic>? anonymousUserData;
          try {
            final anonUserDoc =
                await _firestore.collection('users').doc(anonymousUserId).get();
            if (anonUserDoc.exists) {
              anonymousUserData = anonUserDoc.data();
              debugPrint(
                  'Successfully retrieved anonymous user data for migration');
            }
          } catch (fetchError) {
            debugPrint('Error fetching anonymous user data: $fetchError');
            // Continue with sign-in anyway
          }

          // Sign out from anonymous account
          await _auth.signOut();

          // Sign in with the existing Google account
          final googleCredential =
              await _auth.signInWithCredential(pendingCredential);
          final existingUser = googleCredential.user;

          if (existingUser == null) {
            throw Exception('Failed to sign in with existing account');
          }

          debugPrint(
              'Successfully signed in with existing Google account: ${existingUser.uid}');

          // Migrate data from anonymous account to the existing account
          if (anonymousUserData != null) {
            // Remove fields we don't want to overwrite
            anonymousUserData.remove('email');
            anonymousUserData.remove('displayName');
            anonymousUserData.remove('photoURL');

            // Set isGuest to false
            anonymousUserData['isGuest'] = false;
            anonymousUserData['updatedAt'] = FieldValue.serverTimestamp();
            anonymousUserData['previousAnonymousId'] = anonymousUserId;

            // Merge data into existing user document
            await _firestore.collection('users').doc(existingUser.uid).set(
                  anonymousUserData,
                  SetOptions(merge: true),
                );

            debugPrint(
                'Successfully migrated data from anonymous user to existing account');

            // Migrate other collections like expenses, budgets, etc.
            await _migrateUserData(anonymousUserId, existingUser.uid);

            // Delete the anonymous user document after migration
            try {
              await _firestore
                  .collection('users')
                  .doc(anonymousUserId)
                  .delete();
              debugPrint('Deleted anonymous user document after migration');
            } catch (deleteError) {
              debugPrint(
                  'Error deleting anonymous user document: $deleteError');
              // Continue anyway
            }
          }

          // Return the existing user
          return await _mapFirebaseUserToDomain(existingUser);
        } else if (e.toString().contains('stale') ||
            e.toString().contains('expired') ||
            e.toString().contains('invalid-credential')) {
          debugPrint(
              'Got token expiration error, trying again with fresh token');

          // Force disconnect and reconnect
          await _googleSignIn.disconnect();

          // Try the sign-in flow again but don't go into an infinite loop
          final freshGoogleUser = await _googleSignIn.signIn();

          if (freshGoogleUser == null) {
            throw Exception('Failed to get fresh Google account for linking');
          }

          final freshAuth = await freshGoogleUser.authentication;
          final freshCredential = firebase_auth.GoogleAuthProvider.credential(
            accessToken: freshAuth.accessToken,
            idToken: freshAuth.idToken,
          );

          userCredential =
              await currentUser.linkWithCredential(freshCredential);

          final user = userCredential.user;
          if (user == null) {
            throw Exception('Failed to link account: No user returned');
          }

          // Update user document to remove guest flag
          await _firestore.collection('users').doc(user.uid).update({
            'isGuest': false,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint(
              'Successfully linked anonymous account to Google with fresh token');
          return await _mapFirebaseUserToDomain(user);
        } else {
          // Rethrow other errors
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error linking anonymous account with Google: $e');

      if (e.toString().contains('stale') ||
          e.toString().contains('expired') ||
          e.toString().contains('invalid-credential')) {
        throw Exception(
            'Authentication token expired. Please try linking again.');
      }

      throw Exception('Failed to link account with Google: $e');
    }
  }

  /// Helper method to migrate user data from anonymous account to permanent account
  Future<void> _migrateUserData(String fromUserId, String toUserId) async {
    try {
      debugPrint('Starting data migration from $fromUserId to $toUserId');

      // Migrate expenses
      final expenses = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: fromUserId)
          .get();

      debugPrint('Found ${expenses.docs.length} expenses to migrate');

      for (final doc in expenses.docs) {
        final data = doc.data();
        data['userId'] = toUserId;
        data['previousUserId'] = fromUserId;
        data['migratedAt'] = FieldValue.serverTimestamp();

        // Create a new document with the same ID but under the new user
        await _firestore.collection('expenses').doc(doc.id).set(data);
      }

      // Migrate budgets
      final budgets = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: fromUserId)
          .get();

      debugPrint('Found ${budgets.docs.length} budgets to migrate');

      for (final doc in budgets.docs) {
        final data = doc.data();
        data['userId'] = toUserId;
        data['previousUserId'] = fromUserId;
        data['migratedAt'] = FieldValue.serverTimestamp();

        // For budgets, we need to check if a budget already exists for this month
        final monthId = data['monthId'];
        final existingBudget = await _firestore
            .collection('budgets')
            .where('userId', isEqualTo: toUserId)
            .where('monthId', isEqualTo: monthId)
            .get();

        if (existingBudget.docs.isEmpty) {
          // No existing budget, create a new one
          await _firestore
              .collection('budgets')
              .doc('${monthId}_${toUserId}')
              .set(data);
        } else {
          debugPrint('Budget already exists for month $monthId, merging data');
          // Existing budget found, merge the data
          final existingData = existingBudget.docs.first.data();

          // Logic to merge budgets - prefer higher amounts
          if ((data['total'] ?? 0) > (existingData['total'] ?? 0)) {
            existingData['total'] = data['total'];
          }

          // Merge category budgets
          final existingCategories = existingData['categories'] ?? {};
          final newCategories = data['categories'] ?? {};

          newCategories.forEach((category, budget) {
            if (!existingCategories.containsKey(category) ||
                (existingCategories[category]['budget'] ?? 0) <
                    budget['budget']) {
              existingCategories[category] = budget;
            }
          });

          existingData['categories'] = existingCategories;
          existingData['mergedAt'] = FieldValue.serverTimestamp();

          await _firestore
              .collection('budgets')
              .doc(existingBudget.docs.first.id)
              .set(
                existingData,
                SetOptions(merge: true),
              );
        }
      }

      // Migrate recurring expenses
      final recurringExpenses = await _firestore
          .collection('recurring_expenses')
          .where('userId', isEqualTo: fromUserId)
          .get();

      debugPrint(
          'Found ${recurringExpenses.docs.length} recurring expenses to migrate');

      for (final doc in recurringExpenses.docs) {
        final data = doc.data();
        data['userId'] = toUserId;
        data['previousUserId'] = fromUserId;
        data['migratedAt'] = FieldValue.serverTimestamp();

        await _firestore.collection('recurring_expenses').doc(doc.id).set(data);
      }

      debugPrint('Data migration completed successfully');
    } catch (e) {
      debugPrint('Error during data migration: $e');
      // Don't throw here, we want to continue with authentication even if migration fails
    }
  }

  @override
  Future<domain.User> signInAnonymously() async {
    try {
      debugPrint('Starting anonymous sign-in flow');

      // Check if the current user is already anonymous
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint('Reusing existing anonymous user: ${currentUser.uid}');

        // Check if this user exists in Firestore to ensure data consistency
        final userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (!userDoc.exists) {
          // User document doesn't exist, create it
          debugPrint(
              'Creating missing user document for existing anonymous user');
          await _firestore.collection('users').doc(currentUser.uid).set({
            'isGuest': true,
            'createdAt': FieldValue.serverTimestamp(),
            'currency': 'MYR',
            'theme': 'light',
            'settings': {
              'allowNotification': false,
              'autoBudget': false,
              'improveAccuracy': false,
            }
          }, SetOptions(merge: true));
        }

        // Return existing user instead of creating a new one
        return await _mapFirebaseUserToDomain(currentUser);
      }

      // Check if we have a stored guest user ID in shared preferences
      final prefs = await SharedPreferences.getInstance();
      final storedGuestUserId = prefs.getString('last_guest_user_id');

      if (storedGuestUserId != null) {
        debugPrint('Found stored guest user ID: $storedGuestUserId');

        try {
          // Try to sign in with the stored ID
          // First, check if this anonymous user still exists in Firebase Auth
          final isValid = await _checkIfAnonymousUserExists(storedGuestUserId);

          if (isValid) {
            debugPrint(
                'Verified stored guest user is valid, attempting to reuse');

            // If the current user is different or null, sign in with the stored user
            if (currentUser == null || currentUser.uid != storedGuestUserId) {
              // We can't directly sign in as a specific anonymous user,
              // but we can check if the anonymous account has an entry in Firestore
              // and create a new anonymous user if not

              // Create a new anonymous user
              final userCredential = await _auth.signInAnonymously();
              final newUser = userCredential.user;

              if (newUser == null) {
                throw Exception('Failed to create new anonymous user');
              }

              // Try to transfer data from the old anonymous user
              try {
                await _migrateUserData(storedGuestUserId, newUser.uid);
                debugPrint(
                    'Migrated data from stored guest user to new anonymous user');
              } catch (e) {
                debugPrint('Error migrating from stored guest user: $e');
                // Continue with the new user anyway
              }

              // Store the new user ID
              await prefs.setString('last_guest_user_id', newUser.uid);

              // Create initial user document
              await _firestore.collection('users').doc(newUser.uid).set({
                'isGuest': true,
                'createdAt': FieldValue.serverTimestamp(),
                'currency': 'MYR',
                'theme': 'light',
                'previousGuestId': storedGuestUserId,
                'settings': {
                  'allowNotification': false,
                  'autoBudget': false,
                  'improveAccuracy': false,
                }
              }, SetOptions(merge: true));

              return await _mapFirebaseUserToDomain(newUser);
            } else {
              // Current user is already the stored guest user
              return await _mapFirebaseUserToDomain(currentUser);
            }
          } else {
            debugPrint(
                'Stored guest user is invalid, creating new anonymous user');
            // Clear the stored ID since it's invalid
            await prefs.remove('last_guest_user_id');
          }
        } catch (e) {
          debugPrint('Error trying to reuse stored guest user: $e');
          // Continue with creating a new anonymous user
        }
      }

      // Sign in anonymously with Firebase
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user == null) {
        debugPrint('Anonymous sign-in failed - null user');
        throw Exception('Anonymous sign-in failed');
      }

      debugPrint('Anonymous sign-in successful: ${user.uid}');

      // Store the guest user ID for future use
      await prefs.setString('last_guest_user_id', user.uid);

      // Create initial user document with default settings
      await _firestore.collection('users').doc(user.uid).set({
        'isGuest': true,
        'createdAt': FieldValue.serverTimestamp(),
        'currency': 'MYR',
        'theme': 'light',
        'settings': {
          'allowNotification': false,
          'autoBudget': false,
          'improveAccuracy': false,
        }
      }, SetOptions(merge: true));

      // Map to domain user and return
      final domainUser = await _mapFirebaseUserToDomain(user);
      return domainUser;
    } catch (e) {
      debugPrint('Anonymous sign-in error: $e');
      throw Exception('Failed to sign in anonymously: $e');
    }
  }

  /// Check if an anonymous user exists in Firebase
  Future<bool> _checkIfAnonymousUserExists(String userId) async {
    try {
      // Get the currently signed-in Firebase user
      final firebaseUser = _auth.currentUser;

      // If there's already a signed-in user with a different ID, it's likely invalid
      if (firebaseUser != null && firebaseUser.uid != userId) {
        debugPrint('🔥 AuthRepository: Found different user ID than requested');
        return false;
      }

      // Try to see if we have this user in Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        debugPrint('🔥 AuthRepository: Found user document in Firestore');
        // The user exists in Firestore, which means it's a valid user
        return true;
      }

      // If we reach here, we couldn't verify the user exists
      debugPrint('🔥 AuthRepository: Could not verify user existence');
      return false;
    } catch (e) {
      debugPrint(
          '🔥 AuthRepository: Error checking if anonymous user exists: $e');
      return false;
    }
  }

  /// Delete guest user and all associated data
  @override
  Future<void> deleteGuestUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || !currentUser.isAnonymous) {
        throw Exception('No anonymous user to delete');
      }

      final userId = currentUser.uid;
      debugPrint('Deleting guest user and all associated data: $userId');

      try {
        // Try to delete user data first, but continue if permission denied
        await _deleteUserDataFromFirestore(userId);
      } catch (e) {
        // Log the error but continue with deleting the user account
        debugPrint('Warning: Could not delete user data: $e');
        debugPrint('Continuing with authentication account deletion anyway');
      }

      // Delete the Authentication user account (this also signs them out)
      await currentUser.delete();

      debugPrint(
          'Guest user authentication account successfully deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting guest user: $e');
      throw Exception('Failed to delete guest user: $e');
    }
  }

  /// Delete all user data from Firestore
  Future<void> _deleteUserDataFromFirestore(String userId) async {
    debugPrint('Attempting to delete all Firestore data for user: $userId');

    // Keep track of what was deleted
    bool anyDataDeleted = false;

    // Delete user document
    try {
      await _firestore.collection('users').doc(userId).delete();
      debugPrint('Deleted user document');
      anyDataDeleted = true;
    } catch (e) {
      debugPrint('Error deleting user document: $e');
      // Continue with other deletions
    }

    // Delete user's expenses
    try {
      final expenses = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in expenses.docs) {
        try {
          await doc.reference.delete();
        } catch (e) {
          debugPrint('Error deleting expense document ${doc.id}: $e');
        }
      }
      debugPrint('Attempted to delete ${expenses.docs.length} expenses');
      if (expenses.docs.isNotEmpty) anyDataDeleted = true;
    } catch (e) {
      debugPrint('Error querying expenses: $e');
    }

    // Delete user's budgets
    try {
      final budgets = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in budgets.docs) {
        try {
          await doc.reference.delete();
        } catch (e) {
          debugPrint('Error deleting budget document ${doc.id}: $e');
        }
      }
      debugPrint('Attempted to delete ${budgets.docs.length} budgets');
      if (budgets.docs.isNotEmpty) anyDataDeleted = true;
    } catch (e) {
      debugPrint('Error querying budgets: $e');
    }

    // Delete user's recurring expenses
    try {
      final recurringExpenses = await _firestore
          .collection('recurring_expenses')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in recurringExpenses.docs) {
        try {
          await doc.reference.delete();
        } catch (e) {
          debugPrint('Error deleting recurring expense document ${doc.id}: $e');
        }
      }
      debugPrint(
          'Attempted to delete ${recurringExpenses.docs.length} recurring expenses');
      if (recurringExpenses.docs.isNotEmpty) anyDataDeleted = true;
    } catch (e) {
      debugPrint('Error querying recurring expenses: $e');
    }

    // Report on the overall result
    if (anyDataDeleted) {
      debugPrint('Successfully deleted some data for user: $userId');
    } else {
      debugPrint('Warning: No data was deleted for user: $userId');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      debugPrint('Starting sign out process');

      // Check if the user is anonymous before signing out
      final currentUser = _auth.currentUser;
      final isAnonymous = currentUser?.isAnonymous ?? false;

      // For regular users, just sign out from Google and Firebase
      if (!isAnonymous) {
        // Sign out from Google first
        try {
          await _googleSignIn.signOut();
          debugPrint('Successfully signed out from Google');
        } catch (e) {
          debugPrint('Error signing out from Google: $e');
          // Continue with Firebase sign out
        }

        // Then sign out from Firebase
        await _auth.signOut();
        debugPrint('Successfully signed out from Firebase');
      }
      // For anonymous users, we don't need to do anything here since
      // the deleteGuestUser method will be called separately
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to $email');
    } catch (e) {
      debugPrint('Password reset error: $e');
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Cannot update profile: No authenticated user');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
      debugPrint('Profile updated successfully');
    } catch (e) {
      debugPrint('Update profile error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // 更新用户设置
  @override
  Future<void> updateUserSettings({String? currency, String? theme}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Cannot update settings: No authenticated user');
      }

      final Map<String, dynamic> updates = {};
      if (currency != null) updates['currency'] = currency;
      if (theme != null) updates['theme'] = theme;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).set(
              updates,
              SetOptions(merge: true),
            );
        debugPrint('User settings updated successfully');
      }
    } catch (e) {
      debugPrint('Error updating user settings: $e');
      throw Exception('Failed to update user settings: $e');
    }
  }

  // Helper method to link anonymous account with Apple
  Future<domain.User> linkAnonymousWithApple() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      if (!currentUser.isAnonymous) {
        throw Exception('Current user is not an anonymous user');
      }

      debugPrint('Linking anonymous account to Apple');

      // Generate a random nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credentials from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create OAuthCredential for linking
      final oauthCredential =
          firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Link anonymous account with Apple credential
      final userCredential =
          await currentUser.linkWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to link account: No user returned');
      }

      // Update display name if available
      final displayName =
          '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim();
      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      // Update user document to remove guest flag
      await _firestore.collection('users').doc(user.uid).update({
        'isGuest': false,
        'email': user.email,
        'displayName': user.displayName ?? displayName,
        'photoURL': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Successfully linked anonymous account to Apple');

      // Return updated user
      return await _mapFirebaseUserToDomain(user);
    } catch (e) {
      debugPrint('Error linking anonymous account with Apple: $e');
      throw Exception('Failed to link account with Apple: $e');
    }
  }

  @override
  Future<domain.User> signInWithApple() async {
    try {
      debugPrint('Starting Apple sign-in flow');

      // Check if current user is anonymous - if so, link accounts
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint('Current user is anonymous, attempting to link with Apple');
        return await linkAnonymousWithApple();
      }

      // Generate a random nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credentials from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create OAuthCredential for Firebase
      final oauthCredential =
          firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        debugPrint('Firebase sign-in with Apple failed - null user');
        throw Exception('Sign-in failed');
      }

      // If this is a new user, update the display name from Apple credentials
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        if (displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
          await user.reload();
        }
      }

      debugPrint('Firebase sign-in with Apple successful: ${user.uid}');

      // Return the mapped user
      final domainUser = await _mapFirebaseUserToDomain(user);

      debugPrint('Returning user: ${domainUser.id}');
      return domainUser;
    } catch (e) {
      debugPrint('Apple sign-in error: $e');

      if (e.toString().contains('canceled')) {
        throw Exception('Sign-in was cancelled');
      }

      throw Exception('Failed to sign in with Apple: $e');
    }
  }

  /// Generates a cryptographically secure random nonce for Apple sign-in
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA-256 hash of [input] in hex notation
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<domain.User> linkAnonymousAccount(
      {required String email, required String password}) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      if (!currentUser.isAnonymous) {
        throw Exception('Current user is not an anonymous user');
      }

      debugPrint('Linking anonymous account to email: $email');

      // Store the anonymous user ID for potential error handling
      final anonymousUserId = currentUser.uid;

      // Create email credential
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Try to link the anonymous account with the email credential
      try {
        final userCredential = await currentUser.linkWithCredential(credential);
        final user = userCredential.user;

        if (user == null) {
          throw Exception('Failed to link account: No user returned');
        }

        // Update user document to remove guest flag
        await _firestore.collection('users').doc(user.uid).update({
          'isGuest': false,
          'email': email,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('Successfully linked anonymous account to email: $email');
        return await _mapFirebaseUserToDomain(user);
      } catch (e) {
        debugPrint('Error linking anonymous account with email: $e');

        // Handle specific Firebase errors
        if (e is firebase_auth.FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              // This email is already associated with another account
              // Similar to Google sign-in, we could implement data migration here
              // but email/password doesn't provide the credential in the error
              // so we can't directly sign in with it
              throw Exception(
                  'This email is already in use by another account. Please use a different email or sign in with that account.');
            case 'invalid-email':
              throw Exception('The email address is not valid');
            case 'weak-password':
              throw Exception('The password is too weak');
            default:
              throw Exception('Failed to link account: ${e.message}');
          }
        }

        rethrow;
      }
    } catch (e) {
      debugPrint('Error in linkAnonymousAccount: $e');
      if (e is Exception) rethrow;
      throw Exception('Failed to link anonymous account: $e');
    }
  }
}
