import 'dart:async';

import 'package:kogalo_network/controllers/auth_controller.dart';
import 'package:kogalo_network/pages/home.dart';
import 'package:kogalo_network/pages/login.dart';
import 'package:kogalo_network/providers/splash_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashNavigationController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() async {
    await performInitialization();
  }
  Future<void> performInitialization() async {
    final authCheckFuture =
        ref.read(authControllerProvider.notifier).checkInitialAuthStatus();
    final splashDurationFuture = Future.delayed(const Duration(seconds: 3));
    await Future.wait([authCheckFuture, splashDurationFuture]);
    final authState = ref.read(authControllerProvider);

    if (authState.status == AuthStatus.authenticated) {
      _navigateToHome();
    } else {
      _navigateToLogin();
    }
  }

  void _navigate(Widget screen) {
    final context = ref.read(navigatorKeyProvider).currentContext;

    if (context != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => screen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }
  void _navigateToLogin() {
    _navigate(const Login());
  }

  void _navigateToHome() {
    _navigate(const Home());
  }
}

final splashNavigationProvider =
    AsyncNotifierProvider.autoDispose<SplashNavigationController, void>(
  SplashNavigationController.new,
);