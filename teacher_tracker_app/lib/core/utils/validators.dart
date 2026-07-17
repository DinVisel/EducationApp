import 'package:flutter/widgets.dart';

/// Shared client-side form validators, for use with `TextFormField.validator`.
///
/// Messages default to English; screens that resolve `AppLocalizations` pass
/// localized overrides (e.g. `Validators.required(v, message: loc.commonRequired)`).
class Validators {
  Validators._();

  static String? required(String? value, {String message = 'Required'}) =>
      (value == null || value.trim().isEmpty) ? message : null;

  static String? email(
    String? value, {
    String requiredMessage = 'Required',
    String invalidMessage = 'Enter a valid email',
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return requiredMessage;
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(trimmed)) return invalidMessage;
    return null;
  }

  static String? minLength(String? value, int min, {String? message}) {
    if ((value ?? '').length < min) {
      return message ?? 'Must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String? message}) {
    if ((value ?? '').length > max) {
      return message ?? 'Must be $max characters or fewer';
    }
    return null;
  }

  /// Required + minimum length of 6, matching the backend's password policy.
  static String? password(
    String? value, {
    String requiredMessage = 'Required',
    String tooShortMessage = 'Must be at least 6 characters',
  }) =>
      required(value, message: requiredMessage) ??
      minLength(value, 6, message: tooShortMessage);

  /// Confirm-password validator: compares against [other]'s current text.
  static String? Function(String?) confirms(
    TextEditingController other, {
    String message = 'Passwords do not match',
  }) {
    return (value) => (value != other.text) ? message : null;
  }
}
