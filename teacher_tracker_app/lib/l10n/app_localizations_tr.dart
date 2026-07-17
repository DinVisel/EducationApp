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
}
