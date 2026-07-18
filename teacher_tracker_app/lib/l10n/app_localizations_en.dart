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
  String get commonShare => 'Share';

  @override
  String get commonReport => 'Report';

  @override
  String commonUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get commonNew => 'New';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonNotAvailable => 'N/A';

  @override
  String commonCouldNotDelete(String error) {
    return 'Could not delete: $error';
  }

  @override
  String commonFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String commonCouldNotLoad(String error) {
    return 'Could not load: $error';
  }

  @override
  String get commonTimeJustNow => 'just now';

  @override
  String commonTimeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String commonTimeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String commonTimeDaysAgo(int days) {
    return '${days}d ago';
  }

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

  @override
  String feedShareSubject(String name) {
    return '$name shared a post';
  }

  @override
  String feedQuizAssigned(String title, String className) {
    return 'Assigned \"$title\" to $className';
  }

  @override
  String feedCouldNotAssign(String error) {
    return 'Could not assign: $error';
  }

  @override
  String get feedPinToProfile => 'Pin to profile';

  @override
  String get feedUnpinFromProfile => 'Unpin from profile';

  @override
  String get feedDeletePostTitle => 'Delete post?';

  @override
  String get feedDeletePostBody =>
      'This removes it from the feed for everyone.';

  @override
  String feedCouldNotDelete(String error) {
    return 'Could not delete: $error';
  }

  @override
  String get feedReported => 'Reported — thanks. An admin will review it.';

  @override
  String feedCouldNotReport(String error) {
    return 'Could not report: $error';
  }

  @override
  String feedQuizQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get feedNotRatedYet => 'Not rated yet';

  @override
  String get feedAssignToClass => 'Assign to My Class';

  @override
  String get feedAssignWhichClass => 'Assign to which class?';

  @override
  String get feedNoClassesYet => 'You have no classes yet. Create one first.';

  @override
  String get newPostPublished => 'Post published';

  @override
  String newPostCouldNotPublish(String error) {
    return 'Could not publish: $error';
  }

  @override
  String get newPostTextLabel => 'Share something';

  @override
  String get newPostTextHint => 'An exercise, a tip, a resource…';

  @override
  String get newPostTextRequired => 'Write something to post';

  @override
  String get newPostSubject => 'Subject';

  @override
  String get newPostGradeLevel => 'Grade level (optional)';

  @override
  String get newPostShareQuiz => 'Share a quiz (optional)';

  @override
  String get newPostAttachQuiz => 'Attach one of my quizzes';

  @override
  String get newPostQuizFallback => 'Quiz';

  @override
  String get newPostAttachments => 'Attachments';

  @override
  String get newPostAddFiles => 'Add files';

  @override
  String get newPostAttachmentsHint =>
      'Exercises, videos, or files other teachers can download.';

  @override
  String get newPostPublishing => 'Publishing…';

  @override
  String get newPostSubmit => 'Post to hub';

  @override
  String get newPostShareWhichQuiz => 'Share which quiz?';

  @override
  String get newPostNoQuizzes => 'You haven’t created any quizzes yet.';

  @override
  String newPostQuizSubtitle(String className, String questions) {
    return '$className · $questions';
  }

  @override
  String get reportPostTitle => 'Report post';

  @override
  String get reportCommentTitle => 'Report comment';

  @override
  String get reportReasonLabel => 'Reason';

  @override
  String get reportReasonHint => 'Why are you reporting this?';

  @override
  String get postDetailTitle => 'Post';

  @override
  String get postDetailLoadError => 'This post couldn\'t be loaded.';

  @override
  String postDetailCouldNotRate(String error) {
    return 'Could not rate: $error';
  }

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentsEmpty => 'No comments yet — be the first.';

  @override
  String get commentsHint => 'Add a comment…';

  @override
  String commentsCouldNotAdd(String error) {
    return 'Could not comment: $error';
  }

  @override
  String newQuizTitle(String className) {
    return 'New Quiz · $className';
  }

  @override
  String get newQuizTitleLabel => 'Title';

  @override
  String get newQuizTitleHint => 'e.g. Charlotte’s Web — Chapter 1';

  @override
  String get newQuizTitleRequired => 'Title is required';

  @override
  String get newQuizDescriptionLabel => 'Description (optional)';

  @override
  String get newQuizCategory => 'Category';

  @override
  String get newQuizCategoryBook => 'Book';

  @override
  String get newQuizCategoryPractice => 'Practice';

  @override
  String get newQuizCategoryGeneral => 'General';

  @override
  String get newQuizBookLabel => 'Book';

  @override
  String get newQuizBookHint => 'e.g. Charlotte’s Web';

  @override
  String get newQuizQuestions => 'Questions';

  @override
  String get newQuizAddQuestion => 'Add question';

  @override
  String get newQuizPublishing => 'Publishing…';

  @override
  String get newQuizPublish => 'Publish to class';

  @override
  String get newQuizPublished => 'Quiz published';

  @override
  String newQuizCouldNotPublish(String error) {
    return 'Could not publish: $error';
  }

  @override
  String newQuizQuestionNeedsText(int number) {
    return 'Question $number needs text.';
  }

  @override
  String newQuizQuestionNeedsChoices(int number) {
    return 'Question $number needs at least two answer choices.';
  }

  @override
  String newQuizQuestionNeedsCorrect(int number) {
    return 'Question $number needs a correct answer selected.';
  }

  @override
  String newQuizQuestionLabel(int number) {
    return 'Question $number';
  }

  @override
  String get newQuizRemoveQuestion => 'Remove question';

  @override
  String get newQuizQuestionHint => 'Enter the question';

  @override
  String get newQuizChooseCorrectHint =>
      'Tap the circle to mark the correct answer';

  @override
  String get newQuizAddChoice => 'Add choice';

  @override
  String get newQuizMarkCorrect => 'Mark correct';

  @override
  String get newQuizChoiceHint => 'Answer choice';

  @override
  String get newQuizRemoveChoice => 'Remove choice';

  @override
  String get classQuizTitle => 'Class Quizzes';

  @override
  String get classQuizDeleteTitle => 'Delete quiz?';

  @override
  String classQuizDeleteBody(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
    );
    return 'Remove \"$title\"? This clears it for all $_temp0 and deletes their results.';
  }

  @override
  String get classQuizShareToHub => 'Share to Hub';

  @override
  String classQuizAvg(int percent) {
    return 'Avg $percent%';
  }

  @override
  String classQuizSubmitted(int submitted, int assigned) {
    return '$submitted/$assigned submitted';
  }

  @override
  String get classQuizEmptyTitle => 'No quizzes yet';

  @override
  String get classQuizEmptySubtitle =>
      'Tap “New” to publish a quiz to this class.';

  @override
  String get quizAnalyticsPerQuestion => 'Per-question breakdown';

  @override
  String get quizAnalyticsStudents => 'Students';

  @override
  String get quizAnalyticsParticipation => 'Participation';

  @override
  String get quizAnalyticsAverageScore => 'Average score';

  @override
  String get quizAnalyticsNotYet => 'Not yet';

  @override
  String get booksTabTitle => 'Books';

  @override
  String get studentProfileTitle => 'Student Profile';

  @override
  String get studentProfileReport => 'Report';

  @override
  String get studentProfilePersonalInfo => 'Personal Info';

  @override
  String get studentProfileStudentId => 'Student ID';

  @override
  String get studentProfileGrade => 'Grade';

  @override
  String get studentProfileFullName => 'Full Name';

  @override
  String get studentProfileRecentActivity => 'Recent Activity';

  @override
  String get studentProfileViewHistory => 'View Full History';

  @override
  String get studentProfileParentContacts => 'Parent Contacts';

  @override
  String get studentProfileNotes => 'Notes';

  @override
  String studentProfileNotesLoadError(String error) {
    return 'Could not load notes: $error';
  }

  @override
  String get studentProfileNoNotes => 'No notes yet.';

  @override
  String get studentProfileAddNote => 'Add Note';

  @override
  String get studentProfileNoteContent => 'Note content';

  @override
  String get studentProfileLoginAccount => 'Login Account';

  @override
  String get studentProfileCanSignIn => 'Can sign in';

  @override
  String get studentProfileRevoke => 'Revoke';

  @override
  String get studentProfileNoLogin =>
      'No login yet. Create one so this student can sign in and see their assignments.';

  @override
  String get studentProfileCreateLogin => 'Create login';

  @override
  String get studentProfileTempPassword => 'Temporary password';

  @override
  String get studentProfileLoginCreated =>
      'Login created. Share the credentials.';

  @override
  String studentProfileCouldNotCreate(String error) {
    return 'Could not create: $error';
  }

  @override
  String get studentProfileRevokeTitle => 'Revoke login?';

  @override
  String get studentProfileRevokeBody =>
      'The student will no longer be able to sign in. Their profile and work are kept.';

  @override
  String studentProfileCouldNotRevoke(String error) {
    return 'Could not revoke: $error';
  }
}
