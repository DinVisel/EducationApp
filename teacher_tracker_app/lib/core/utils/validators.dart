import 'package:flutter/widgets.dart';

/// Shared client-side form validators, for use with `TextFormField.validator`.
class Validators {
  Validators._();

  static String? required(String? value, {String message = 'Required'}) =>
      (value == null || value.trim().isEmpty) ? message : null;

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Required';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(trimmed)) return 'Enter a valid email';
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
  static String? password(String? value) =>
      required(value) ?? minLength(value, 6, message: 'Must be at least 6 characters');

  /// Confirm-password validator: compares against [other]'s current text.
  static String? Function(String?) confirms(TextEditingController other) {
    return (value) => (value != other.text) ? 'Passwords do not match' : null;
  }
}
