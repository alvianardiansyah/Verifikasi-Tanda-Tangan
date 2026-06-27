class AppConstants {
  static const String appName = 'Signature Verification';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String defaultBaseUrl = 'http://10.0.2.2:5000';
  static const int apiTimeoutSeconds = 30;

  // App Strings
  static const String identificationTitle = 'Identifikasi Pemilik Tanda Tangan';
  static const String verificationTitle = 'Verifikasi Keaslian Tanda Tangan';

  // Error Messages
  static const String noImageSelected =
      'Pilih gambar tanda tangan terlebih dahulu';
  static const String imageTooLarge = 'Gambar terlalu besar (max 10MB)';
  static const String networkError = 'Terjadi kesalahan jaringan';
  static const String serverError = 'Terjadi kesalahan pada server';

  // Success Messages
  static const String identificationSuccess = 'Identifikasi berhasil';
  static const String verificationSuccess = 'Verifikasi berhasil';
}

class AppRoutes {
  static const String home = '/';
  static const String identification = '/identification';
  static const String verification = '/verification';
  static const String history = '/history';
  static const String settings = '/settings';
}
