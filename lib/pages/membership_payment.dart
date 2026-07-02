import 'package:eventsbooking/controllers/payment_controller.dart';
import 'package:eventsbooking/pages/main_shell.dart';
import 'package:eventsbooking/pages/payment_success.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MembershipPayment extends ConsumerStatefulWidget {
  final String title;
  final String price;
  final String rawAmount;
  final String period;
  final String membershipId;

  const MembershipPayment({
    super.key,
    required this.title,
    required this.price,
    required this.rawAmount,
    required this.period,
    required this.membershipId,
  });

  @override
  ConsumerState<MembershipPayment> createState() => _MembershipPaymentState();
}

class _MembershipPaymentState extends ConsumerState<MembershipPayment> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentControllerProvider, (previous, next) {
      if (previous?.status == PaymentStatus.waitingForMpesa && next.status != PaymentStatus.waitingForMpesa) {
        // Close the dialog if it was open
        if (Navigator.of(context, rootNavigator: true).canPop()) {
           Navigator.of(context, rootNavigator: true).pop();
        }
      }

      if (next.status == PaymentStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(paymentControllerProvider.notifier).resetStatus();
      } else if (next.status == PaymentStatus.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentSuccess(title: widget.title)),
        );
      }
    });

    final isInitiating = ref.watch(paymentControllerProvider).status == PaymentStatus.initiating;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('ORDER SUMMARY'),
              const SizedBox(height: 12),
              _buildOrderSummary(),
              const SizedBox(height: 32),
              _buildSectionTitle('PAYMENT METHOD'),
              const SizedBox(height: 12),
              _buildPaymentMethod(),
              const SizedBox(height: 32),
              _buildSectionTitle('M-PESA DETAILS'),
              const SizedBox(height: 12),
              _buildMpesaForm(),
              const SizedBox(height: 48),
              _buildPayButton(isInitiating),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildOrderSummary() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/Gor-Mahia-FC-logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.period,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                widget.price,
                style: const TextStyle(
                  color: AppColors.greenLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildPaymentMethod() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.phone_android,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'M-PESA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pay securely via M-PESA STK Push',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 24),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildMpesaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'M-PESA Phone Number',
                style: TextStyle(
                  color: AppColors.textSecondaryDark.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'e.g. 254700000000',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Instructions: Enter your M-PESA phone number above and tap Pay. A prompt will be sent to your phone. Enter your M-PESA PIN to complete the transaction.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildPayButton(bool isInitiating) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isInitiating
            ? null
            : () {
                final phone = _phoneController.text.trim();
                if (phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your phone number')),
                  );
                  return;
                }

                // Show the dialog immediately, the controller will pop it when status changes
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Dialog(
                    backgroundColor: AppColors.bgSurfaceDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Waiting for M-PESA...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please check your phone',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                ref.read(paymentControllerProvider.notifier).initiatePayment(
                      phone: phone,
                      membershipId: widget.membershipId,
                      amount: widget.rawAmount,
                      packageName: widget.title,
                    );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isInitiating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'INITIATE PAYMENT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }
}
