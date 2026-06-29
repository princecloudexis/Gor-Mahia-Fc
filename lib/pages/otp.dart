import 'dart:async';
import 'package:eventsbooking/pages/login.dart';
import 'package:eventsbooking/providers/fcm_providers.dart';
import 'package:eventsbooking/theme/apptheme.dart';
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
      if (next.status == AuthStatus.error) {
        _showErrorSnackBar(next.errorMessage ?? 'An unknown error occurred');
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          const _BackgroundDecorations(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
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
          const _BackButton(),
        ],
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
        buttonText: 'Continue to Login',
        onPressed: () {
          Navigator.pop(dialogContext);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
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
    final theme = Theme.of(context);
    final maskedEmail = email.replaceRange(3, email.indexOf('@'), '****');

    return Column(
      children: [
        const _AppLogo(),
        const SizedBox(height: 24),
        Text(
          'Verify Your Account',
          style: theme.textTheme.displaySmall,
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'Enter the 4-digit code sent to\n$maskedEmail',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controllers[index],
            focusNode: widget.focusNodes[index],
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.top,
            maxLength: 1,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
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
                style: TextStyle(color: AppTheme.textLight),
              ),
              TextButton(
                onPressed: onResend,
                child: const Text(
                  'Resend',
                  style: TextStyle(
                    color: AppTheme.primaryPink,
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

class _BackButton extends StatelessWidget {
  const _BackButton();
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 46,
      left: 16,
      child: IconButton.filledTonal(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_sharp, color: Colors.white),
        style: IconButton.styleFrom(backgroundColor: const Color(0xFFEC398B)),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: _BackgroundCircle(
            size: 200,
            gradient: AppTheme.primaryGradient.scale(0.5),
          ),
        ).animate().scale(duration: 1000.ms, curve: Curves.easeOut),
        Positioned(
          bottom: -50,
          left: -50,
          child: _BackgroundCircle(
            size: 150,
            gradient: AppTheme.primaryGradient.scale(0.5),
          ),
        ).animate().scale(duration: 1200.ms, curve: Curves.easeOut),
      ],
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final Gradient gradient;
  const _BackgroundCircle({required this.size, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.sports_soccer_rounded,
        size: size,
        color: AppTheme.primaryPink.withValues(alpha: 0.15),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.mark_email_read_outlined,
        size: 60,
        color: Colors.white,
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut).fadeIn();
  }
}

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
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
