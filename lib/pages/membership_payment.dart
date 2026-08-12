import 'package:gormahiafc/pages/main_shell.dart';
import 'package:gormahiafc/pages/payment_success.dart';
import 'package:gormahiafc/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gormahiafc/providers/user_providers.dart';
import 'package:gormahiafc/repositories/membership_repository.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _MembershipPaymentState extends ConsumerState<MembershipPayment> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isInitiating = false;
  bool _paymentLaunched = false;
  bool _isCheckingStatus = false;
  String? _currentPaymentReference;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _paymentLaunched && !_isCheckingStatus) {
      _verifyPaymentStatus();
    }
  }

  Future<void> _verifyPaymentStatus() async {
    setState(() {
      _isCheckingStatus = true;
      _paymentLaunched = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryGreen),
              SizedBox(height: 16),
              Text('Verifying payment status...'),
            ],
          ),
        );
      },
    );

    // Give backend a moment to process the webhook if any
    await Future.delayed(const Duration(seconds: 2));

    if (_currentPaymentReference != null) {
      try {
        final repo = ref.read(membershipRepositoryProvider);
        await repo.checkPaymentStatus(
          reference: _currentPaymentReference!,
          membershipId: widget.membershipId,
          plan: widget.title,
        );
      } catch (e) {
        debugPrint('Error checking payment status: $e');
      }
    }

    await ref.read(userProvider.notifier).fetchUser();
    ref.invalidate(membershipDetailsProvider);

    if (!mounted) return;
    Navigator.pop(context); // Close dialog

    final user = ref.read(userProvider);
    final isPaid = user != null &&
                   user.membershipPlan != null &&
                   user.membershipPlan!.toLowerCase() != 'free plan' &&
                   user.membershipPlan!.toLowerCase() != 'none';

    if (isPaid) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => PaymentSuccess(title: widget.title)),
        (route) => false,
      );
    } else {
      setState(() {
        _isCheckingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment not completed or still processing.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }


  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isInitiating = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryGreen),
              SizedBox(height: 16),
              Text('Initiating Paystack checkout...'),
            ],
          ),
        );
      },
    );

    try {
      final repo = ref.read(membershipRepositoryProvider);
      final response = await repo.initiatePayment(
        email: _emailController.text.trim(),
        membershipId: widget.membershipId,
        amount: widget.rawAmount,
        packageName: widget.title,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close dialog

      _currentPaymentReference = response.reference;

      final Uri url = Uri.parse(response.authorizationUrl);
      if (await canLaunchUrl(url)) {
        _paymentLaunched = true;
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch payment page.');
      }

      // We no longer navigate away immediately.
      // The didChangeAppLifecycleState will handle verification when the browser is closed.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the payment securely in your browser.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isInitiating = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
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
                _buildSectionTitle('PAYSTACK DETAILS'),
                const SizedBox(height: 12),
                _buildPaystackForm(),
                const SizedBox(height: 48),
                _buildPayButton(_isInitiating),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildOrderSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurfaceDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade300,
        ),
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
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.period,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.price,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black54,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurfaceDark : Colors.grey.shade100,
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
              Icons.credit_card,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAYSTACK',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pay securely via Card, Mobile Money or USSD',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.primaryGreen,
            size: 24,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildPaystackForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSurfaceDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email Address',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark.withOpacity(0.7)
                      : Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter your email';
                  if (!val.contains('@')) return 'Please enter a valid email';
                  return null;
                },
                decoration: InputDecoration(
                  filled: false,
                  hintText: 'e.g. jimjacksports@gmail.com',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black26,
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
                  'Instructions: Enter your email address and tap Pay. You will be redirected to the secure Paystack portal to complete the transaction.',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black87,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isInitiating
            ? null
            : () => _processPayment(),
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
