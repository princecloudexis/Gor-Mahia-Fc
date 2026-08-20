/// 🔧 ENVIRONMENT SWITCH — Change this ONE constant to switch between environments.
/// 
/// For STAGING (testing with users):   AppEnvironment.staging
/// For PRODUCTION (live users):        AppEnvironment.production
///
/// After changing this, run:
///   flutter clean
///   flutter build appbundle --release
/// Then upload the new AAB to Google Play Console.

enum AppEnvironment { staging, production }

class AppConfig {
  // ══════════════════════════════════════════════════════════
  // 👇 CHANGE THIS ONE LINE TO SWITCH ENVIRONMENTS
  static const AppEnvironment _env = AppEnvironment.staging;
  // ══════════════════════════════════════════════════════════

  static String get baseApiUrl {
    switch (_env) {
      case AppEnvironment.staging:
        return 'https://footballclub.staging-workhub.com/api';
      case AppEnvironment.production:
        return 'https://YOUR-LIVE-DOMAIN.com/api'; // ← backend dev fills this in
    }
  }

  static String get storageBaseUrl {
    switch (_env) {
      case AppEnvironment.staging:
        return 'https://footballclub.staging-workhub.com/';
      case AppEnvironment.production:
        return 'https://YOUR-LIVE-DOMAIN.com/'; // ← backend dev fills this in
    }
  }

  static String get wsHost {
    switch (_env) {
      case AppEnvironment.staging:
        return 'footballclub.staging-workhub.com';
      case AppEnvironment.production:
        return 'YOUR-LIVE-DOMAIN.com'; // ← backend dev fills this in
    }
  }

  static bool get isStaging => _env == AppEnvironment.staging;
  static bool get isProduction => _env == AppEnvironment.production;
}
