import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get commonInvalidEmail;

  /// No description provided for @commonPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters'**
  String get commonPasswordTooShort;

  /// No description provided for @commonPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get commonPasswordsDoNotMatch;

  /// No description provided for @commonNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Is the server running?'**
  String get commonNetworkError;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @connectivityOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get connectivityOffline;

  /// No description provided for @connectivityBackOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get connectivityBackOnline;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonError(String error);

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get commonEmpty;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commonReport;

  /// No description provided for @commonUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String commonUploadFailed(String error);

  /// No description provided for @commonNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get commonNew;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get commonTitle;

  /// No description provided for @commonDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get commonDescriptionOptional;

  /// No description provided for @commonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get commonNotAvailable;

  /// No description provided for @commonCouldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String commonCouldNotDelete(String error);

  /// No description provided for @commonFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String commonFailed(String error);

  /// No description provided for @commonCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load: {error}'**
  String commonCouldNotLoad(String error);

  /// No description provided for @commonSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String commonSaveFailed(String error);

  /// No description provided for @commonAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Add failed: {error}'**
  String commonAddFailed(String error);

  /// No description provided for @commonCouldNotPublish.
  ///
  /// In en, this message translates to:
  /// **'Could not publish: {error}'**
  String commonCouldNotPublish(String error);

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get commonTimeJustNow;

  /// No description provided for @commonTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String commonTimeMinutesAgo(int minutes);

  /// No description provided for @commonTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String commonTimeHoursAgo(int hours);

  /// No description provided for @commonTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String commonTimeDaysAgo(int days);

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Tracker'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to track your students'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get loginNoAccount;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get registerFirstName;

  /// No description provided for @registerLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get registerLastName;

  /// No description provided for @registerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get registerEmail;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password (min 6 chars)'**
  String get registerPasswordHint;

  /// No description provided for @registerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerSubmit;

  /// No description provided for @registerEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'That email is already registered.'**
  String get registerEmailTaken;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account\'s email and we\'ll send you a reset code.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get forgotPasswordEmailLabel;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send reset code'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get forgotPasswordBackToSignIn;

  /// No description provided for @forgotPasswordConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get forgotPasswordConfirmTitle;

  /// No description provided for @forgotPasswordConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'If that email exists, we\'ve sent a reset code to it.'**
  String get forgotPasswordConfirmBody;

  /// No description provided for @forgotPasswordHaveCode.
  ///
  /// In en, this message translates to:
  /// **'I have a code'**
  String get forgotPasswordHaveCode;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we emailed you and choose a new password.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get resetPasswordCodeLabel;

  /// No description provided for @resetPasswordNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetPasswordNewPasswordLabel;

  /// No description provided for @resetPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get resetPasswordConfirmLabel;

  /// No description provided for @resetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordSubmit;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Sign in with your new password.'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get resetPasswordBackToSignIn;

  /// No description provided for @navHub.
  ///
  /// In en, this message translates to:
  /// **'Hub'**
  String get navHub;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get navClasses;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navNewPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get navNewPost;

  /// No description provided for @navNewClass.
  ///
  /// In en, this message translates to:
  /// **'New Class'**
  String get navNewClass;

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Hub'**
  String get feedTitle;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New Post\" to share a resource with other teachers.'**
  String get feedEmptyBody;

  /// No description provided for @feedFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedFilterAll;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get settingsFirstName;

  /// No description provided for @settingsLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get settingsLastName;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// No description provided for @settingsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get settingsSaveChanges;

  /// No description provided for @settingsProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get settingsProfileSaved;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String settingsSaveFailed(String error);

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutConfirmTitle;

  /// No description provided for @settingsSignOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again.'**
  String get settingsSignOutConfirmBody;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get settingsLanguageTurkish;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsToggle.
  ///
  /// In en, this message translates to:
  /// **'Vibration feedback'**
  String get settingsHapticsToggle;

  /// No description provided for @imageCropperTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit photo'**
  String get imageCropperTitle;

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTitle;

  /// No description provided for @attendanceTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTabLabel;

  /// No description provided for @attendanceStatusPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendanceStatusPresent;

  /// No description provided for @attendanceStatusAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceStatusAbsent;

  /// No description provided for @attendanceStatusLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceStatusLate;

  /// No description provided for @attendanceStatusExcused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get attendanceStatusExcused;

  /// No description provided for @attendanceSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get attendanceSave;

  /// No description provided for @attendanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved'**
  String get attendanceSaved;

  /// No description provided for @attendanceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String attendanceSaveFailed(String error);

  /// No description provided for @attendanceEmptyRoster.
  ///
  /// In en, this message translates to:
  /// **'No students in this class yet.'**
  String get attendanceEmptyRoster;

  /// No description provided for @attendancePickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get attendancePickDate;

  /// No description provided for @attendanceMarkAllPresent.
  ///
  /// In en, this message translates to:
  /// **'Mark all present'**
  String get attendanceMarkAllPresent;

  /// No description provided for @attendanceUnmarked.
  ///
  /// In en, this message translates to:
  /// **'Not marked'**
  String get attendanceUnmarked;

  /// No description provided for @attendanceHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance history'**
  String get attendanceHistoryTitle;

  /// No description provided for @attendanceHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attendance recorded yet.'**
  String get attendanceHistoryEmpty;

  /// No description provided for @attendanceViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View attendance history'**
  String get attendanceViewHistory;

  /// No description provided for @classTabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get classTabStudents;

  /// No description provided for @classTabHomework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get classTabHomework;

  /// No description provided for @classTabQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get classTabQuizzes;

  /// No description provided for @classTabReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get classTabReading;

  /// No description provided for @classAddStudents.
  ///
  /// In en, this message translates to:
  /// **'Add Students'**
  String get classAddStudents;

  /// No description provided for @classRemoveFromClass.
  ///
  /// In en, this message translates to:
  /// **'Remove from class'**
  String get classRemoveFromClass;

  /// No description provided for @classCouldNotRemove.
  ///
  /// In en, this message translates to:
  /// **'Could not remove: {error}'**
  String classCouldNotRemove(String error);

  /// No description provided for @classCouldNotAdd.
  ///
  /// In en, this message translates to:
  /// **'Could not add: {error}'**
  String classCouldNotAdd(String error);

  /// No description provided for @classEmptyRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'No students in this class yet'**
  String get classEmptyRosterTitle;

  /// No description provided for @classEmptyRosterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add Students” to build the roster.'**
  String get classEmptyRosterSubtitle;

  /// No description provided for @classAddStudentsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add students'**
  String get classAddStudentsSheetTitle;

  /// No description provided for @classAllStudentsEnrolled.
  ///
  /// In en, this message translates to:
  /// **'All your students are already in this class.'**
  String get classAllStudentsEnrolled;

  /// No description provided for @classStudentAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String classStudentAdded(String name);

  /// No description provided for @classStudentNumber.
  ///
  /// In en, this message translates to:
  /// **'No. {number}'**
  String classStudentNumber(String number);

  /// No description provided for @classesTitle.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classesTitle;

  /// No description provided for @classesNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Class'**
  String get classesNewTitle;

  /// No description provided for @classesRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Class'**
  String get classesRenameTitle;

  /// No description provided for @classesNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Class name'**
  String get classesNameLabel;

  /// No description provided for @classesRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get classesRename;

  /// No description provided for @classesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete class?'**
  String get classesDeleteTitle;

  /// No description provided for @classesDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"? Students stay, only the class and its enrollments are removed.'**
  String classesDeleteBody(String name);

  /// No description provided for @classesStudentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student} other{{count} students}}'**
  String classesStudentCount(int count);

  /// No description provided for @classesCouldNotCreate.
  ///
  /// In en, this message translates to:
  /// **'Could not create class: {error}'**
  String classesCouldNotCreate(String error);

  /// No description provided for @classesCouldNotRename.
  ///
  /// In en, this message translates to:
  /// **'Could not rename class: {error}'**
  String classesCouldNotRename(String error);

  /// No description provided for @classesCouldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete class: {error}'**
  String classesCouldNotDelete(String error);

  /// No description provided for @classesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No classes yet'**
  String get classesEmptyTitle;

  /// No description provided for @classesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap “New Class” to create one.'**
  String get classesEmptySubtitle;

  /// No description provided for @feedShareSubject.
  ///
  /// In en, this message translates to:
  /// **'{name} shared a post'**
  String feedShareSubject(String name);

  /// No description provided for @feedQuizAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned \"{title}\" to {className}'**
  String feedQuizAssigned(String title, String className);

  /// No description provided for @feedCouldNotAssign.
  ///
  /// In en, this message translates to:
  /// **'Could not assign: {error}'**
  String feedCouldNotAssign(String error);

  /// No description provided for @feedPinToProfile.
  ///
  /// In en, this message translates to:
  /// **'Pin to profile'**
  String get feedPinToProfile;

  /// No description provided for @feedUnpinFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Unpin from profile'**
  String get feedUnpinFromProfile;

  /// No description provided for @feedDeletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get feedDeletePostTitle;

  /// No description provided for @feedDeletePostBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from the feed for everyone.'**
  String get feedDeletePostBody;

  /// No description provided for @feedCouldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String feedCouldNotDelete(String error);

  /// No description provided for @feedReported.
  ///
  /// In en, this message translates to:
  /// **'Reported — thanks. An admin will review it.'**
  String get feedReported;

  /// No description provided for @feedCouldNotReport.
  ///
  /// In en, this message translates to:
  /// **'Could not report: {error}'**
  String feedCouldNotReport(String error);

  /// No description provided for @feedQuizQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String feedQuizQuestionCount(int count);

  /// No description provided for @feedNotRatedYet.
  ///
  /// In en, this message translates to:
  /// **'Not rated yet'**
  String get feedNotRatedYet;

  /// No description provided for @feedAssignToClass.
  ///
  /// In en, this message translates to:
  /// **'Assign to My Class'**
  String get feedAssignToClass;

  /// No description provided for @feedAssignWhichClass.
  ///
  /// In en, this message translates to:
  /// **'Assign to which class?'**
  String get feedAssignWhichClass;

  /// No description provided for @feedNoClassesYet.
  ///
  /// In en, this message translates to:
  /// **'You have no classes yet. Create one first.'**
  String get feedNoClassesYet;

  /// No description provided for @newPostPublished.
  ///
  /// In en, this message translates to:
  /// **'Post published'**
  String get newPostPublished;

  /// No description provided for @newPostCouldNotPublish.
  ///
  /// In en, this message translates to:
  /// **'Could not publish: {error}'**
  String newPostCouldNotPublish(String error);

  /// No description provided for @newPostTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Share something'**
  String get newPostTextLabel;

  /// No description provided for @newPostTextHint.
  ///
  /// In en, this message translates to:
  /// **'An exercise, a tip, a resource…'**
  String get newPostTextHint;

  /// No description provided for @newPostTextRequired.
  ///
  /// In en, this message translates to:
  /// **'Write something to post'**
  String get newPostTextRequired;

  /// No description provided for @newPostSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get newPostSubject;

  /// No description provided for @newPostGradeLevel.
  ///
  /// In en, this message translates to:
  /// **'Grade level (optional)'**
  String get newPostGradeLevel;

  /// No description provided for @newPostShareQuiz.
  ///
  /// In en, this message translates to:
  /// **'Share a quiz (optional)'**
  String get newPostShareQuiz;

  /// No description provided for @newPostAttachQuiz.
  ///
  /// In en, this message translates to:
  /// **'Attach one of my quizzes'**
  String get newPostAttachQuiz;

  /// No description provided for @newPostQuizFallback.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get newPostQuizFallback;

  /// No description provided for @newPostAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get newPostAttachments;

  /// No description provided for @newPostAddFiles.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get newPostAddFiles;

  /// No description provided for @newPostAttachmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Exercises, videos, or files other teachers can download.'**
  String get newPostAttachmentsHint;

  /// No description provided for @newPostPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get newPostPublishing;

  /// No description provided for @newPostSubmit.
  ///
  /// In en, this message translates to:
  /// **'Post to hub'**
  String get newPostSubmit;

  /// No description provided for @newPostShareWhichQuiz.
  ///
  /// In en, this message translates to:
  /// **'Share which quiz?'**
  String get newPostShareWhichQuiz;

  /// No description provided for @newPostNoQuizzes.
  ///
  /// In en, this message translates to:
  /// **'You haven’t created any quizzes yet.'**
  String get newPostNoQuizzes;

  /// No description provided for @newPostQuizSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{className} · {questions}'**
  String newPostQuizSubtitle(String className, String questions);

  /// No description provided for @reportPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get reportPostTitle;

  /// No description provided for @reportCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get reportCommentTitle;

  /// No description provided for @reportReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReasonLabel;

  /// No description provided for @reportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this?'**
  String get reportReasonHint;

  /// No description provided for @postDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postDetailTitle;

  /// No description provided for @postDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'This post couldn\'t be loaded.'**
  String get postDetailLoadError;

  /// No description provided for @postDetailCouldNotRate.
  ///
  /// In en, this message translates to:
  /// **'Could not rate: {error}'**
  String postDetailCouldNotRate(String error);

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @commentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet — be the first.'**
  String get commentsEmpty;

  /// No description provided for @commentsHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get commentsHint;

  /// No description provided for @commentsCouldNotAdd.
  ///
  /// In en, this message translates to:
  /// **'Could not comment: {error}'**
  String commentsCouldNotAdd(String error);

  /// No description provided for @newQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'New Quiz · {className}'**
  String newQuizTitle(String className);

  /// No description provided for @newQuizTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get newQuizTitleLabel;

  /// No description provided for @newQuizTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Charlotte’s Web — Chapter 1'**
  String get newQuizTitleHint;

  /// No description provided for @newQuizTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get newQuizTitleRequired;

  /// No description provided for @newQuizDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get newQuizDescriptionLabel;

  /// No description provided for @newQuizCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get newQuizCategory;

  /// No description provided for @newQuizCategoryBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get newQuizCategoryBook;

  /// No description provided for @newQuizCategoryPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get newQuizCategoryPractice;

  /// No description provided for @newQuizCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get newQuizCategoryGeneral;

  /// No description provided for @newQuizBookLabel.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get newQuizBookLabel;

  /// No description provided for @newQuizBookHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Charlotte’s Web'**
  String get newQuizBookHint;

  /// No description provided for @newQuizQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get newQuizQuestions;

  /// No description provided for @newQuizAddQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get newQuizAddQuestion;

  /// No description provided for @newQuizPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get newQuizPublishing;

  /// No description provided for @newQuizPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish to class'**
  String get newQuizPublish;

  /// No description provided for @newQuizPublished.
  ///
  /// In en, this message translates to:
  /// **'Quiz published'**
  String get newQuizPublished;

  /// No description provided for @newQuizCouldNotPublish.
  ///
  /// In en, this message translates to:
  /// **'Could not publish: {error}'**
  String newQuizCouldNotPublish(String error);

  /// No description provided for @newQuizQuestionNeedsText.
  ///
  /// In en, this message translates to:
  /// **'Question {number} needs text.'**
  String newQuizQuestionNeedsText(int number);

  /// No description provided for @newQuizQuestionNeedsChoices.
  ///
  /// In en, this message translates to:
  /// **'Question {number} needs at least two answer choices.'**
  String newQuizQuestionNeedsChoices(int number);

  /// No description provided for @newQuizQuestionNeedsCorrect.
  ///
  /// In en, this message translates to:
  /// **'Question {number} needs a correct answer selected.'**
  String newQuizQuestionNeedsCorrect(int number);

  /// No description provided for @newQuizQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String newQuizQuestionLabel(int number);

  /// No description provided for @newQuizRemoveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove question'**
  String get newQuizRemoveQuestion;

  /// No description provided for @newQuizQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the question'**
  String get newQuizQuestionHint;

  /// No description provided for @newQuizChooseCorrectHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the circle to mark the correct answer'**
  String get newQuizChooseCorrectHint;

  /// No description provided for @newQuizAddChoice.
  ///
  /// In en, this message translates to:
  /// **'Add choice'**
  String get newQuizAddChoice;

  /// No description provided for @newQuizMarkCorrect.
  ///
  /// In en, this message translates to:
  /// **'Mark correct'**
  String get newQuizMarkCorrect;

  /// No description provided for @newQuizChoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Answer choice'**
  String get newQuizChoiceHint;

  /// No description provided for @newQuizRemoveChoice.
  ///
  /// In en, this message translates to:
  /// **'Remove choice'**
  String get newQuizRemoveChoice;

  /// No description provided for @classQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Class Quizzes'**
  String get classQuizTitle;

  /// No description provided for @classQuizDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete quiz?'**
  String get classQuizDeleteTitle;

  /// No description provided for @classQuizDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\"? This clears it for all {count, plural, =1{1 student} other{{count} students}} and deletes their results.'**
  String classQuizDeleteBody(String title, int count);

  /// No description provided for @classQuizShareToHub.
  ///
  /// In en, this message translates to:
  /// **'Share to Hub'**
  String get classQuizShareToHub;

  /// No description provided for @classQuizAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg {percent}%'**
  String classQuizAvg(int percent);

  /// No description provided for @classQuizSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{submitted}/{assigned} submitted'**
  String classQuizSubmitted(int submitted, int assigned);

  /// No description provided for @classQuizEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet'**
  String get classQuizEmptyTitle;

  /// No description provided for @classQuizEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap “New” to publish a quiz to this class.'**
  String get classQuizEmptySubtitle;

  /// No description provided for @quizAnalyticsPerQuestion.
  ///
  /// In en, this message translates to:
  /// **'Per-question breakdown'**
  String get quizAnalyticsPerQuestion;

  /// No description provided for @quizAnalyticsStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get quizAnalyticsStudents;

  /// No description provided for @quizAnalyticsParticipation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get quizAnalyticsParticipation;

  /// No description provided for @quizAnalyticsAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get quizAnalyticsAverageScore;

  /// No description provided for @quizAnalyticsNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get quizAnalyticsNotYet;

  /// No description provided for @booksTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get booksTabTitle;

  /// No description provided for @studentProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Profile'**
  String get studentProfileTitle;

  /// No description provided for @studentProfileReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get studentProfileReport;

  /// No description provided for @studentProfilePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get studentProfilePersonalInfo;

  /// No description provided for @studentProfileStudentId.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get studentProfileStudentId;

  /// No description provided for @studentProfileGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get studentProfileGrade;

  /// No description provided for @studentProfileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get studentProfileFullName;

  /// No description provided for @studentProfileRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get studentProfileRecentActivity;

  /// No description provided for @studentProfileViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View Full History'**
  String get studentProfileViewHistory;

  /// No description provided for @studentProfileParentContacts.
  ///
  /// In en, this message translates to:
  /// **'Parent Contacts'**
  String get studentProfileParentContacts;

  /// No description provided for @studentProfileNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get studentProfileNotes;

  /// No description provided for @studentProfileNotesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load notes: {error}'**
  String studentProfileNotesLoadError(String error);

  /// No description provided for @studentProfileNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get studentProfileNoNotes;

  /// No description provided for @studentProfileAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get studentProfileAddNote;

  /// No description provided for @studentProfileNoteContent.
  ///
  /// In en, this message translates to:
  /// **'Note content'**
  String get studentProfileNoteContent;

  /// No description provided for @studentProfileLoginAccount.
  ///
  /// In en, this message translates to:
  /// **'Login Account'**
  String get studentProfileLoginAccount;

  /// No description provided for @studentProfileCanSignIn.
  ///
  /// In en, this message translates to:
  /// **'Can sign in'**
  String get studentProfileCanSignIn;

  /// No description provided for @studentProfileRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get studentProfileRevoke;

  /// No description provided for @studentProfileNoLogin.
  ///
  /// In en, this message translates to:
  /// **'No login yet. Create one so this student can sign in and see their assignments.'**
  String get studentProfileNoLogin;

  /// No description provided for @studentProfileCreateLogin.
  ///
  /// In en, this message translates to:
  /// **'Create login'**
  String get studentProfileCreateLogin;

  /// No description provided for @studentProfileTempPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get studentProfileTempPassword;

  /// No description provided for @studentProfileLoginCreated.
  ///
  /// In en, this message translates to:
  /// **'Login created. Share the credentials.'**
  String get studentProfileLoginCreated;

  /// No description provided for @studentProfileCouldNotCreate.
  ///
  /// In en, this message translates to:
  /// **'Could not create: {error}'**
  String studentProfileCouldNotCreate(String error);

  /// No description provided for @studentProfileRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke login?'**
  String get studentProfileRevokeTitle;

  /// No description provided for @studentProfileRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'The student will no longer be able to sign in. Their profile and work are kept.'**
  String get studentProfileRevokeBody;

  /// No description provided for @studentProfileCouldNotRevoke.
  ///
  /// In en, this message translates to:
  /// **'Could not revoke: {error}'**
  String studentProfileCouldNotRevoke(String error);

  /// No description provided for @studentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentsTitle;

  /// No description provided for @studentsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add student'**
  String get studentsAdd;

  /// No description provided for @studentsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete student?'**
  String get studentsDeleteTitle;

  /// No description provided for @studentsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}? This cannot be undone.'**
  String studentsDeleteBody(String name);

  /// No description provided for @studentsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String studentsDeleted(String name);

  /// No description provided for @studentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No students yet'**
  String get studentsEmptyTitle;

  /// No description provided for @studentsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add student” to create your first one.'**
  String get studentsEmptySubtitle;

  /// No description provided for @studentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load students'**
  String get studentsLoadError;

  /// No description provided for @readingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Log'**
  String get readingTitle;

  /// No description provided for @readingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your students\' reading adventures.'**
  String get readingSubtitle;

  /// No description provided for @readingAddBook.
  ///
  /// In en, this message translates to:
  /// **'Add New Book'**
  String get readingAddBook;

  /// No description provided for @readingAddStudentsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add students first'**
  String get readingAddStudentsFirst;

  /// No description provided for @readingFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished!'**
  String get readingFinished;

  /// No description provided for @readingInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get readingInProgress;

  /// No description provided for @readingComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get readingComplete;

  /// No description provided for @readingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get readingCompleted;

  /// No description provided for @readingUpdateProgress.
  ///
  /// In en, this message translates to:
  /// **'Update Progress'**
  String get readingUpdateProgress;

  /// No description provided for @readingStatusReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingStatusReading;

  /// No description provided for @readingStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get readingStudent;

  /// No description provided for @readingBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Title'**
  String get readingBookTitle;

  /// No description provided for @readingAuthorOptional.
  ///
  /// In en, this message translates to:
  /// **'Author (optional)'**
  String get readingAuthorOptional;

  /// No description provided for @hwTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework Tracking'**
  String get hwTrackerTitle;

  /// No description provided for @hwTrackerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor your students\' progress.'**
  String get hwTrackerSubtitle;

  /// No description provided for @hwTrackerNewAssignment.
  ///
  /// In en, this message translates to:
  /// **'New Assignment'**
  String get hwTrackerNewAssignment;

  /// No description provided for @hwTrackerThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get hwTrackerThisWeek;

  /// No description provided for @hwTrackerAllStudents.
  ///
  /// In en, this message translates to:
  /// **'All Students'**
  String get hwTrackerAllStudents;

  /// No description provided for @hwTrackerAssignmentChip.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get hwTrackerAssignmentChip;

  /// No description provided for @hwTrackerCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get hwTrackerCompleted;

  /// No description provided for @hwTrackerInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get hwTrackerInProgress;

  /// No description provided for @hwTrackerNoDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get hwTrackerNoDueDate;

  /// No description provided for @hwTrackerDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String hwTrackerDue(String date);

  /// No description provided for @hwTrackerMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get hwTrackerMarkDone;

  /// No description provided for @hwTrackerMarkUndone.
  ///
  /// In en, this message translates to:
  /// **'Mark Undone'**
  String get hwTrackerMarkUndone;

  /// No description provided for @hwTrackerPickDueDate.
  ///
  /// In en, this message translates to:
  /// **'Pick due date'**
  String get hwTrackerPickDueDate;

  /// No description provided for @studentFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit student'**
  String get studentFormEditTitle;

  /// No description provided for @studentFormDobOptional.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (optional)'**
  String get studentFormDobOptional;

  /// No description provided for @studentFormDob.
  ///
  /// In en, this message translates to:
  /// **'DOB: {date}'**
  String studentFormDob(String date);

  /// No description provided for @studentFormNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Student number (optional)'**
  String get studentFormNumberOptional;

  /// No description provided for @studentFormGenderOptional.
  ///
  /// In en, this message translates to:
  /// **'Gender (optional)'**
  String get studentFormGenderOptional;

  /// No description provided for @studentFormGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get studentFormGenderFemale;

  /// No description provided for @studentFormGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get studentFormGenderMale;

  /// No description provided for @studentFormGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get studentFormGenderOther;

  /// No description provided for @studentFormGuardianNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Guardian name (optional)'**
  String get studentFormGuardianNameOptional;

  /// No description provided for @studentFormGuardianPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Guardian phone (optional)'**
  String get studentFormGuardianPhoneOptional;

  /// No description provided for @studentFormNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get studentFormNotesOptional;

  /// No description provided for @booksTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No books yet'**
  String get booksTabEmpty;

  /// No description provided for @booksTabAdd.
  ///
  /// In en, this message translates to:
  /// **'Add book'**
  String get booksTabAdd;

  /// No description provided for @booksTabEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit book'**
  String get booksTabEdit;

  /// No description provided for @homeworkTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No homework yet'**
  String get homeworkTabEmpty;

  /// No description provided for @homeworkTabAdd.
  ///
  /// In en, this message translates to:
  /// **'Add homework'**
  String get homeworkTabAdd;

  /// No description provided for @homeworkTabDueOptional.
  ///
  /// In en, this message translates to:
  /// **'Due date (optional)'**
  String get homeworkTabDueOptional;

  /// No description provided for @notesTabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get notesTabEmpty;

  /// No description provided for @notesTabAdd.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get notesTabAdd;

  /// No description provided for @notesTabNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get notesTabNoteLabel;

  /// No description provided for @notesCategoryBehavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get notesCategoryBehavior;

  /// No description provided for @notesCategoryAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get notesCategoryAcademic;

  /// No description provided for @notesCategorySocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get notesCategorySocial;

  /// No description provided for @notesCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get notesCategoryOther;

  /// No description provided for @infoTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get infoTabTitle;

  /// No description provided for @infoTabStudentNumber.
  ///
  /// In en, this message translates to:
  /// **'Student number'**
  String get infoTabStudentNumber;

  /// No description provided for @infoTabDob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get infoTabDob;

  /// No description provided for @infoTabAge.
  ///
  /// In en, this message translates to:
  /// **'age {age}'**
  String infoTabAge(int age);

  /// No description provided for @infoTabGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get infoTabGender;

  /// No description provided for @infoTabGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get infoTabGuardian;

  /// No description provided for @infoTabGuardianPhone.
  ///
  /// In en, this message translates to:
  /// **'Guardian phone'**
  String get infoTabGuardianPhone;

  /// No description provided for @studentDetailEditInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit info'**
  String get studentDetailEditInfo;

  /// No description provided for @dashboardAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get dashboardAssistant;

  /// No description provided for @dashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find a student…'**
  String get dashboardSearchHint;

  /// No description provided for @dashboardQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get dashboardQuickAccess;

  /// No description provided for @dashboardNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No students found'**
  String get dashboardNoMatch;

  /// No description provided for @dashboardAddStudent.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get dashboardAddStudent;

  /// No description provided for @assignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'{className} · Assignments'**
  String assignmentsTitle(String className);

  /// No description provided for @assignmentsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete assignment?'**
  String get assignmentsDeleteTitle;

  /// No description provided for @assignmentsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\"? This clears it for all {count, plural, =1{1 student} other{{count} students}}.'**
  String assignmentsDeleteBody(String title, int count);

  /// No description provided for @assignmentsDone.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} done'**
  String assignmentsDone(int completed, int total);

  /// No description provided for @assignmentsFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String assignmentsFiles(int count);

  /// No description provided for @assignmentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No assignments yet'**
  String get assignmentsEmptyTitle;

  /// No description provided for @assignmentsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap “New Assignment” to publish work to this class.'**
  String get assignmentsEmptySubtitle;

  /// No description provided for @newAssignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'New Assignment · {className}'**
  String newAssignmentTitle(String className);

  /// No description provided for @newAssignmentTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Read chapter 3'**
  String get newAssignmentTitleHint;

  /// No description provided for @newAssignmentSetDueDate.
  ///
  /// In en, this message translates to:
  /// **'Set a due date (optional)'**
  String get newAssignmentSetDueDate;

  /// No description provided for @newAssignmentPublished.
  ///
  /// In en, this message translates to:
  /// **'Assignment published'**
  String get newAssignmentPublished;

  /// No description provided for @newAssignmentAttachmentsHint.
  ///
  /// In en, this message translates to:
  /// **'Exercises, videos, or files students can download.'**
  String get newAssignmentAttachmentsHint;

  /// No description provided for @classHwAssignments.
  ///
  /// In en, this message translates to:
  /// **'Class Assignments'**
  String get classHwAssignments;

  /// No description provided for @classHwNoAssignments.
  ///
  /// In en, this message translates to:
  /// **'No assignments published to this class yet.'**
  String get classHwNoAssignments;

  /// No description provided for @classHwStudentHomework.
  ///
  /// In en, this message translates to:
  /// **'Student Homework'**
  String get classHwStudentHomework;

  /// No description provided for @classHwStudentHomeworkHint.
  ///
  /// In en, this message translates to:
  /// **'Individual homework per student (add from a student’s page).'**
  String get classHwStudentHomeworkHint;

  /// No description provided for @classReadingAddBook.
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get classReadingAddBook;

  /// No description provided for @classReadingMarkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get classReadingMarkCompleted;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// No description provided for @adminReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReports;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adminOpen;

  /// No description provided for @adminResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get adminResolved;

  /// No description provided for @adminNoOpen.
  ///
  /// In en, this message translates to:
  /// **'No open reports 🎉'**
  String get adminNoOpen;

  /// No description provided for @adminNoResolved.
  ///
  /// In en, this message translates to:
  /// **'No resolved reports.'**
  String get adminNoResolved;

  /// No description provided for @adminReportTitlePost.
  ///
  /// In en, this message translates to:
  /// **'Post report'**
  String get adminReportTitlePost;

  /// No description provided for @adminReportTitleComment.
  ///
  /// In en, this message translates to:
  /// **'Comment report'**
  String get adminReportTitleComment;

  /// No description provided for @adminContentRemoved.
  ///
  /// In en, this message translates to:
  /// **'[content removed]'**
  String get adminContentRemoved;

  /// No description provided for @adminReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String adminReason(String reason);

  /// No description provided for @adminReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by {name}'**
  String adminReportedBy(String name);

  /// No description provided for @adminDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adminDismiss;

  /// No description provided for @adminRemoveContent.
  ///
  /// In en, this message translates to:
  /// **'Remove content'**
  String get adminRemoveContent;

  /// No description provided for @adminContentRemovedMsg.
  ///
  /// In en, this message translates to:
  /// **'Content removed'**
  String get adminContentRemovedMsg;

  /// No description provided for @adminReportDismissed.
  ///
  /// In en, this message translates to:
  /// **'Report dismissed'**
  String get adminReportDismissed;

  /// No description provided for @adminActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed: {error}'**
  String adminActionFailed(String error);

  /// No description provided for @adminRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleAdmin;

  /// No description provided for @adminRoleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get adminRoleStudent;

  /// No description provided for @adminRoleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get adminRoleTeacher;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Teachers, quizzes, documents…'**
  String get searchHint;

  /// No description provided for @searchTeachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get searchTeachers;

  /// No description provided for @searchDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get searchDocs;

  /// No description provided for @searchMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get searchMaterials;

  /// No description provided for @searchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Search teachers and shared materials'**
  String get searchEmptyHint;

  /// No description provided for @searchByAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String searchByAuthor(String author);

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notifEmptyTitle;

  /// No description provided for @notifEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notifEmptySubtitle;

  /// No description provided for @homeTeacherFallback.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get homeTeacherFallback;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get homeGreetingEvening;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// No description provided for @homeRecentStudents.
  ///
  /// In en, this message translates to:
  /// **'Recent Students'**
  String get homeRecentStudents;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeAddFirstStudent.
  ///
  /// In en, this message translates to:
  /// **'Add your first student to get started.'**
  String get homeAddFirstStudent;

  /// No description provided for @stuAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get stuAssignments;

  /// No description provided for @stuMyClasses.
  ///
  /// In en, this message translates to:
  /// **'My Classes'**
  String get stuMyClasses;

  /// No description provided for @stuNoClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'Not in any class yet'**
  String get stuNoClassesTitle;

  /// No description provided for @stuNoClassesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your teacher will enroll you in a class.'**
  String get stuNoClassesSubtitle;

  /// No description provided for @stuStudentFallback.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get stuStudentFallback;

  /// No description provided for @stuStudentNumber.
  ///
  /// In en, this message translates to:
  /// **'Student No. {number}'**
  String stuStudentNumber(String number);

  /// No description provided for @stuEnrolledClasses.
  ///
  /// In en, this message translates to:
  /// **'Enrolled classes'**
  String get stuEnrolledClasses;

  /// No description provided for @stuMyAssignments.
  ///
  /// In en, this message translates to:
  /// **'My Assignments'**
  String get stuMyAssignments;

  /// No description provided for @stuCouldNotUpdate.
  ///
  /// In en, this message translates to:
  /// **'Could not update: {error}'**
  String stuCouldNotUpdate(String error);

  /// No description provided for @stuMarkNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark not done'**
  String get stuMarkNotDone;

  /// No description provided for @stuAssignmentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Work your teacher assigns will show up here.'**
  String get stuAssignmentsEmptyHint;

  /// No description provided for @stuMyQuizzes.
  ///
  /// In en, this message translates to:
  /// **'My Quizzes'**
  String get stuMyQuizzes;

  /// No description provided for @stuScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score}/{total}'**
  String stuScore(int score, int total);

  /// No description provided for @stuTapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get stuTapToStart;

  /// No description provided for @stuQuizzesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Quizzes your teacher assigns will show up here.'**
  String get stuQuizzesEmptyHint;

  /// No description provided for @stuQuizCouldNotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Could not submit: {error}'**
  String stuQuizCouldNotSubmit(String error);

  /// No description provided for @stuQuizNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'This quiz has no questions.'**
  String get stuQuizNoQuestions;

  /// No description provided for @stuQuizQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String stuQuizQuestionOf(int current, int total);

  /// No description provided for @stuQuizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get stuQuizNext;

  /// No description provided for @stuQuizSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get stuQuizSubmitting;

  /// No description provided for @stuQuizFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get stuQuizFinish;

  /// No description provided for @stuQuizAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'Already completed'**
  String get stuQuizAlreadyDone;

  /// No description provided for @stuQuizComplete.
  ///
  /// In en, this message translates to:
  /// **'Quiz complete!'**
  String get stuQuizComplete;

  /// No description provided for @stuQuizPctCorrect.
  ///
  /// In en, this message translates to:
  /// **'{percent}% correct'**
  String stuQuizPctCorrect(int percent);

  /// No description provided for @stuHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get stuHome;

  /// No description provided for @stuHomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String stuHomeGreeting(String name);

  /// No description provided for @stuHomeDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get stuHomeDueSoon;

  /// No description provided for @stuHomeNoDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Nothing due soon. Nice work!'**
  String get stuHomeNoDueSoon;

  /// No description provided for @stuHomeQuizProgress.
  ///
  /// In en, this message translates to:
  /// **'Quiz progress'**
  String get stuHomeQuizProgress;

  /// No description provided for @stuHomeQuizzesDone.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done'**
  String stuHomeQuizzesDone(int done, int total);

  /// No description provided for @stuHomePendingQuizzes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All caught up} =1{1 quiz to solve} other{{count} quizzes to solve}}'**
  String stuHomePendingQuizzes(int count);

  /// No description provided for @stuHomeClassesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 class} other{{count} classes}}'**
  String stuHomeClassesCount(int count);

  /// No description provided for @stuHomeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get stuHomeSeeAll;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one.'**
  String get changePasswordSubtitle;

  /// No description provided for @changePasswordFirstLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your own password to finish signing in.'**
  String get changePasswordFirstLoginSubtitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordSubmit;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get changePasswordSuccess;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileYourPosts.
  ///
  /// In en, this message translates to:
  /// **'Your posts'**
  String get profileYourPosts;

  /// No description provided for @profileChangeCover.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get profileChangeCover;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @attachLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Download link for \"{name}\" copied'**
  String attachLinkCopied(String name);

  /// No description provided for @attachCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String attachCouldNotOpen(String error);

  /// No description provided for @attachStoragePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage permission needed to save: {message}'**
  String attachStoragePermission(String message);

  /// No description provided for @attachCouldNotDownload.
  ///
  /// In en, this message translates to:
  /// **'Could not download: {error}'**
  String attachCouldNotDownload(String error);

  /// No description provided for @attachSaveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get attachSaveToDevice;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkip;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Teacher Tracker'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get your class set up in a few quick steps.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first class'**
  String get onboardingClassTitle;

  /// No description provided for @onboardingClassBody.
  ///
  /// In en, this message translates to:
  /// **'Classes group your students so you can post homework, quizzes, and track reading together.'**
  String get onboardingClassBody;

  /// No description provided for @onboardingCreateClass.
  ///
  /// In en, this message translates to:
  /// **'Create a class'**
  String get onboardingCreateClass;

  /// No description provided for @onboardingStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first student'**
  String get onboardingStudentTitle;

  /// No description provided for @onboardingStudentBody.
  ///
  /// In en, this message translates to:
  /// **'Add a student profile to start tracking homework, reading, and notes.'**
  String get onboardingStudentBody;

  /// No description provided for @onboardingAddStudent.
  ///
  /// In en, this message translates to:
  /// **'Add a student'**
  String get onboardingAddStudent;

  /// No description provided for @onboardingDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get onboardingDoneTitle;

  /// No description provided for @onboardingDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Open a class any time to publish assignments and quizzes to your students.'**
  String get onboardingDoneBody;

  /// No description provided for @onboardingGoHub.
  ///
  /// In en, this message translates to:
  /// **'Go to your Hub'**
  String get onboardingGoHub;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
