import 'package:eventsbooking/pages/login.dart';
import 'package:eventsbooking/pages/otp.dart';
import 'package:eventsbooking/theme/apptheme.dart';
import 'package:eventsbooking/theme/app_colors.dart';
import 'package:eventsbooking/widgets/breadcrumb_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';

final firstNameControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  final c = TextEditingController();
  ref.onDispose(c.dispose);
  return c;
});

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

final nationalIdControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
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
final nationalIdValidatorProvider =
    Provider.autoDispose<String? Function(String?)>(
      (ref) =>
          (v) => v!.isEmpty ? 'Please enter your National ID / Passport' : null,
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
      if (ModalRoute.of(context)?.isCurrent != true) return;
      if (next.status == AuthStatus.error) {
        showErrorSnackBar(next.errorMessage ?? 'An error occurred');
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.bgDark, // Deep dark background from reference
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
          'Registration',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const BreadcrumbTabBar(activeStep: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERSONAL INFORMATION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 20),
                    form(),
                    const SizedBox(height: 30),
                    submitButton(isLoading),
                    const SizedBox(height: 30),
                    signInLink(),
                  ],
                ),
              ),
            ),
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

      final firstName = ref.read(firstNameControllerProvider).text.trim();
      final lastName = ref.read(lastNameControllerProvider).text.trim();

      final nationalId = ref.read(nationalIdControllerProvider).text.trim();

      final formData = SignupFormData(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        nationalId: nationalId,
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
    navigateToOtp(encryptedEmail, email, phone);
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
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    ref.read(authControllerProvider.notifier).resetError();
  }

  Widget form() {
    final firstNameController = ref.watch(firstNameControllerProvider);
    final lastNameController = ref.watch(lastNameControllerProvider);
    final emailController = ref.watch(signupEmailControllerProvider);
    final phoneController = ref.watch(phoneControllerProvider);
    final nationalIdController = ref.watch(nationalIdControllerProvider);
    final passwordController = ref.watch(signupPasswordControllerProvider);
    final confirmPasswordController = ref.watch(
      confirmPasswordControllerProvider,
    );

    final firstNameValidator = ref.watch(firstNameValidatorProvider);
    final lastNameValidator = ref.watch(lastNameValidatorProvider);
    final emailValidator = ref.watch(emailValidatorProvider);
    final phoneValidator = ref.watch(phoneValidatorProvider);
    final nationalIdValidator = ref.watch(nationalIdValidatorProvider);
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
          _buildSleekField(
            controller: firstNameController,
            label: 'First Name',
            hint: 'John',
            validator: firstNameValidator,
            delay: 1,
          ),
          const SizedBox(height: 12),
          _buildSleekField(
            controller: lastNameController,
            label: 'Last Name',
            hint: 'Ochieng\'',
            validator: lastNameValidator,
            delay: 1,
          ),
          const SizedBox(height: 12),
          _buildSleekField(
            controller: phoneController,
            label: 'Phone Number',
            hint: '07XX XXX XXX',
            keyboardType: TextInputType.phone,
            validator: phoneValidator,
            delay: 2,
          ),
          const SizedBox(height: 12),
          _buildSleekField(
            controller: emailController,
            label: 'Email Address',
            hint: 'john.ochieng@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator,
            delay: 3,
          ),
          const SizedBox(height: 12),
          _buildSleekField(
            controller: nationalIdController,
            label: 'National ID / Passport (Optional)',
            hint: '12345678',
            keyboardType: TextInputType.number,
            validator: nationalIdValidator,
            delay: 4,
          ),
          const SizedBox(height: 12),
          _buildSleekField(
            controller: passwordController,
            label: 'Password',
            hint: '••••••••',
            obscureText: obscurePassword,
            validator: passwordValidator,
            delay: 5,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textLightInDarkMode,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(passwordVisibilityProvider.notifier).state =
                      !obscurePassword,
            ),
          ),
          const SizedBox(height: 12),
          _buildSleekField(
            controller: confirmPasswordController,
            label: 'Confirm Password',
            hint: '••••••••',
            obscureText: obscureConfirmPassword,
            validator: confirmPasswordValidator,
            delay: 6,
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppTheme.textLightInDarkMode,
                size: 20,
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

  Widget _buildSleekField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    required int delay,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondaryDark.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    suffixIconConstraints: const BoxConstraints(maxHeight: 20),
                    suffixIcon: suffixIcon != null
                        ? Container(
                            alignment: Alignment.centerRight,
                            width: 30,
                            child: suffixIcon,
                          )
                        : null,
                  ),
                  validator: validator,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (delay * 100).ms)
        .slideY(begin: 0.05);
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
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(12),
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
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 800.ms);
  }

  Widget signInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: AppColors.greenLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 900.ms);
  }
}
