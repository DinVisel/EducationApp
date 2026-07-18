// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonRequired => 'Zorunlu alan';

  @override
  String get commonInvalidEmail => 'Geçerli bir e-posta girin';

  @override
  String get commonPasswordTooShort => 'En az 6 karakter olmalı';

  @override
  String get commonPasswordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get commonNetworkError => 'Ağ hatası. Sunucu çalışıyor mu?';

  @override
  String get commonSomethingWentWrong => 'Bir şeyler ters gitti.';

  @override
  String commonError(String error) {
    return 'Hata: $error';
  }

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonAdd => 'Ekle';

  @override
  String get commonRemove => 'Kaldır';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonDone => 'Tamam';

  @override
  String get commonLoading => 'Yükleniyor…';

  @override
  String get commonSearch => 'Ara';

  @override
  String get commonEmpty => 'Burada henüz bir şey yok.';

  @override
  String get commonShare => 'Paylaş';

  @override
  String get commonReport => 'Bildir';

  @override
  String commonUploadFailed(String error) {
    return 'Yükleme başarısız: $error';
  }

  @override
  String get commonNew => 'Yeni';

  @override
  String get commonAll => 'Tümü';

  @override
  String get commonCreate => 'Oluştur';

  @override
  String get commonEmail => 'E-posta';

  @override
  String get commonTitle => 'Başlık';

  @override
  String get commonDescriptionOptional => 'Açıklama (isteğe bağlı)';

  @override
  String get commonNotAvailable => 'Yok';

  @override
  String commonCouldNotDelete(String error) {
    return 'Silinemedi: $error';
  }

  @override
  String commonFailed(String error) {
    return 'Başarısız: $error';
  }

  @override
  String commonCouldNotLoad(String error) {
    return 'Yüklenemedi: $error';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Kaydetme başarısız: $error';
  }

  @override
  String commonAddFailed(String error) {
    return 'Ekleme başarısız: $error';
  }

  @override
  String get commonClear => 'Temizle';

  @override
  String get commonTimeJustNow => 'az önce';

  @override
  String commonTimeMinutesAgo(int minutes) {
    return '$minutes dk önce';
  }

  @override
  String commonTimeHoursAgo(int hours) {
    return '$hours sa önce';
  }

  @override
  String commonTimeDaysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String get loginTitle => 'Teacher Tracker';

  @override
  String get loginSubtitle => 'Öğrencilerinizi takip etmek için giriş yapın';

  @override
  String get loginEmailLabel => 'E-posta';

  @override
  String get loginPasswordLabel => 'Şifre';

  @override
  String get loginForgotPassword => 'Şifremi unuttum';

  @override
  String get loginSignIn => 'Giriş yap';

  @override
  String get loginNoAccount => 'Hesabınız yok mu? Kayıt olun';

  @override
  String get loginInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get registerTitle => 'Hesap oluştur';

  @override
  String get registerFirstName => 'Ad';

  @override
  String get registerLastName => 'Soyad';

  @override
  String get registerEmail => 'E-posta';

  @override
  String get registerPasswordHint => 'Şifre (en az 6 karakter)';

  @override
  String get registerSubmit => 'Hesap oluştur';

  @override
  String get registerEmailTaken => 'Bu e-posta zaten kayıtlı.';

  @override
  String get forgotPasswordTitle => 'Şifremi unuttum';

  @override
  String get forgotPasswordSubtitle =>
      'Hesabınızın e-postasını girin, size bir sıfırlama kodu gönderelim.';

  @override
  String get forgotPasswordEmailLabel => 'E-posta';

  @override
  String get forgotPasswordSubmit => 'Sıfırlama kodu gönder';

  @override
  String get forgotPasswordBackToSignIn => 'Girişe dön';

  @override
  String get forgotPasswordConfirmTitle => 'E-postanızı kontrol edin';

  @override
  String get forgotPasswordConfirmBody =>
      'Bu e-posta kayıtlıysa, bir sıfırlama kodu gönderdik.';

  @override
  String get forgotPasswordHaveCode => 'Kodum var';

  @override
  String get resetPasswordTitle => 'Şifreyi sıfırla';

  @override
  String get resetPasswordSubtitle =>
      'E-postanıza gönderdiğimiz kodu girin ve yeni bir şifre belirleyin.';

  @override
  String get resetPasswordCodeLabel => 'Sıfırlama kodu';

  @override
  String get resetPasswordNewPasswordLabel => 'Yeni şifre';

  @override
  String get resetPasswordConfirmLabel => 'Yeni şifreyi onayla';

  @override
  String get resetPasswordSubmit => 'Şifreyi sıfırla';

  @override
  String get resetPasswordSuccess =>
      'Şifre sıfırlandı. Yeni şifrenizle giriş yapın.';

  @override
  String get resetPasswordBackToSignIn => 'Girişe dön';

  @override
  String get navHub => 'Akış';

  @override
  String get navSearch => 'Ara';

  @override
  String get navClasses => 'Sınıflar';

  @override
  String get navProfile => 'Profil';

  @override
  String get navNewPost => 'Yeni Gönderi';

  @override
  String get navNewClass => 'Yeni Sınıf';

  @override
  String get feedTitle => 'Topluluk Merkezi';

  @override
  String get feedEmptyTitle => 'Henüz gönderi yok';

  @override
  String get feedEmptyBody =>
      'Diğer öğretmenlerle bir kaynak paylaşmak için \"Yeni Gönderi\"ye dokunun.';

  @override
  String get feedFilterAll => 'Tümü';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsAccount => 'Hesap';

  @override
  String get settingsFirstName => 'Ad';

  @override
  String get settingsLastName => 'Soyad';

  @override
  String get settingsEmail => 'E-posta';

  @override
  String get settingsSaveChanges => 'Değişiklikleri kaydet';

  @override
  String get settingsProfileSaved => 'Profil kaydedildi';

  @override
  String settingsSaveFailed(String error) {
    return 'Kaydetme başarısız: $error';
  }

  @override
  String get settingsSignOut => 'Çıkış yap';

  @override
  String get settingsSignOutConfirmTitle => 'Çıkış yapılsın mı?';

  @override
  String get settingsSignOutConfirmBody => 'Tekrar giriş yapmanız gerekecek.';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageEnglish => 'İngilizce';

  @override
  String get settingsLanguageTurkish => 'Türkçe';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get imageCropperTitle => 'Fotoğrafı düzenle';

  @override
  String get attendanceTitle => 'Yoklama';

  @override
  String get attendanceTabLabel => 'Yoklama';

  @override
  String get attendanceStatusPresent => 'Var';

  @override
  String get attendanceStatusAbsent => 'Yok';

  @override
  String get attendanceStatusLate => 'Geç';

  @override
  String get attendanceStatusExcused => 'İzinli';

  @override
  String get attendanceSave => 'Kaydet';

  @override
  String get attendanceSaved => 'Yoklama kaydedildi';

  @override
  String attendanceSaveFailed(String error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get attendanceEmptyRoster => 'Bu sınıfta henüz öğrenci yok.';

  @override
  String get attendancePickDate => 'Tarih seç';

  @override
  String get attendanceMarkAllPresent => 'Tümünü var işaretle';

  @override
  String get attendanceUnmarked => 'İşaretlenmedi';

  @override
  String get attendanceHistoryTitle => 'Yoklama geçmişi';

  @override
  String get attendanceHistoryEmpty => 'Henüz yoklama kaydı yok.';

  @override
  String get attendanceViewHistory => 'Yoklama geçmişini gör';

  @override
  String get classTabStudents => 'Öğrenciler';

  @override
  String get classTabHomework => 'Ödevler';

  @override
  String get classTabQuizzes => 'Sınavlar';

  @override
  String get classTabReading => 'Okuma';

  @override
  String get classAddStudents => 'Öğrenci Ekle';

  @override
  String get classRemoveFromClass => 'Sınıftan çıkar';

  @override
  String classCouldNotRemove(String error) {
    return 'Çıkarılamadı: $error';
  }

  @override
  String classCouldNotAdd(String error) {
    return 'Eklenemedi: $error';
  }

  @override
  String get classEmptyRosterTitle => 'Bu sınıfta henüz öğrenci yok';

  @override
  String get classEmptyRosterSubtitle =>
      'Listeyi oluşturmak için “Öğrenci Ekle”ye dokunun.';

  @override
  String get classAddStudentsSheetTitle => 'Öğrenci ekle';

  @override
  String get classAllStudentsEnrolled => 'Tüm öğrencileriniz zaten bu sınıfta.';

  @override
  String classStudentAdded(String name) {
    return '$name eklendi';
  }

  @override
  String classStudentNumber(String number) {
    return 'No. $number';
  }

  @override
  String get classesTitle => 'Sınıflar';

  @override
  String get classesNewTitle => 'Yeni Sınıf';

  @override
  String get classesRenameTitle => 'Sınıfı Yeniden Adlandır';

  @override
  String get classesNameLabel => 'Sınıf adı';

  @override
  String get classesRename => 'Yeniden adlandır';

  @override
  String get classesDeleteTitle => 'Sınıf silinsin mi?';

  @override
  String classesDeleteBody(String name) {
    return '\"$name\" kaldırılsın mı? Öğrenciler kalır, yalnızca sınıf ve kayıtları silinir.';
  }

  @override
  String classesStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öğrenci',
      one: '1 öğrenci',
    );
    return '$_temp0';
  }

  @override
  String classesCouldNotCreate(String error) {
    return 'Sınıf oluşturulamadı: $error';
  }

  @override
  String classesCouldNotRename(String error) {
    return 'Sınıf yeniden adlandırılamadı: $error';
  }

  @override
  String classesCouldNotDelete(String error) {
    return 'Sınıf silinemedi: $error';
  }

  @override
  String get classesEmptyTitle => 'Henüz sınıf yok';

  @override
  String get classesEmptySubtitle =>
      'Bir tane oluşturmak için “Yeni Sınıf”a dokunun.';

  @override
  String feedShareSubject(String name) {
    return '$name bir gönderi paylaştı';
  }

  @override
  String feedQuizAssigned(String title, String className) {
    return '\"$title\", $className sınıfına atandı';
  }

  @override
  String feedCouldNotAssign(String error) {
    return 'Atanamadı: $error';
  }

  @override
  String get feedPinToProfile => 'Profile sabitle';

  @override
  String get feedUnpinFromProfile => 'Profilden kaldır';

  @override
  String get feedDeletePostTitle => 'Gönderi silinsin mi?';

  @override
  String get feedDeletePostBody =>
      'Bu, gönderiyi herkes için akıştan kaldırır.';

  @override
  String feedCouldNotDelete(String error) {
    return 'Silinemedi: $error';
  }

  @override
  String get feedReported =>
      'Bildirildi — teşekkürler. Bir yönetici inceleyecek.';

  @override
  String feedCouldNotReport(String error) {
    return 'Bildirilemedi: $error';
  }

  @override
  String feedQuizQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soru',
      one: '1 soru',
    );
    return '$_temp0';
  }

  @override
  String get feedNotRatedYet => 'Henüz puanlanmadı';

  @override
  String get feedAssignToClass => 'Sınıfıma Ata';

  @override
  String get feedAssignWhichClass => 'Hangi sınıfa atansın?';

  @override
  String get feedNoClassesYet =>
      'Henüz sınıfınız yok. Önce bir tane oluşturun.';

  @override
  String get newPostPublished => 'Gönderi yayınlandı';

  @override
  String newPostCouldNotPublish(String error) {
    return 'Yayınlanamadı: $error';
  }

  @override
  String get newPostTextLabel => 'Bir şeyler paylaş';

  @override
  String get newPostTextHint => 'Bir alıştırma, bir ipucu, bir kaynak…';

  @override
  String get newPostTextRequired => 'Paylaşmak için bir şeyler yazın';

  @override
  String get newPostSubject => 'Konu';

  @override
  String get newPostGradeLevel => 'Sınıf düzeyi (isteğe bağlı)';

  @override
  String get newPostShareQuiz => 'Bir sınav paylaş (isteğe bağlı)';

  @override
  String get newPostAttachQuiz => 'Sınavlarımdan birini ekle';

  @override
  String get newPostQuizFallback => 'Sınav';

  @override
  String get newPostAttachments => 'Ekler';

  @override
  String get newPostAddFiles => 'Dosya ekle';

  @override
  String get newPostAttachmentsHint =>
      'Diğer öğretmenlerin indirebileceği alıştırmalar, videolar veya dosyalar.';

  @override
  String get newPostPublishing => 'Yayınlanıyor…';

  @override
  String get newPostSubmit => 'Hub\'a gönder';

  @override
  String get newPostShareWhichQuiz => 'Hangi sınav paylaşılsın?';

  @override
  String get newPostNoQuizzes => 'Henüz hiç sınav oluşturmadınız.';

  @override
  String newPostQuizSubtitle(String className, String questions) {
    return '$className · $questions';
  }

  @override
  String get reportPostTitle => 'Gönderiyi bildir';

  @override
  String get reportCommentTitle => 'Yorumu bildir';

  @override
  String get reportReasonLabel => 'Sebep';

  @override
  String get reportReasonHint => 'Bunu neden bildiriyorsunuz?';

  @override
  String get postDetailTitle => 'Gönderi';

  @override
  String get postDetailLoadError => 'Bu gönderi yüklenemedi.';

  @override
  String postDetailCouldNotRate(String error) {
    return 'Puanlanamadı: $error';
  }

  @override
  String get commentsTitle => 'Yorumlar';

  @override
  String get commentsEmpty => 'Henüz yorum yok — ilk siz olun.';

  @override
  String get commentsHint => 'Bir yorum ekle…';

  @override
  String commentsCouldNotAdd(String error) {
    return 'Yorum yapılamadı: $error';
  }

  @override
  String newQuizTitle(String className) {
    return 'Yeni Sınav · $className';
  }

  @override
  String get newQuizTitleLabel => 'Başlık';

  @override
  String get newQuizTitleHint => 'örn. Şarlot\'un Ağı — 1. Bölüm';

  @override
  String get newQuizTitleRequired => 'Başlık zorunlu';

  @override
  String get newQuizDescriptionLabel => 'Açıklama (isteğe bağlı)';

  @override
  String get newQuizCategory => 'Kategori';

  @override
  String get newQuizCategoryBook => 'Kitap';

  @override
  String get newQuizCategoryPractice => 'Alıştırma';

  @override
  String get newQuizCategoryGeneral => 'Genel';

  @override
  String get newQuizBookLabel => 'Kitap';

  @override
  String get newQuizBookHint => 'örn. Şarlot\'un Ağı';

  @override
  String get newQuizQuestions => 'Sorular';

  @override
  String get newQuizAddQuestion => 'Soru ekle';

  @override
  String get newQuizPublishing => 'Yayınlanıyor…';

  @override
  String get newQuizPublish => 'Sınıfa yayınla';

  @override
  String get newQuizPublished => 'Sınav yayınlandı';

  @override
  String newQuizCouldNotPublish(String error) {
    return 'Yayınlanamadı: $error';
  }

  @override
  String newQuizQuestionNeedsText(int number) {
    return '$number. soru metin gerektiriyor.';
  }

  @override
  String newQuizQuestionNeedsChoices(int number) {
    return '$number. soru en az iki yanıt seçeneği gerektiriyor.';
  }

  @override
  String newQuizQuestionNeedsCorrect(int number) {
    return '$number. soru için bir doğru yanıt seçilmeli.';
  }

  @override
  String newQuizQuestionLabel(int number) {
    return '$number. soru';
  }

  @override
  String get newQuizRemoveQuestion => 'Soruyu kaldır';

  @override
  String get newQuizQuestionHint => 'Soruyu girin';

  @override
  String get newQuizChooseCorrectHint =>
      'Doğru yanıtı işaretlemek için daireye dokunun';

  @override
  String get newQuizAddChoice => 'Seçenek ekle';

  @override
  String get newQuizMarkCorrect => 'Doğru olarak işaretle';

  @override
  String get newQuizChoiceHint => 'Yanıt seçeneği';

  @override
  String get newQuizRemoveChoice => 'Seçeneği kaldır';

  @override
  String get classQuizTitle => 'Sınıf Sınavları';

  @override
  String get classQuizDeleteTitle => 'Sınav silinsin mi?';

  @override
  String classQuizDeleteBody(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öğrenci',
      one: '1 öğrenci',
    );
    return '\"$title\" kaldırılsın mı? Bu, $_temp0 için sınavı temizler ve sonuçlarını siler.';
  }

  @override
  String get classQuizShareToHub => 'Hub\'a paylaş';

  @override
  String classQuizAvg(int percent) {
    return 'Ort. %$percent';
  }

  @override
  String classQuizSubmitted(int submitted, int assigned) {
    return '$submitted/$assigned gönderildi';
  }

  @override
  String get classQuizEmptyTitle => 'Henüz sınav yok';

  @override
  String get classQuizEmptySubtitle =>
      'Bu sınıfa sınav yayınlamak için “Yeni”ye dokunun.';

  @override
  String get quizAnalyticsPerQuestion => 'Soru bazında dağılım';

  @override
  String get quizAnalyticsStudents => 'Öğrenciler';

  @override
  String get quizAnalyticsParticipation => 'Katılım';

  @override
  String get quizAnalyticsAverageScore => 'Ortalama puan';

  @override
  String get quizAnalyticsNotYet => 'Henüz değil';

  @override
  String get booksTabTitle => 'Kitaplar';

  @override
  String get studentProfileTitle => 'Öğrenci Profili';

  @override
  String get studentProfileReport => 'Rapor';

  @override
  String get studentProfilePersonalInfo => 'Kişisel Bilgiler';

  @override
  String get studentProfileStudentId => 'Öğrenci No';

  @override
  String get studentProfileGrade => 'Sınıf';

  @override
  String get studentProfileFullName => 'Ad Soyad';

  @override
  String get studentProfileRecentActivity => 'Son Etkinlikler';

  @override
  String get studentProfileViewHistory => 'Tüm Geçmişi Gör';

  @override
  String get studentProfileParentContacts => 'Veli İletişim Bilgileri';

  @override
  String get studentProfileNotes => 'Notlar';

  @override
  String studentProfileNotesLoadError(String error) {
    return 'Notlar yüklenemedi: $error';
  }

  @override
  String get studentProfileNoNotes => 'Henüz not yok.';

  @override
  String get studentProfileAddNote => 'Not Ekle';

  @override
  String get studentProfileNoteContent => 'Not içeriği';

  @override
  String get studentProfileLoginAccount => 'Giriş Hesabı';

  @override
  String get studentProfileCanSignIn => 'Giriş yapabilir';

  @override
  String get studentProfileRevoke => 'İptal et';

  @override
  String get studentProfileNoLogin =>
      'Henüz giriş yok. Bu öğrencinin giriş yapıp ödevlerini görebilmesi için bir tane oluşturun.';

  @override
  String get studentProfileCreateLogin => 'Giriş oluştur';

  @override
  String get studentProfileTempPassword => 'Geçici şifre';

  @override
  String get studentProfileLoginCreated =>
      'Giriş oluşturuldu. Bilgileri paylaşın.';

  @override
  String studentProfileCouldNotCreate(String error) {
    return 'Oluşturulamadı: $error';
  }

  @override
  String get studentProfileRevokeTitle => 'Giriş iptal edilsin mi?';

  @override
  String get studentProfileRevokeBody =>
      'Öğrenci artık giriş yapamayacak. Profili ve çalışmaları korunur.';

  @override
  String studentProfileCouldNotRevoke(String error) {
    return 'İptal edilemedi: $error';
  }

  @override
  String get studentsTitle => 'Öğrenciler';

  @override
  String get studentsAdd => 'Öğrenci ekle';

  @override
  String get studentsDeleteTitle => 'Öğrenci silinsin mi?';

  @override
  String studentsDeleteBody(String name) {
    return '$name kaldırılsın mı? Bu geri alınamaz.';
  }

  @override
  String studentsDeleted(String name) {
    return '$name silindi';
  }

  @override
  String get studentsEmptyTitle => 'Henüz öğrenci yok';

  @override
  String get studentsEmptySubtitle =>
      'İlk öğrencinizi oluşturmak için “Öğrenci ekle”ye dokunun.';

  @override
  String get studentsLoadError => 'Öğrenciler yüklenemedi';

  @override
  String get readingTitle => 'Okuma Günlüğü';

  @override
  String get readingSubtitle =>
      'Öğrencilerinizin okuma maceralarını takip edin.';

  @override
  String get readingAddBook => 'Yeni Kitap Ekle';

  @override
  String get readingAddStudentsFirst => 'Önce öğrenci ekleyin';

  @override
  String get readingFinished => 'Bitti!';

  @override
  String get readingInProgress => 'Devam ediyor';

  @override
  String get readingComplete => 'Tamamlandı';

  @override
  String get readingCompleted => 'Tamamlandı';

  @override
  String get readingUpdateProgress => 'İlerlemeyi Güncelle';

  @override
  String get readingStatusReading => 'Okuyor';

  @override
  String get readingStudent => 'Öğrenci';

  @override
  String get readingBookTitle => 'Kitap Adı';

  @override
  String get readingAuthorOptional => 'Yazar (isteğe bağlı)';

  @override
  String get hwTrackerTitle => 'Ödev Takibi';

  @override
  String get hwTrackerSubtitle => 'Öğrencilerinizin ilerlemesini izleyin.';

  @override
  String get hwTrackerNewAssignment => 'Yeni Ödev';

  @override
  String get hwTrackerThisWeek => 'Bu Hafta';

  @override
  String get hwTrackerAllStudents => 'Tüm Öğrenciler';

  @override
  String get hwTrackerAssignmentChip => 'Ödev';

  @override
  String get hwTrackerCompleted => 'Tamamlandı';

  @override
  String get hwTrackerInProgress => 'Devam Ediyor';

  @override
  String get hwTrackerNoDueDate => 'Son tarih yok';

  @override
  String hwTrackerDue(String date) {
    return 'Son tarih $date';
  }

  @override
  String get hwTrackerMarkDone => 'Yapıldı işaretle';

  @override
  String get hwTrackerMarkUndone => 'Yapılmadı işaretle';

  @override
  String get hwTrackerPickDueDate => 'Son tarih seç';

  @override
  String get studentFormEditTitle => 'Öğrenciyi düzenle';

  @override
  String get studentFormDobOptional => 'Doğum tarihi (isteğe bağlı)';

  @override
  String studentFormDob(String date) {
    return 'Doğum tarihi: $date';
  }

  @override
  String get studentFormNumberOptional => 'Öğrenci numarası (isteğe bağlı)';

  @override
  String get studentFormGenderOptional => 'Cinsiyet (isteğe bağlı)';

  @override
  String get studentFormGenderFemale => 'Kız';

  @override
  String get studentFormGenderMale => 'Erkek';

  @override
  String get studentFormGenderOther => 'Diğer';

  @override
  String get studentFormGuardianNameOptional => 'Veli adı (isteğe bağlı)';

  @override
  String get studentFormGuardianPhoneOptional => 'Veli telefonu (isteğe bağlı)';

  @override
  String get studentFormNotesOptional => 'Notlar (isteğe bağlı)';

  @override
  String get booksTabEmpty => 'Henüz kitap yok';

  @override
  String get booksTabAdd => 'Kitap ekle';

  @override
  String get booksTabEdit => 'Kitabı düzenle';

  @override
  String get homeworkTabEmpty => 'Henüz ödev yok';

  @override
  String get homeworkTabAdd => 'Ödev ekle';

  @override
  String get homeworkTabDueOptional => 'Son tarih (isteğe bağlı)';

  @override
  String get notesTabEmpty => 'Henüz not yok';

  @override
  String get notesTabAdd => 'Not ekle';

  @override
  String get notesTabNoteLabel => 'Not';

  @override
  String get notesCategoryBehavior => 'Davranış';

  @override
  String get notesCategoryAcademic => 'Akademik';

  @override
  String get notesCategorySocial => 'Sosyal';

  @override
  String get notesCategoryOther => 'Diğer';

  @override
  String get infoTabTitle => 'Bilgi';

  @override
  String get infoTabStudentNumber => 'Öğrenci numarası';

  @override
  String get infoTabDob => 'Doğum tarihi';

  @override
  String infoTabAge(int age) {
    return 'yaş $age';
  }

  @override
  String get infoTabGender => 'Cinsiyet';

  @override
  String get infoTabGuardian => 'Veli';

  @override
  String get infoTabGuardianPhone => 'Veli telefonu';

  @override
  String get studentDetailEditInfo => 'Bilgileri düzenle';

  @override
  String get dashboardAssistant => 'Asistan';

  @override
  String get dashboardSearchHint => 'Öğrenci bul…';

  @override
  String get dashboardQuickAccess => 'Hızlı Erişim';

  @override
  String get dashboardNoMatch => 'Öğrenci bulunamadı';

  @override
  String get dashboardAddStudent => 'Öğrenci Ekle';
}
