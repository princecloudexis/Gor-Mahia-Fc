
import 'package:gormahiafc/pages/splashscreen.dart';
import 'package:gormahiafc/providers/connectivity_provider.dart';
import 'package:gormahiafc/widgets/no_connection_widget.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityControllerProvider);

    return connectivityState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => const Scaffold(
        body: Center(child: Text('Error checking connection')),
      ),
      data: (result) {
        if (result == ConnectivityResult.none) {
          if (child is SplashScreen) {
            return Stack(
              children: [
                child,
                const NoConnectionSplashBar(),
              ],
            );
          } else {
            return const NoConnectionFullScreen();
          }
        }
        return child;
      },
    );
  }
}