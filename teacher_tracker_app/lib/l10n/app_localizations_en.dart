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
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonEmpty => 'Nothing here yet.';

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

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get imageCropperTitle => 'Edit photo';

  @override
  String get attendanceTitle => 'Attendance';

  @override
  String get attendanceTabLabel => 'Attendance';

  @override
  String get attendanceStatusPresent => 'Present';

  @override
  String get attendanceStatusAbsent => 'Absent';

  @override
  String get attendanceStatusLate => 'Late';

  @override
  String get attendanceStatusExcused => 'Excused';

  @override
  String get attendanceSave => 'Save';

  @override
  String get attendanceSaved => 'Attendance saved';

  @override
  String attendanceSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String get attendanceEmptyRoster => 'No students in this class yet.';

  @override
  String get attendancePickDate => 'Pick date';

  @override
  String get attendanceMarkAllPresent => 'Mark all present';

  @override
  String get attendanceUnmarked => 'Not marked';

  @override
  String get attendanceHistoryTitle => 'Attendance history';

  @override
  String get attendanceHistoryEmpty => 'No attendance recorded yet.';

  @override
  String get attendanceViewHistory => 'View attendance history';

  @override
  String get classTabStudents => 'Students';

  @override
  String get classTabHomework => 'Homework';

  @override
  String get classTabQuizzes => 'Quizzes';

  @override
  String get classTabReading => 'Reading';

  @override
  String get classAddStudents => 'Add Students';

  @override
  String get classRemoveFromClass => 'Remove from class';

  @override
  String classCouldNotRemove(String error) {
    return 'Could not remove: $error';
  }

  @override
  String classCouldNotAdd(String error) {
    return 'Could not add: $error';
  }

  @override
  String get classEmptyRosterTitle => 'No students in this class yet';

  @override
  String get classEmptyRosterSubtitle =>
      'Tap “Add Students” to build the roster.';

  @override
  String get classAddStudentsSheetTitle => 'Add students';

  @override
  String get classAllStudentsEnrolled =>
      'All your students are already in this class.';

  @override
  String classStudentAdded(String name) {
    return 'Added $name';
  }

  @override
  String classStudentNumber(String number) {
    return 'No. $number';
  }

  @override
  String get classesTitle => 'Classes';

  @override
  String get classesNewTitle => 'New Class';

  @override
  String get classesRenameTitle => 'Rename Class';

  @override
  String get classesNameLabel => 'Class name';

  @override
  String get classesRename => 'Rename';

  @override
  String get classesDeleteTitle => 'Delete class?';

  @override
  String classesDeleteBody(String name) {
    return 'Remove \"$name\"? Students stay, only the class and its enrollments are removed.';
  }

  @override
  String classesStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String classesCouldNotCreate(String error) {
    return 'Could not create class: $error';
  }

  @override
  String classesCouldNotRename(String error) {
    return 'Could not rename class: $error';
  }

  @override
  String classesCouldNotDelete(String error) {
    return 'Could not delete class: $error';
  }

  @override
  String get classesEmptyTitle => 'No classes yet';

  @override
  String get classesEmptySubtitle => 'Tap “New Class” to create one.';
}
