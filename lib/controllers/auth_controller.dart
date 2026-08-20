import 'package:flutter/foundation.dart';
import 'package:kogalo_network/providers/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../providers/event_providers.dart';
import '../providers/fcm_providers.dart';
import '../providers/shop_providers.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  resending,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final bool isGuest;
  final String? token;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.isGuest = false,
    this.token,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool? isGuest,
    String? token,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      isGuest: isGuest ?? this.isGuest,
      token: token ?? this.token,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final UserNotifier _userNotifier;
  final Ref _ref;

  AuthController(this._authRepository, this._userNotifier, this._ref)
    : super(const AuthState(status: AuthStatus.initial));

  Future<void> checkInitialAuthStatus() async {
    if (state.status == AuthStatus.authenticated) return;

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final isGuest = prefs.getBool('is_guest') ?? false;

      if (token != null && token.isNotEmpty) {
        final success = await _userNotifier.fetchUser();

        if (success) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            isGuest: false,
            token: token,
          );
          
          // Initialize FCM on startup if already logged in!
          if (_userNotifier.state != null) {
            _initFCMAfterLogin(token, _userNotifier.state!.id);
          }
        } else {
          await _clearAuthData();
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      } else if (isGuest) {
        state = const AuthState(
          status: AuthStatus.authenticated,
          isGuest: true,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      await _clearAuthData();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final loginResponse = await _authRepository.login(email, password);

      // Save token first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', loginResponse.token);

      // ✅ Set basic user from login response immediately
      _userNotifier.setUserFromLogin(loginResponse.user);

      // ✅ Set authenticated state so token is attached to requests
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isGuest: false,
        token: loginResponse.token,
      );

      // ✅ Invalidate favoritesProvider so stale data from the previous
      //    session is cleared and new user's favorites are fetched fresh.
      _ref.invalidate(favoritesProvider);

      // ✅ NOW fetch full user profile (with stats) in background
      // Token is saved so API call will work
      _fetchUserProfileAfterLogin();

      // Initialize FCM (non-blocking)
      _initFCMAfterLogin(loginResponse.token, loginResponse.user.id);

      debugPrint('Login successful');
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      debugPrint('❌ Login error: $e');
    }
  }

  void _fetchUserProfileAfterLogin() {
    Future.microtask(() async {
      try {
        await _userNotifier.fetchUser();
        debugPrint('👤 Full profile fetched after login');
      } catch (e) {
        debugPrint('⚠️ Could not fetch full profile after login: $e');
      }
    });
  }

  void _initFCMAfterLogin(String token, int userId) {
    Future.microtask(() async {
      try {
        final fcmService = _ref.read(fcmServiceProvider);
        await fcmService.init();
        await fcmService.sendTokenToServer(
          userAuthToken: token,
          userId: userId,
        );
        debugPrint('FCM token registered');
      } catch (e) {
        debugPrint('⚠️ FCM registration error: $e');
      }
    });
  }

  /// Signup
  Future<String?> signup(SignupFormData data) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final encryptedEmail = await _authRepository.signup(data);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return encryptedEmail;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp(String encryptedEmail, String otp) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final loginResponse = await _authRepository.verifyOtp(encryptedEmail, otp);
      
      _userNotifier.setUserFromLogin(loginResponse.user);
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isGuest: false,
        token: loginResponse.token,
      );

      _initFCMAfterLogin(loginResponse.token, loginResponse.user.id);
      _fetchUserProfileAfterLogin();

      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Resend OTP
  Future<bool> resendOtp(String encryptedEmail) async {
    try {
      await _authRepository.resendRegisterOtp(encryptedEmail);
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Skip login (guest mode)
  Future<void> skipLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', true);
    state = const AuthState(status: AuthStatus.authenticated, isGuest: true);
  }

  /// Reset error state
  void resetError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    // Call API + clear token in SharedPreferences (inside repository)
    try {
      await _authRepository.logout();
    } catch (_) {}

    // Clear the Dio interceptor's cached prefs so it re-reads on next request
    _ref.read(apiClientProvider).clearCache();

    await _clearAuthData();
    _userNotifier.clearUser();

    // ✅ Invalidate ALL user-specific cached providers so account 2
    //    never sees stale data from account 1 after switching users.
    _ref.invalidate(membershipDetailsProvider);
    _ref.invalidate(shopCartProvider);
    _ref.invalidate(shopFavoritesProvider);
    _ref.invalidate(shopOrdersProvider);
    _ref.invalidate(favoritesProvider); // event favorites

    state = const AuthState(status: AuthStatus.unauthenticated);
    debugPrint('Logged out');
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('is_guest');
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final userNotifier = ref.read(userProvider.notifier);
    return AuthController(authRepository, userNotifier, ref);
  },
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.status == AuthStatus.authenticated;
});

final isGuestProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isGuest;
});
