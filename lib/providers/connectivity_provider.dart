import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStreamProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((event) => event.first);
});

class ConnectivityNotifier extends StateNotifier<AsyncValue<ConnectivityResult>> {
  ConnectivityNotifier() : super(const AsyncValue.loading()) {
    checkConnection();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      state = AsyncValue.data(result.first);
    });
  }

  Future<void> checkConnection() async {
    state = const AsyncValue.loading();
    try {
      final result = await Connectivity().checkConnectivity();
      state = AsyncValue.data(result.first);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final connectivityControllerProvider =
    StateNotifierProvider<ConnectivityNotifier, AsyncValue<ConnectivityResult>>(
  (ref) => ConnectivityNotifier(),
);