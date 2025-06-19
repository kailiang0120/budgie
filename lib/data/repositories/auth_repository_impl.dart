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

    // Get currency from Firestore (user-specific)
    String currency = 'MYR';

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          currency = userData['currency'] ?? 'MYR';
        }
      }
    } catch (e) {
      debugPrint('Error fetching user currency: $e');
    }

    return domain.User(
      id: user.uid,
      email: user.email ?? '', // Handle null email
      displayName: displayName,
      photoUrl: user.photoURL,
      currency: currency,
      theme: 'light', // Theme is now device-based, not user-based
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

      // Ensure user document exists with default settings
      await _ensureUserDocumentExists(user);

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

      // Ensure user document exists with default settings
      await _ensureUserDocumentExists(user);

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

      // 6. Ensure user document exists in Firestore with default settings
      await _ensureUserDocumentExists(user);

      // 7. Return the mapped user
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

  @override
  Future<domain.User> signInAnonymously() async {
    throw Exception('Method not implemented');
  }

  @override
  Future<domain.User> linkAnonymousAccount(
      {required String email, required String password}) async {
    throw Exception('Method not implemented');
  }

  @override
  Future<void> deleteGuestUser() async {
    throw Exception('Method not implemented');
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

  /// Updates user settings
  @override
  Future<void> updateUserSettings(
      {String? currency, String? displayName}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      final userId = currentUser.uid;
      final userDoc = await _firestore.collection('users').doc(userId).get();

      // Prepare update data
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (currency != null) {
        updateData['currency'] = currency;
      }

      if (displayName != null) {
        updateData['displayName'] = displayName;
      }

      // Update the user document
      await _firestore.collection('users').doc(userId).update(updateData);

      debugPrint('User settings updated successfully');
    } catch (e) {
      debugPrint('Error updating user settings: $e');
      throw Exception('Failed to update user settings: $e');
    }
  }

  /// Ensures a user document exists in Firestore with default settings
  /// This method is called for all sign-in methods to ensure consistency
  Future<void> _ensureUserDocumentExists(firebase_auth.User user) async {
    try {
      debugPrint('Ensuring user document exists for: ${user.uid}');

      // Check if user document already exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        debugPrint('Creating new user document with default settings');

        // Create a user document with only essential fields
        // Settings will be handled locally, only currency is stored in the user document
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName ?? 'User ${user.uid.substring(0, 8)}',
          'photoURL': user.photoURL,
          'currency': 'MYR', // Default currency
          'isGuest': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('User document created successfully');
      } else {
        debugPrint('User document already exists');

        // Check if the document has all required fields and add missing ones
        final userData = userDoc.data();
        final Map<String, dynamic> updates = {};

        // Ensure all default fields exist
        if (userData?['currency'] == null) {
          updates['currency'] = 'MYR';
        }
        if (userData?['displayName'] == null) {
          updates['displayName'] =
              user.displayName ?? 'User ${user.uid.substring(0, 8)}';
        }
        if (userData?['photoURL'] == null) {
          updates['photoURL'] = user.photoURL;
        }

        // Add updatedAt timestamp
        if (updates.isNotEmpty) {
          updates['updatedAt'] = FieldValue.serverTimestamp();

          await _firestore.collection('users').doc(user.uid).update(updates);
          debugPrint(
              'User document updated with missing fields: ${updates.keys}');
        }
      }
    } catch (e) {
      debugPrint('Error ensuring user document exists: $e');
      // Don't throw here as this is not critical for sign-in to succeed
    }
  }
}
