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

  @override
  Future<domain.User> signInAnonymously() async {
    try {
      debugPrint('Starting anonymous sign-in flow');

      // Check if the current user is already anonymous
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        debugPrint('Reusing existing anonymous user: ${currentUser.uid}');
        // Return existing user instead of creating a new one
        return await _mapFirebaseUserToDomain(currentUser);
      }

      // Sign in anonymously with Firebase
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user == null) {
        debugPrint('Anonymous sign-in failed - null user');
        throw Exception('Anonymous sign-in failed');
      }

      debugPrint('Anonymous sign-in successful: ${user.uid}');

      // Create initial user document with default settings
      // This will only be used for new users, not existing ones
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

  // Helper method to link anonymous account with Google
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
      } catch (e) {
        debugPrint('Error during credential linking: $e');

        // If we get a stale token error, try linking again with a fresh token
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
            throw Exception('Failed to get fresh Google account for linking');
          }

          final freshAuth = await freshGoogleUser.authentication;
          final freshCredential = firebase_auth.GoogleAuthProvider.credential(
            accessToken: freshAuth.accessToken,
            idToken: freshAuth.idToken,
          );

          userCredential =
              await currentUser.linkWithCredential(freshCredential);
        } else {
          // Rethrow other errors
          rethrow;
        }
      }

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

      debugPrint('Successfully linked anonymous account to Google');

      // Return updated user
      return await _mapFirebaseUserToDomain(user);
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

      // Create email credential
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Link anonymous account with email credential
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

      // Return updated user
      return await _mapFirebaseUserToDomain(user);
    } catch (e) {
      debugPrint('Error linking anonymous account: $e');

      // Handle specific Firebase errors
      if (e is firebase_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('This email is already in use by another account');
          case 'invalid-email':
            throw Exception('The email address is not valid');
          case 'weak-password':
            throw Exception('The password is too weak');
          default:
            throw Exception('Failed to link account: ${e.message}');
        }
      }

      throw Exception('Failed to link anonymous account: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      debugPrint('Starting sign out process');

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
}
