import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kogalo_network/services/fcm_service.dart';

/// Callback type that payment pages register so the deep link service
/// can notify them when Paystack redirects back with a reference.
typedef PaymentDeepLinkCallback = void Function(
    String reference, String type);

/// Singleton service that listens for Paystack deep-link callbacks.
///
/// Flow:
///   Paystack payment success
///   → Paystack redirects to `kogalonetwork://payment/callback?reference=xxx&type=yyy`
///   → Browser closes automatically
///   → OS re-opens the app via the custom URL scheme
///   → [PaymentDeepLinkService] fires the registered [PaymentDeepLinkCallback]
///   → The active payment page verifies & navigates to the success screen
class PaymentDeepLinkService {
  PaymentDeepLinkService._();
  static final PaymentDeepLinkService instance = PaymentDeepLinkService._();

  StreamSubscription<Uri>? _sub;
  PaymentDeepLinkCallback? _callback;

  /// Call once from [main.dart] after [runApp].
  void init() {
    final appLinks = AppLinks();

    // Handle links that arrive while the app is already running.
    _sub = appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 [DeepLink] Received: $uri');
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint('🔗 [DeepLink] Error: $err');
      },
    );

    // Handle the initial link that launched the app (cold start).
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        debugPrint('🔗 [DeepLink] Initial link: $uri');
        _handleUri(uri);
      }
    });
  }

  /// Register a callback from a payment page.
  /// Only one callback is active at a time (the currently visible payment page).
  void registerCallback(PaymentDeepLinkCallback cb) {
    _callback = cb;
    debugPrint('🔗 [DeepLink] Callback registered');
  }

  /// Unregister when the payment page is disposed.
  void unregisterCallback() {
    _callback = null;
    debugPrint('🔗 [DeepLink] Callback unregistered');
  }

  void _handleUri(Uri uri) {
    // Expected: kogalonetwork://payment/callback?reference=xxx&type=yyy
    if (uri.scheme != 'kogalonetwork') return;
    if (uri.host != 'payment') return;
    if (uri.path != '/callback') return;

    final reference = uri.queryParameters['reference'];
    final type = uri.queryParameters['type'] ?? 'unknown';

    if (reference == null || reference.isEmpty) {
      debugPrint('🔗 [DeepLink] No reference in callback URL');
      return;
    }

    debugPrint('🔗 [DeepLink] Payment callback → reference=$reference, type=$type');

    if (_callback != null) {
      _callback!(reference, type);
    } else {
      // No page registered — the app may have been cold-started by the deep link.
      // Navigate using the global navigator key.
      _navigateFallback(reference, type);
    }
  }

  void _navigateFallback(String reference, String type) {
    debugPrint('🔗 [DeepLink] Fallback navigation for reference=$reference type=$type');
    // The active payment page will pick this up via the callback once mounted.
    // Store it so the page can retrieve it on init.
    _pendingReference = reference;
    _pendingType = type;

    // Attempt navigation via navigatorKey if context is available
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      _callback?.call(reference, type);
    }
  }

  /// Pending callback data for cold-start deep links.
  String? _pendingReference;
  String? _pendingType;

  /// Payment pages call this in [initState] to consume any pending deep link.
  ({String reference, String type})? consumePending() {
    if (_pendingReference != null) {
      final result = (reference: _pendingReference!, type: _pendingType ?? 'unknown');
      _pendingReference = null;
      _pendingType = null;
      debugPrint('🔗 [DeepLink] Consumed pending: $result');
      return result;
    }
    return null;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _callback = null;
  }
}
