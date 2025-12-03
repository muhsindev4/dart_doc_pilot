// **********************************************************************
// Example file for testing dart_doc_pilot documentation extraction
// **********************************************************************

/// {@category UI}
/// {@subCategory Buttons}
///
/// A high-level button interface.
/// This class is used as a base for all custom button implementations.
///
/// See also: [PrimaryButton], [SecondaryButton].
///
/// {@template general_button_usage}
/// Example:
/// ```dart
/// final btn = PrimaryButton(
///   label: 'Continue',
///   onPressed: () => print('Hi'),
/// );
/// ```
/// {@endtemplate}
abstract class AppButton {
  /// Button label text.
  final String label;

  /// Called when the button is pressed.
  final void Function()? onPressed;

  /// Creates a new button.
  AppButton({required this.label, this.onPressed});

  /// Renders the button.
  void render();
}

// **********************************************************************
// Primary Button
// **********************************************************************

/// {@category UI}
/// {@subCategory Buttons}
///
/// A primary action button in the UI.
///
/// {@macro general_button_usage}
///
/// This button uses the app’s theme colors.
/// Tabs + spaces should be supported:
/// \t/// Inline doc with tab
class PrimaryButton extends AppButton {
  /// Button size.
  final double size;

  PrimaryButton({required super.label, super.onPressed, this.size = 48});

  /// {@macro general_button_usage}
  @override
  void render() {
    print("Rendering PrimaryButton: $label");
  }

  /// A static helper method.
  static PrimaryButton createDefault() {
    return PrimaryButton(label: 'Default');
  }
}

// **********************************************************************
// SECONDARY BUTTON
// **********************************************************************

/// {@category UI}
/// {@subCategory Buttons}
///
/// A secondary variant of [PrimaryButton].
///
/// Often used for lower-priority actions.
/// ```dart
/// final btn = SecondaryButton(
///   label: 'Cancel',
///   onPressed: () {},
/// );
/// ```
class SecondaryButton extends AppButton {
  SecondaryButton({required super.label, super.onPressed});

  @override
  void render() {
    print("Rendering SecondaryButton: $label");
  }
}

// **********************************************************************
// ENUM WITH DOCS
// **********************************************************************

/// {@category Data}
/// {@subCategory Status}
///
/// Status of a network request.
enum RequestStatus {
  /// Request is loading.
  loading,

  /// Request completed successfully.
  success,

  /// Request failed.
  failure,
}

// **********************************************************************
// TYPEDEF SAMPLE
// **********************************************************************

/// {@category Core}
/// {@subCategory Types}
///
/// Callback for a button action.
///
/// Example:
/// ```dart
/// typedef ActionCallback = void Function(String action);
/// ```
typedef ActionCallback = void Function(String action);

// **********************************************************************
// MIXIN SAMPLE
// **********************************************************************

/// {@category Core}
/// {@subCategory Mixins}
///
/// A mixin providing analytics logging functionality.
mixin AnalyticsMixin {
  /// Logs an event.
  void logEvent(String name) {
    print("Event logged: $name");
  }
}

// **********************************************************************
// CLASS USING MIXIN
// **********************************************************************

/// {@category Services}
/// {@subCategory Authentication}
///
/// A service responsible for authenticating users.
class AuthService with AnalyticsMixin {
  /// Current logged-in user ID.
  String? userId;

  /// Logs in a user.
  ///
  /// ```dart
  /// final auth = AuthService();
  /// await auth.login('email', '1234');
  /// ```
  Future<bool> login(String email, String password) async {
    logEvent("login_attempt");
    userId = "uid_123";
    return true;
  }
}

// **********************************************************************
// EXTENSIONS
// **********************************************************************

/// {@category Extensions}
/// {@subCategory String Helpers}
///
/// Adds helper methods to [String].
extension StringUtils on String {
  /// Capitalizes the first letter of the string.
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
