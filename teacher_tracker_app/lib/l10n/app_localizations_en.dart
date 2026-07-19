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
  String get connectivityOffline => 'You\'re offline';

  @override
  String get connectivityBackOnline => 'Back online';

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
  String get commonAll => 'All';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonTitle => 'Title';

  @override
  String get commonDescriptionOptional => 'Description (optional)';

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
  String commonSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String commonAddFailed(String error) {
    return 'Add failed: $error';
  }

  @override
  String commonCouldNotPublish(String error) {
    return 'Could not publish: $error';
  }

  @override
  String get commonClear => 'Clear';

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
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsHapticsToggle => 'Vibration feedback';

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

  @override
  String get studentsTitle => 'Students';

  @override
  String get studentsAdd => 'Add student';

  @override
  String get studentsDeleteTitle => 'Delete student?';

  @override
  String studentsDeleteBody(String name) {
    return 'Remove $name? This cannot be undone.';
  }

  @override
  String studentsDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String get studentsEmptyTitle => 'No students yet';

  @override
  String get studentsEmptySubtitle =>
      'Tap “Add student” to create your first one.';

  @override
  String get studentsLoadError => 'Could not load students';

  @override
  String get readingTitle => 'Reading Log';

  @override
  String get readingSubtitle => 'Track your students\' reading adventures.';

  @override
  String get readingAddBook => 'Add New Book';

  @override
  String get readingAddStudentsFirst => 'Add students first';

  @override
  String get readingFinished => 'Finished!';

  @override
  String get readingInProgress => 'In progress';

  @override
  String get readingComplete => 'Complete';

  @override
  String get readingCompleted => 'Completed';

  @override
  String get readingUpdateProgress => 'Update Progress';

  @override
  String get readingStatusReading => 'Reading';

  @override
  String get readingStudent => 'Student';

  @override
  String get readingBookTitle => 'Book Title';

  @override
  String get readingAuthorOptional => 'Author (optional)';

  @override
  String get hwTrackerTitle => 'Homework Tracking';

  @override
  String get hwTrackerSubtitle => 'Monitor your students\' progress.';

  @override
  String get hwTrackerNewAssignment => 'New Assignment';

  @override
  String get hwTrackerThisWeek => 'This Week';

  @override
  String get hwTrackerAllStudents => 'All Students';

  @override
  String get hwTrackerAssignmentChip => 'Assignment';

  @override
  String get hwTrackerCompleted => 'Completed';

  @override
  String get hwTrackerInProgress => 'In Progress';

  @override
  String get hwTrackerNoDueDate => 'No due date';

  @override
  String hwTrackerDue(String date) {
    return 'Due $date';
  }

  @override
  String get hwTrackerMarkDone => 'Mark Done';

  @override
  String get hwTrackerMarkUndone => 'Mark Undone';

  @override
  String get hwTrackerPickDueDate => 'Pick due date';

  @override
  String get studentFormEditTitle => 'Edit student';

  @override
  String get studentFormDobOptional => 'Date of birth (optional)';

  @override
  String studentFormDob(String date) {
    return 'DOB: $date';
  }

  @override
  String get studentFormNumberOptional => 'Student number (optional)';

  @override
  String get studentFormGenderOptional => 'Gender (optional)';

  @override
  String get studentFormGenderFemale => 'Female';

  @override
  String get studentFormGenderMale => 'Male';

  @override
  String get studentFormGenderOther => 'Other';

  @override
  String get studentFormGuardianNameOptional => 'Guardian name (optional)';

  @override
  String get studentFormGuardianPhoneOptional => 'Guardian phone (optional)';

  @override
  String get studentFormNotesOptional => 'Notes (optional)';

  @override
  String get booksTabEmpty => 'No books yet';

  @override
  String get booksTabAdd => 'Add book';

  @override
  String get booksTabEdit => 'Edit book';

  @override
  String get homeworkTabEmpty => 'No homework yet';

  @override
  String get homeworkTabAdd => 'Add homework';

  @override
  String get homeworkTabDueOptional => 'Due date (optional)';

  @override
  String get notesTabEmpty => 'No notes yet';

  @override
  String get notesTabAdd => 'Add note';

  @override
  String get notesTabNoteLabel => 'Note';

  @override
  String get notesCategoryBehavior => 'Behavior';

  @override
  String get notesCategoryAcademic => 'Academic';

  @override
  String get notesCategorySocial => 'Social';

  @override
  String get notesCategoryOther => 'Other';

  @override
  String get infoTabTitle => 'Info';

  @override
  String get infoTabStudentNumber => 'Student number';

  @override
  String get infoTabDob => 'Date of birth';

  @override
  String infoTabAge(int age) {
    return 'age $age';
  }

  @override
  String get infoTabGender => 'Gender';

  @override
  String get infoTabGuardian => 'Guardian';

  @override
  String get infoTabGuardianPhone => 'Guardian phone';

  @override
  String get studentDetailEditInfo => 'Edit info';

  @override
  String get dashboardAssistant => 'Assistant';

  @override
  String get dashboardSearchHint => 'Find a student…';

  @override
  String get dashboardQuickAccess => 'Quick Access';

  @override
  String get dashboardNoMatch => 'No students found';

  @override
  String get dashboardAddStudent => 'Add Student';

  @override
  String assignmentsTitle(String className) {
    return '$className · Assignments';
  }

  @override
  String get assignmentsDeleteTitle => 'Delete assignment?';

  @override
  String assignmentsDeleteBody(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
    );
    return 'Remove \"$title\"? This clears it for all $_temp0.';
  }

  @override
  String assignmentsDone(int completed, int total) {
    return '$completed/$total done';
  }

  @override
  String assignmentsFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get assignmentsEmptyTitle => 'No assignments yet';

  @override
  String get assignmentsEmptySubtitle =>
      'Tap “New Assignment” to publish work to this class.';

  @override
  String newAssignmentTitle(String className) {
    return 'New Assignment · $className';
  }

  @override
  String get newAssignmentTitleHint => 'e.g. Read chapter 3';

  @override
  String get newAssignmentSetDueDate => 'Set a due date (optional)';

  @override
  String get newAssignmentPublished => 'Assignment published';

  @override
  String get newAssignmentAttachmentsHint =>
      'Exercises, videos, or files students can download.';

  @override
  String get classHwAssignments => 'Class Assignments';

  @override
  String get classHwNoAssignments =>
      'No assignments published to this class yet.';

  @override
  String get classHwStudentHomework => 'Student Homework';

  @override
  String get classHwStudentHomeworkHint =>
      'Individual homework per student (add from a student’s page).';

  @override
  String get classReadingAddBook => 'Add Book';

  @override
  String get classReadingMarkCompleted => 'Mark completed';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminReports => 'Reports';

  @override
  String get adminUsers => 'Users';

  @override
  String get adminOpen => 'Open';

  @override
  String get adminResolved => 'Resolved';

  @override
  String get adminNoOpen => 'No open reports 🎉';

  @override
  String get adminNoResolved => 'No resolved reports.';

  @override
  String get adminReportTitlePost => 'Post report';

  @override
  String get adminReportTitleComment => 'Comment report';

  @override
  String get adminContentRemoved => '[content removed]';

  @override
  String adminReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String adminReportedBy(String name) {
    return 'Reported by $name';
  }

  @override
  String get adminDismiss => 'Dismiss';

  @override
  String get adminRemoveContent => 'Remove content';

  @override
  String get adminContentRemovedMsg => 'Content removed';

  @override
  String get adminReportDismissed => 'Report dismissed';

  @override
  String adminActionFailed(String error) {
    return 'Action failed: $error';
  }

  @override
  String get adminRoleAdmin => 'Admin';

  @override
  String get adminRoleStudent => 'Student';

  @override
  String get adminRoleTeacher => 'Teacher';

  @override
  String get searchTitle => 'Discover';

  @override
  String get searchHint => 'Teachers, quizzes, documents…';

  @override
  String get searchTeachers => 'Teachers';

  @override
  String get searchDocs => 'Docs';

  @override
  String get searchMaterials => 'Materials';

  @override
  String get searchEmptyHint => 'Search teachers and shared materials';

  @override
  String searchByAuthor(String author) {
    return 'by $author';
  }

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifEmptyTitle => 'No notifications';

  @override
  String get notifEmptySubtitle => 'You\'re all caught up.';

  @override
  String get homeTeacherFallback => 'Teacher';

  @override
  String get homeGreetingMorning => 'Good morning,';

  @override
  String get homeGreetingAfternoon => 'Good afternoon,';

  @override
  String get homeGreetingEvening => 'Good evening,';

  @override
  String get homeQuickActions => 'Quick Actions';

  @override
  String get homeRecentStudents => 'Recent Students';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeAddFirstStudent => 'Add your first student to get started.';

  @override
  String get stuAssignments => 'Assignments';

  @override
  String get stuMyClasses => 'My Classes';

  @override
  String get stuNoClassesTitle => 'Not in any class yet';

  @override
  String get stuNoClassesSubtitle => 'Your teacher will enroll you in a class.';

  @override
  String get stuStudentFallback => 'Student';

  @override
  String stuStudentNumber(String number) {
    return 'Student No. $number';
  }

  @override
  String get stuEnrolledClasses => 'Enrolled classes';

  @override
  String get stuMyAssignments => 'My Assignments';

  @override
  String stuCouldNotUpdate(String error) {
    return 'Could not update: $error';
  }

  @override
  String get stuMarkNotDone => 'Mark not done';

  @override
  String get stuAssignmentsEmptyHint =>
      'Work your teacher assigns will show up here.';

  @override
  String get stuMyQuizzes => 'My Quizzes';

  @override
  String stuScore(int score, int total) {
    return 'Score $score/$total';
  }

  @override
  String get stuTapToStart => 'Tap to start';

  @override
  String get stuQuizzesEmptyHint =>
      'Quizzes your teacher assigns will show up here.';

  @override
  String stuQuizCouldNotSubmit(String error) {
    return 'Could not submit: $error';
  }

  @override
  String get stuQuizNoQuestions => 'This quiz has no questions.';

  @override
  String stuQuizQuestionOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get stuQuizNext => 'Next';

  @override
  String get stuQuizSubmitting => 'Submitting…';

  @override
  String get stuQuizFinish => 'Finish';

  @override
  String get stuQuizAlreadyDone => 'Already completed';

  @override
  String get stuQuizComplete => 'Quiz complete!';

  @override
  String stuQuizPctCorrect(int percent) {
    return '$percent% correct';
  }

  @override
  String get stuHome => 'Home';

  @override
  String stuHomeGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get stuHomeDueSoon => 'Due soon';

  @override
  String get stuHomeNoDueSoon => 'Nothing due soon. Nice work!';

  @override
  String get stuHomeQuizProgress => 'Quiz progress';

  @override
  String stuHomeQuizzesDone(int done, int total) {
    return '$done/$total done';
  }

  @override
  String stuHomePendingQuizzes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quizzes to solve',
      one: '1 quiz to solve',
      zero: 'All caught up',
    );
    return '$_temp0';
  }

  @override
  String stuHomeClassesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes',
      one: '1 class',
    );
    return '$_temp0';
  }

  @override
  String get stuHomeSeeAll => 'See all';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordSubtitle =>
      'Enter your current password and choose a new one.';

  @override
  String get changePasswordFirstLoginSubtitle =>
      'Set your own password to finish signing in.';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get changePasswordSubmit => 'Change password';

  @override
  String get changePasswordSuccess => 'Password changed.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileYourPosts => 'Your posts';

  @override
  String get profileChangeCover => 'Change cover';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String attachLinkCopied(String name) {
    return 'Download link for \"$name\" copied';
  }

  @override
  String attachCouldNotOpen(String error) {
    return 'Could not open file: $error';
  }

  @override
  String attachStoragePermission(String message) {
    return 'Storage permission needed to save: $message';
  }

  @override
  String attachCouldNotDownload(String error) {
    return 'Could not download: $error';
  }

  @override
  String get attachSaveToDevice => 'Save to device';

  @override
  String get onboardingSkip => 'Skip for now';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Teacher Tracker';

  @override
  String get onboardingWelcomeBody =>
      'Let\'s get your class set up in a few quick steps.';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingClassTitle => 'Create your first class';

  @override
  String get onboardingClassBody =>
      'Classes group your students so you can post homework, quizzes, and track reading together.';

  @override
  String get onboardingCreateClass => 'Create a class';

  @override
  String get onboardingStudentTitle => 'Add your first student';

  @override
  String get onboardingStudentBody =>
      'Add a student profile to start tracking homework, reading, and notes.';

  @override
  String get onboardingAddStudent => 'Add a student';

  @override
  String get onboardingDoneTitle => 'You\'re all set';

  @override
  String get onboardingDoneBody =>
      'Open a class any time to publish assignments and quizzes to your students.';

  @override
  String get onboardingGoHub => 'Go to your Hub';
}
