import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:eventsbooking/providers/shop_providers.dart';
import 'dart:async';
import 'package:eventsbooking/pages/shop_order_success.dart';

class ShopPaymentProcessingPage extends ConsumerStatefulWidget {
  final String reference;
  final String orderNumber;

  const ShopPaymentProcessingPage({
    super.key,
    required this.reference,
    required this.orderNumber,
  });

  @override
  ConsumerState<ShopPaymentProcessingPage> createState() => _ShopPaymentProcessingPageState();
}

class _ShopPaymentProcessingPageState extends ConsumerState<ShopPaymentProcessingPage> {
  Timer? _timer;
  int _secondsPassed = 0;
  final int _maxTimeout = 300; // 5 minutes timeout for card entry
  bool _isFinished = false;
  String _statusMessage = 'Waiting for Paystack confirmation...';

  @override
  void initState() {
    super.initState();
    // Give the backend 4 seconds to process Paystack's webhook before first poll
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _startPolling();
    });
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsPassed += 3;
      });

      if (_secondsPassed >= _maxTimeout) {
        _handleTimeout();
        return;
      }

      try {
        final repository = ref.read(shopRepositoryProvider);
        final statusResponse = await repository.checkPaystackStatus(widget.reference);

        // Debug log to trace what API returns
        debugPrint('🛒 [ShopPaystack] Poll result → payment="${statusResponse.payment}", message="${statusResponse.message}"');

        if (statusResponse.payment == 'success' || statusResponse.payment.toLowerCase() == 'paid') {
          _handleSuccess();
        } else if (statusResponse.payment == 'failed') {
          _handleFailure(statusResponse.message.isNotEmpty
              ? statusResponse.message
              : 'Payment was cancelled or failed. Please try again.');
        } else {
          // Still pending — update message
          if (mounted) {
            setState(() {
              _statusMessage = statusResponse.message.isNotEmpty
                  ? statusResponse.message
                  : 'Still waiting for Paystack...';
            });
          }
        }
      } catch (e) {
        // Silently ignore network errors while polling so it keeps trying
        debugPrint('🛒 [ShopPaystack] Polling error: $e');
      }
    });
  }

  void _handleSuccess() {
    if (_isFinished) return;
    _isFinished = true;
    _timer?.cancel();
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ShopOrderSuccessPage(orderNumber: widget.orderNumber),
        ),
      );
    }
  }

  void _handleFailure(String message) {
    if (_isFinished) return;
    _isFinished = true;
    _timer?.cancel();
    
    if (mounted) {
      _showErrorDialog('Payment Failed', message);
    }
  }

  void _handleTimeout() {
    if (_isFinished) return;
    _isFinished = true;
    _timer?.cancel();
    
    if (mounted) {
      _showErrorDialog('Timeout', 'We did not receive a payment confirmation in time. If you were deducted, please contact support.');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to Checkout/Cart
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                      strokeWidth: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                  const Text(
                    'Processing Payment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Order # ${widget.orderNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please do not close this screen while we verify your payment with Paystack.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                const SizedBox(height: 40),
                LinearProgressIndicator(
                  value: _secondsPassed / _maxTimeout,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: 16),
                Text(
                  '${_maxTimeout - _secondsPassed} seconds remaining...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
