import 'package:async/async.dart';

/// A user authentication service.
///
/// {@category Authentication}
/// {@subCategory Core}
///
/// This service handles user login, registration, and token management.
/// It provides a clean API for authentication operations.
///
/// Example:
/// ```dart
/// final auth = AuthService();
/// final user = await auth.login('email@example.com', 'password');
/// ```
class AuthService {
  /// The current authenticated user.
  User? currentUser;

  /// Whether the user is currently logged in.
  final bool isAuthenticated;

  /// The authentication token.
  final String? token;

  /// Creates a new [AuthService] instance.
  AuthService({this.currentUser, this.isAuthenticated = false, this.token});

  /// Logs in a user with email and password.
  ///
  /// Returns the authenticated [User] on success.
  /// Throws [AuthException] if login fails.
  Future<User> login(String email, String password) async {
    // Implementation
    return User(id: '1', email: email, name: 'John Doe');
  }

  /// Registers a new user.
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password (must be at least 8 characters)
  /// - [name]: User's display name
  Future<User> register({
    required String email,
    required String password,
    required String name,
  }) async {
    // Implementation
    return User(id: '2', email: email, name: name);
  }

  /// Logs out the current user.
  void logout() {
    // Implementation
  }

  /// Refreshes the authentication token.
  static Future<String> refreshToken(String oldToken) async {
    // Implementation
    return 'new-token';
  }
}

/// Represents a user in the system.
///
/// {@category Authentication}
/// {@subCategory Models}
class User {
  /// The user's unique identifier.
  final String id;

  /// The user's email address.
  final String email;

  /// The user's display name.
  final String name;

  /// The user's profile picture URL.
  String? avatarUrl;

  /// Creates a new [User] instance.
  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
  });

  /// Converts this user to a JSON object.
  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'avatarUrl': avatarUrl};
  }

  /// Creates a [User] from a JSON object.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
    );
  }
}

/// User roles in the system.
///
/// {@category Authentication}
/// {@subCategory Models}
enum UserRole {
  /// Regular user with basic permissions.
  user,

  /// Administrator with full access.
  admin,

  /// Moderator with limited admin access.
  moderator,

  /// Guest user with read-only access.
  guest,
}

/// Extension methods for [String] validation.
///
/// {@category Utilities}
/// {@subCategory Validation}
extension StringValidation on String {
  /// Checks if this string is a valid email address.
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Checks if this string is a valid password.
  ///
  /// A valid password must be at least 8 characters long
  /// and contain at least one uppercase letter, one lowercase
  /// letter, and one number.
  bool get isValidPassword {
    if (length < 8) return false;
    final hasUppercase = contains(RegExp(r'[A-Z]'));
    final hasLowercase = contains(RegExp(r'[a-z]'));
    final hasDigit = contains(RegExp(r'\d'));
    return hasUppercase && hasLowercase && hasDigit;
  }
}

/// A callback function for authentication events.
///
/// {@category Authentication}
/// {@subCategory Core}
typedef AuthCallback = void Function(User user);

/// A payment processing service.
///
/// {@category Payments}
/// {@subCategory Processing}
class PaymentService {
  /// The payment gateway API key.
  final String apiKey;

  /// Whether to use test mode.
  final bool testMode;

  /// Creates a new [PaymentService] instance.
  const PaymentService({required this.apiKey, this.testMode = false});

  /// Processes a payment transaction.
  ///
  /// Returns a [PaymentResult] containing the transaction details.
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String cardToken,
    String? description,
  }) async {
    // Implementation
    return PaymentResult(
      success: true,
      transactionId: 'txn_123',
      amount: amount,
    );
  }

  /// Refunds a payment.
  Future<bool> refundPayment(String transactionId) async {
    // Implementation
    return true;
  }
}

/// The result of a payment transaction.
///
/// {@category Payments}
/// {@subCategory Models}
class PaymentResult {
  /// Whether the payment was successful.
  final bool success;

  /// The transaction identifier.
  final String transactionId;

  /// The payment amount.
  final double amount;

  /// An error message if the payment failed.
  final String? error;

  /// Creates a new [PaymentResult] instance.
  PaymentResult({
    required this.success,
    required this.transactionId,
    required this.amount,
    this.error,
  });
}

/// Payment status enumeration.
///
/// {@category Payments}
/// {@subCategory Models}
enum PaymentStatus {
  /// Payment is pending.
  pending,

  /// Payment was successful.
  completed,

  /// Payment failed.
  failed,

  /// Payment was refunded.
  refunded,
}
