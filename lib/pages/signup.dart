import 'package:eventsbooking/pages/main_shell.dart';
import 'package:eventsbooking/pages/login.dart';
import 'package:eventsbooking/pages/otp.dart';
import 'package:eventsbooking/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';

final firstNameControllerProvider = Provider.autoDispose<TextEditingController>(
  (ref) {
    final c = TextEditingController();
    ref.onDispose(c.dispose);
    return c;
  },
);

final lastNameControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

final signupEmailControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final c = TextEditingController();
      ref.onDispose(c.dispose);
      return c;
    });
final phoneControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});
final signupPasswordControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final c = TextEditingController();
      ref.onDispose(c.dispose);
      return c;
    });
final confirmPasswordControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final c = TextEditingController();
      ref.onDispose(c.dispose);
      return c;
    });

final firstNameValidatorProvider =
    Provider.autoDispose<String? Function(String?)>(
      (ref) =>
          (v) => v!.isEmpty ? 'Please enter your first name' : null,
    );
final lastNameValidatorProvider =
    Provider.autoDispose<String? Function(String?)>(
      (ref) =>
          (v) => v!.isEmpty ? 'Please enter your last name' : null,
    );
final emailValidatorProvider = Provider.autoDispose<String? Function(String?)>((
  ref,
) {
  return (value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    const emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    if (!RegExp(emailRegex).hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  };
});
final passwordValidatorProvider =
    Provider.autoDispose<String? Function(String?)>((ref) {
      return (value) {
        if (value == null || value.isEmpty) return 'Please enter your password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      };
    });
final phoneValidatorProvider = Provider.autoDispose<String? Function(String?)>((
  ref,
) {
  return (value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    const phoneRegex = r'^[0-9]{10}$';
    if (!RegExp(phoneRegex).hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  };
});

final confirmPasswordValidatorProvider =
    Provider.autoDispose<String? Function(String?)>((ref) {
      final passwordController = ref.watch(signupPasswordControllerProvider);
      return (value) {
        if (value != passwordController.text) {
          return 'Passwords do not match';
        }
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        return null;
      };
    });

final passwordVisibilityProvider = StateProvider.autoDispose<bool>(
  (ref) => true,
);
final confirmPasswordVisibilityProvider = StateProvider.autoDispose<bool>(
  (ref) => true,
);

class Signup extends ConsumerStatefulWidget {
  const Signup({super.key});
  @override
  ConsumerState<Signup> createState() => _SignupState();
}

class _SignupState extends ConsumerState<Signup> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _buttonController;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error) {
        showErrorSnackBar(next.errorMessage ?? 'An error occurred');
      }
    });
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            backgroundDecoration(),
            mainContent(isLoading),
            skipButton(),
          ],
        ),
      ),
    );
  }

  Future<void> handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = ref.read(signupEmailControllerProvider).text.trim();
      final phone = ref.read(phoneControllerProvider).text.trim();
      final password = ref.read(signupPasswordControllerProvider).text;

      final formData = SignupFormData(
        firstName: ref.read(firstNameControllerProvider).text.trim(),
        lastName: ref.read(lastNameControllerProvider).text.trim(),
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: password,
      );

      final encryptedEmail = await ref
          .read(authControllerProvider.notifier)
          .signup(formData);

      if (encryptedEmail != null && mounted) {
        showSuccessDialog(encryptedEmail, email, phone);
      }
    }
  }

  void showSuccessDialog(String encryptedEmail, String email, String phone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              const Text(
                'Account Created!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please verify your account with the OTP sent to your email.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  navigateToOtp(encryptedEmail, email, phone);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Verify Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void navigateToOtp(String encryptedEmail, String email, String phone) {
    Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => OtpVerification(
        encryptedEmail: encryptedEmail,
        email: email,
        phone: phone,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
          child: child,
        );
      },
    ),
  );
}

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    ref.read(authControllerProvider.notifier).resetError();
  }

  Widget backgroundDecoration() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 200,
              color: AppTheme.primaryPink.withValues(alpha: 0.15),
            ),
          ),
        ).animate().scale(duration: 1000.ms, curve: Curves.easeOut),
        Positioned(
          bottom: -50,
          left: -50,
          child: SizedBox(
            width: 150,
            height: 150,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 150,
              color: AppTheme.primaryPink.withValues(alpha: 0.10),
            ),
          ),
        ).animate().scale(duration: 1200.ms, curve: Curves.easeOut),
      ],
    );
  }

  Widget skipButton() {
    return Positioned(
      top: 20,
      right: 20,
      child: TextButton(
        onPressed: () {
          Navigator.pop(context);
          ref.read(authControllerProvider.notifier).skipLogin();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
            (route) => false,
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: TextStyle(
                color: AppTheme.textDark.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppTheme.textDark.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideX(begin: 0.2);
  }

  Widget mainContent(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          logo(),
          const SizedBox(height: 30),
          header(),
          const SizedBox(height: 40),
          form(),
          const SizedBox(height: 30),
          submitButton(isLoading),
          const SizedBox(height: 30),
          signInLink(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget logo() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Image.asset(
        'assets/images/Gor-Mahia-FC-logo.png',
        fit: BoxFit.contain,
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut).fadeIn();
  }

  Widget header() {
    return Column(
      children: [
        const Text(
          'Create Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
        const SizedBox(height: 8),
        const Text(
          'Join us to discover amazing events',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppTheme.textLight),
        ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
      ],
    );
  }

  Widget form() {
    final firstNameController = ref.watch(firstNameControllerProvider);
    final lastNameController = ref.watch(lastNameControllerProvider);
    final emailController = ref.watch(signupEmailControllerProvider);
    final phoneController = ref.watch(phoneControllerProvider);
    final passwordController = ref.watch(signupPasswordControllerProvider);
    final confirmPasswordController = ref.watch(
      confirmPasswordControllerProvider,
    );

    final firstNameValidator = ref.watch(firstNameValidatorProvider);
    final lastNameValidator = ref.watch(lastNameValidatorProvider);
    final emailValidator = ref.watch(emailValidatorProvider);
    final phoneValidator = ref.watch(phoneValidatorProvider);
    final passwordValidator = ref.watch(passwordValidatorProvider);
    final confirmPasswordValidator = ref.watch(
      confirmPasswordValidatorProvider,
    );

    final obscurePassword = ref.watch(passwordVisibilityProvider);
    final obscureConfirmPassword = ref.watch(confirmPasswordVisibilityProvider);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          textField(
            controller: firstNameController,
            label: 'First Name',
            icon: Icons.person_outline,
            validator: firstNameValidator,
            delay: 2,
          ),
          const SizedBox(height: 16),
          textField(
            controller: lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline,
            validator: lastNameValidator,
            delay: 3,
          ),
          const SizedBox(height: 16),
          textField(
            controller: emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator,
            delay: 4,
          ),
          const SizedBox(height: 16),
          textField(
            controller: phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            prefixText: '+91 ',
            validator: phoneValidator,
            delay: 5,
          ),
          const SizedBox(height: 16),
          textField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            validator: passwordValidator,
            delay: 6,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textLight,
              ),
              onPressed: () =>
                  ref.read(passwordVisibilityProvider.notifier).state =
                      !obscurePassword,
            ),
          ),
          const SizedBox(height: 16),
          textField(
            controller: confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline_rounded,
            obscureText: obscureConfirmPassword,
            validator: confirmPasswordValidator,
            delay: 7,
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppTheme.textLight,
              ),
              onPressed: () =>
                  ref.read(confirmPasswordVisibilityProvider.notifier).state =
                      !obscureConfirmPassword,
            ),
          ),
        ],
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    required int delay,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(color: AppTheme.textDark, fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: AppTheme.textLight),
              prefixIcon: Icon(icon, color: AppTheme.primaryPink),
              prefixText: prefixText,
              prefixStyle: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 16,
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              errorStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            validator: validator,
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: (delay * 100).ms)
        .slideY(begin: 0.1);
  }

  Widget submitButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              _buttonController.forward().then(
                (_) => _buttonController.reverse(),
              );
              handleSubmit();
            },
      child: AnimatedBuilder(
        animation: _buttonController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_buttonController.value * 0.05),
            child: child,
          );
        },
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPink.withValues(alpha: 0.3),
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
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 800.ms).slideY(begin: 0.2);
  }

  Widget signInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: AppTheme.textLight),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: AppTheme.primaryPink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 800.ms);
  }
}
