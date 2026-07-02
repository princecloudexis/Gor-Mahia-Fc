import 'package:eventsbooking/pages/splashscreen.dart';
import 'package:eventsbooking/providers/theme_provider.dart';
import 'package:eventsbooking/theme/apptheme.dart';
import 'package:eventsbooking/widgets/connectivity_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:eventsbooking/services/fcm_service.dart';
import 'package:eventsbooking/firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  const bootstrapStripeKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  if (bootstrapStripeKey.isNotEmpty) {
    // Stripe.publishableKey = bootstrapStripeKey;
    // await Stripe.instance.applySettings();
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeOption = ref.watch(themeProvider);
    final themeMode = switch (themeModeOption) {
      ThemeModeOption.light => ThemeMode.light,
      ThemeModeOption.dark => ThemeMode.dark,
      ThemeModeOption.system => ThemeMode.system,
    };

    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'KogaloTix',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        return ConnectivityWrapper(child: child!);
      },
      home: const SplashScreen(),
    );
  }
}
