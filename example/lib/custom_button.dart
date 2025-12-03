/// A button widget that supports various styles and interactions.
///
/// {@category Widgets}
/// {@subCategory Buttons}
///
/// The [CustomButton] provides a flexible button implementation with support
/// for different visual styles, loading states, and custom actions.
///
/// ## Usage Example
///
/// ```dart
/// CustomButton(
///   text: 'Click Me',
///   onPressed: () {
///     print('Button pressed!');
///   },
///   style: ButtonStyle.primary,
/// );
/// ```
///
/// See also:
///
/// * [TextButton] for simple text-based buttons
/// * [IconButton] for icon-only buttons
class CustomButton {
  /// The text to display on the button.
  ///
  /// This text will be displayed using the current theme's button text style.
  final String text;

  /// Called when the button is tapped.
  ///
  /// If null, the button will be disabled.
  final VoidCallback? onPressed;

  /// The visual style of the button.
  ///
  /// Defaults to [ButtonStyle.primary].
  final ButtonStyle style;

  /// Whether the button should show a loading indicator.
  ///
  /// When true, the button will display a circular progress indicator
  /// instead of the text.
  final bool isLoading;

  /// Creates a custom button.
  ///
  /// The [text] parameter must not be null.
  ///
  /// Example:
  /// ```dart
  /// CustomButton(
  ///   text: 'Submit',
  ///   onPressed: _handleSubmit,
  /// );
  /// ```
  const CustomButton({
    required this.text,
    this.onPressed,
    this.style = ButtonStyle.primary,
    this.isLoading = false,
  });

  /// Creates a custom button with a secondary style.
  ///
  /// This is a convenience constructor that automatically sets
  /// the style to [ButtonStyle.secondary].
  factory CustomButton.secondary({
    required String text,
    VoidCallback? onPressed,
  }) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      style: ButtonStyle.secondary,
    );
  }

  /// Builds the button widget.
  ///
  /// This method is called by the framework when the button needs to be
  /// rendered on screen.
  Container build(BuildContext context) {
    return Container(child: Text(text));
  }

  /// Handles the tap gesture.
  ///
  /// This method is called when the user taps on the button. It will only
  /// execute if [onPressed] is not null and [isLoading] is false.
  void _handleTap() {
    if (onPressed != null && !isLoading) {
      onPressed!();
    }
  }

  /// The default duration for button animations.
  ///
  /// All button animations will use this duration unless overridden.
  static const Duration animationDuration = Duration(milliseconds: 200);

  /// Creates a copy of this button with updated properties.
  ///
  /// Any non-null parameter will override the current value.
  ///
  /// Example:
  /// ```dart
  /// final newButton = button.copyWith(
  ///   text: 'Updated Text',
  ///   isLoading: true,
  /// );
  /// ```
  CustomButton copyWith({
    String? text,
    VoidCallback? onPressed,
    ButtonStyle? style,
    bool? isLoading,
  }) {
    return CustomButton(
      text: text ?? this.text,
      onPressed: onPressed ?? this.onPressed,
      style: style ?? this.style,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Defines the visual style for buttons.
///
/// {@category Styles}
///
/// Each style provides a different visual appearance for buttons,
/// following Material Design guidelines.
enum ButtonStyle {
  /// A primary button with high emphasis.
  ///
  /// Used for the main action in a screen.
  primary,

  /// A secondary button with medium emphasis.
  ///
  /// Used for alternative actions.
  secondary,

  /// A text-only button with low emphasis.
  ///
  /// Used for tertiary actions.
  text,
}

/// Extension methods for [String] related to button text.
///
/// {@category Extensions}
extension ButtonStringExtension on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Example:
  /// ```dart
  /// 'hello'.capitalizeFirst(); // Returns 'Hello'
  /// ```
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Checks if the string is a valid button text.
  ///
  /// Returns true if the string is not empty and not only whitespace.
  bool get isValidButtonText => trim().isNotEmpty;
}

/// A callback type for button press events.
///
/// {@category Types}
typedef VoidCallback = void Function();

/// A callback type for button press events with a value.
///
/// {@category Types}
typedef ValueCallback<T> = void Function(T value);

/// Mock context class for example
class BuildContext {}

/// Mock widget class for example
class Widget {}

/// Mock container class for example
class Container {
  final Widget? child;
  Container({this.child});
}

/// Mock text class for example
class Text extends Widget {
  final String data;
  Text(this.data);
}
