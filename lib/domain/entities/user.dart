import 'constants.dart';

/// User entity representing a user in the application
class User {
  /// Unique identifier for the user
  final String id;

  /// User's email address
  final String? email;

  /// User's display name
  final String? displayName;

  /// URL to user's profile photo
  final String? photoUrl;

  /// User's preferred currency
  final String currency;

  /// User's preferred theme
  final String theme;

  /// Creates a new User instance
  User({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    String? currency,
    String? theme,
  })  : currency = currency ?? DomainConstants.defaultCurrency,
        theme = theme ?? DomainConstants.defaultTheme;

  /// Creates a copy of this User with the given fields replaced with new values
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? currency,
    String? theme,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      currency: currency ?? this.currency,
      theme: theme ?? this.theme,
    );
  }
}
