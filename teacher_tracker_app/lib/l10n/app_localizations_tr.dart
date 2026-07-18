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
}
