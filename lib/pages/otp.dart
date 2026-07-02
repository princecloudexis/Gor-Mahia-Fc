import 'dart:async';
import 'package:eventsbooking/pages/login.dart';
import 'package:eventsbooking/pages/membership_signup.dart';
import 'package:eventsbooking/providers/fcm_providers.dart';
import 'package:eventsbooking/theme/apptheme.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:eventsbooking/widgets/breadcrumb_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

final _timerProvider = StateProvider.autoDispose<int>((ref) => 60);

class OtpVerification extends ConsumerStatefulWidget {
  final String encryptedEmail;
  final String email;
  final String phone;

  const OtpVerification({
    super.key,
    required this.encryptedEmail,
    required this.email,
    required this.phone,
  });

  @override
  ConsumerState<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends ConsumerState<OtpVerification> {
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes.first.requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentTimer = ref.read(_timerProvider);
      if (currentTimer > 0) {
        ref.read(_timerProvider.notifier).state = currentTimer - 1;
      } else {
        _timer?.cancel();
      }
    });
  }

  void _resetTimer() {
    ref.read(_timerProvider.notifier).state = 60;
    _startTimer();
  }

  Future<void> _handleVerify() async {
    FocusScope.of(context).unfocus();
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length == 4) {
      final success = await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(widget.encryptedEmail, otp);
      if (success && mounted) {
        _showSuccessDialog();
      }
    } else {
      _showErrorSnackBar('Please enter the complete 4-digit OTP');
    }
  }

  Future<void> _handleResend() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .resendOtp(widget.encryptedEmail);
    if (success && mounted) {
      _resetTimer();
      _showSuccessSnackBar('A new OTP has been sent to your email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (ModalRoute.of(context)?.isCurrent != true) return;
      if (next.status == AuthStatus.error) {
        _showErrorSnackBar(next.errorMessage ?? 'An unknown error occurred');
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

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
          'OTP Verification',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const BreadcrumbTabBar(activeStep: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _AppHeader(email: widget.email),
                    const SizedBox(height: 40),
                    _OtpInputFields(
                      controllers: _otpControllers,
                      focusNodes: _focusNodes,
                      onCompleted: _handleVerify,
                    ),
                    const SizedBox(height: 32),
                    _VerifyButton(isLoading: isLoading, onTap: _handleVerify),
                    const SizedBox(height: 32),
                    _ResendCodeSection(onResend: _handleResend),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _InfoDialog(
        icon: Icons.verified_user_outlined,
        gradient: AppTheme.primaryGradient,
        title: 'Verification Successful!',
        message: 'Your account is now active. Welcome!',
        buttonText: 'Continue',
        onPressed: () {
          Navigator.pop(dialogContext);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MembershipSignup(),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          )
                          .chain(CurveTween(curve: Curves.easeInOut))
                          .animate(animation),
                  child: child,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    ref.read(authControllerProvider.notifier).resetError();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final String email;
  const _AppHeader({required this.email});

  @override
  Widget build(BuildContext context) {
    final maskedEmail = email.replaceRange(3, email.indexOf('@'), '****');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Verify Your Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'Enter the 4-digit code sent to\n$maskedEmail',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
      ],
    );
  }
}

class _OtpInputFields extends StatefulWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final VoidCallback onCompleted;

  const _OtpInputFields({
    required this.controllers,
    required this.focusNodes,
    required this.onCompleted,
  });

  @override
  State<_OtpInputFields> createState() => _OtpInputFieldsState();
}

class _OtpInputFieldsState extends State<_OtpInputFields> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.bgSurfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextFormField(
            controller: widget.controllers[index],
            focusNode: widget.focusNodes[index],
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.top,
            maxLength: 1,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 24,
            ),
            decoration: InputDecoration(
              counterText: '',
              // contentPadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              border: OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < 3) {
                  widget.focusNodes[index + 1].requestFocus();
                } else {
                  FocusScope.of(context).unfocus();
                  widget.onCompleted();
                }
              } else if (value.isEmpty && index > 0) {
                widget.focusNodes[index - 1].requestFocus();
              }
            },
          ),
        ).animate().fadeIn(duration: 500.ms, delay: (400 + index * 100).ms);
      }),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _VerifyButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPink.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Verify Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 900.ms).slideY(begin: 0.2);
  }
}

class _ResendCodeSection extends ConsumerWidget {
  final VoidCallback onResend;
  const _ResendCodeSection({required this.onResend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(_timerProvider);
    final isResending =
        ref.watch(authControllerProvider).status == AuthStatus.resending;

    return Column(
      children: [
        if (isResending)
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(),
          )
        else if (timer > 0)
          Text(
            'Resend code in $timer seconds',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the code? ",
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              TextButton(
                onPressed: onResend,
                child: const Text(
                  'Resend',
                  style: TextStyle(
                    color: AppColors.greenLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 1000.ms);
  }
}

// Removed _BackButton as we now use AppBar back button

// Removed background decorations and logo classes to maintain a sleek minimalist design.

class _InfoDialog extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _InfoDialog({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgSurfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
