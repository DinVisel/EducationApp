// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonInvalidEmail => 'Enter a valid email';

  @override
  String get commonPasswordTooShort => 'Must be at least 6 characters';

  @override
  String get commonPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get commonNetworkError => 'Network error. Is the server running?';

  @override
  String get commonSomethingWentWrong => 'Something went wrong.';

  @override
  String get loginTitle => 'Teacher Tracker';

  @override
  String get loginSubtitle => 'Sign in to track your students';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginNoAccount => 'Don\'t have an account? Register';

  @override
  String get loginInvalidCredentials => 'Invalid email or password.';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerFirstName => 'First name';

  @override
  String get registerLastName => 'Last name';

  @override
  String get registerEmail => 'Email';

  @override
  String get registerPasswordHint => 'Password (min 6 chars)';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get registerEmailTaken => 'That email is already registered.';

  @override
  String get forgotPasswordTitle => 'Forgot password?';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your account\'s email and we\'ll send you a reset code.';

  @override
  String get forgotPasswordEmailLabel => 'Email';

  @override
  String get forgotPasswordSubmit => 'Send reset code';

  @override
  String get forgotPasswordBackToSignIn => 'Back to sign in';

  @override
  String get forgotPasswordConfirmTitle => 'Check your email';

  @override
  String get forgotPasswordConfirmBody =>
      'If that email exists, we\'ve sent a reset code to it.';

  @override
  String get forgotPasswordHaveCode => 'I have a code';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordSubtitle =>
      'Enter the code we emailed you and choose a new password.';

  @override
  String get resetPasswordCodeLabel => 'Reset code';

  @override
  String get resetPasswordNewPasswordLabel => 'New password';

  @override
  String get resetPasswordConfirmLabel => 'Confirm new password';

  @override
  String get resetPasswordSubmit => 'Reset password';

  @override
  String get resetPasswordSuccess =>
      'Password reset. Sign in with your new password.';

  @override
  String get resetPasswordBackToSignIn => 'Back to sign in';

  @override
  String get navHub => 'Hub';

  @override
  String get navSearch => 'Search';

  @override
  String get navClasses => 'Classes';

  @override
  String get navProfile => 'Profile';

  @override
  String get navNewPost => 'New Post';

  @override
  String get navNewClass => 'New Class';

  @override
  String get feedTitle => 'Community Hub';

  @override
  String get feedEmptyTitle => 'No posts yet';

  @override
  String get feedEmptyBody =>
      'Tap \"New Post\" to share a resource with other teachers.';

  @override
  String get feedFilterAll => 'All';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsFirstName => 'First name';

  @override
  String get settingsLastName => 'Last name';

  @override
  String get settingsEmail => 'Email';

  @override
  String get settingsSaveChanges => 'Save changes';

  @override
  String get settingsProfileSaved => 'Profile saved';

  @override
  String settingsSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out?';

  @override
  String get settingsSignOutConfirmBody => 'You will need to sign in again.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageTurkish => 'Türkçe';
}
