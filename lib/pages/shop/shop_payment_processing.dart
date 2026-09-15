import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kogalo_network/providers/shop_providers.dart';
import 'package:kogalo_network/pages/shop/shop_order_success.dart';
import 'package:kogalo_network/widgets/universal_payment_processing_screen.dart';
import 'package:kogalo_network/theme/app_colors.dart';

class ShopPaymentProcessingPage extends ConsumerWidget {
  final String reference;
  final String orderNumber;

  const ShopPaymentProcessingPage({
    super.key,
    required this.reference,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UniversalPaymentProcessingScreen(
      title: 'Processing Order',
      reference: reference,
      verifyStatus: () async {
        final repository = ref.read(shopRepositoryProvider);
        final statusResponse =
            await repository.checkPaystackStatus(reference);
        debugPrint(
          '🛒 [ShopPaystack] Poll → payment="${statusResponse.payment}"',
        );
        if (statusResponse.payment == 'success' ||
            statusResponse.payment.toLowerCase() == 'paid') {
          return true;
        }
        if (statusResponse.payment == 'failed') {
          throw Exception(
            statusResponse.message.isNotEmpty
                ? statusResponse.message
                : 'Payment was cancelled or failed. Please try again.',
          );
        }
        return false;
      },
      onSuccess: () {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ShopOrderSuccessPage(orderNumber: orderNumber),
            ),
          );
        }
      },
      onFailure: (message) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text('Payment Issue'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // go back to cart/checkout
                  },
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
