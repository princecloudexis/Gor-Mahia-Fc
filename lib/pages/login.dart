import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/apptheme.dart';
import '../theme/app_colors.dart';
import './signup.dart';
import './main_shell.dart';
import '../controllers/auth_controller.dart';

final emailValidatorProvider = Provider<String? Function(String?)>((ref) {
  return (String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  };
});

final passwordValidatorProvider = Provider<String? Function(String?)>((ref) {
  return (String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  };
});

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _buttonController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (ModalRoute.of(context)?.isCurrent != true) return;

      if (next.status == AuthStatus.error && next.errorMessage != null) {
        _showErrorSnackBar(next.errorMessage!);
        ref.read(authControllerProvider.notifier).resetError();
      }
      if (next.status == AuthStatus.authenticated) {
        _navigateToHome();
      }
    });

    final isLoading =
        ref.watch(authControllerProvider).status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            _buildMainContent(isLoading),
          ],
        ),
      ),
    );
  }


  Widget _buildMainContent(bool isLoading) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),

            // Logo
            const _AppLogo(),
            const SizedBox(height: 32),

            // Header
            _buildHeader(),
            const SizedBox(height: 40),

            // Login Form
            _buildLoginForm(),
            const SizedBox(height: 32),

            // Submit Button
            _buildSubmitButton(isLoading),
            const SizedBox(height: 24),

            // Sign Up Link
            _buildSignUpLink(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to Gor Mahia FC',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white70,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          _buildEmailField(),
          const SizedBox(height: 16),

          // Password Field
          _buildPasswordField(),
          const SizedBox(height: 12),

          // Forgot Password
          _buildForgotPasswordButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    final validator = ref.watch(emailValidatorProvider);

    return _InputField(
      controller: _emailController,
      labelText: 'Email',
      hintText: 'Enter your email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: validator,
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPasswordField() {
    final validator = ref.watch(passwordValidatorProvider);

    return _InputField(
      controller: _passwordController,
      labelText: 'Password',
      hintText: 'Enter your password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      validator: validator,
      onFieldSubmitted: (_) => _handleLogin(),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.white.withOpacity(0.5),
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => _showForgotPasswordSheet(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 550.ms);
  }

  Widget _buildSubmitButton(bool isLoading) {
    return GestureDetector(
      onTapDown: (_) => _buttonController.forward(),
      onTapUp: (_) {
        _buttonController.reverse();
        if (!isLoading) _handleLogin();
      },
      onTapCancel: () => _buttonController.reverse(),
      child: AnimatedBuilder(
        animation: _buttonController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - (_buttonController.value * 0.03),
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      key: ValueKey('text'),
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: AppTheme.textLight.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => _navigateToSignUp(),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 700.ms);
  }

  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      // Haptic feedback
      HapticFeedback.lightImpact();

      await ref
          .read(authControllerProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    }
  }


  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const Signup(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPasswordSheet(),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn();
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
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
              labelText,
              style: TextStyle(
                color: AppColors.textSecondaryDark.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
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
                prefixIconConstraints: const BoxConstraints(minWidth: 32, maxHeight: 20),
                prefixIcon: Container(
                  alignment: Alignment.centerLeft,
                  width: 32,
                  child: Icon(prefixIcon, color: AppColors.primaryGreen, size: 18),
                ),
              ),
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet();

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailValidator = ref.watch(emailValidatorProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.bgSurfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Email input
              _InputField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: emailValidator,
                onFieldSubmitted: (_) => _handlePasswordReset(),
              ),
              const SizedBox(height: 24),

              // Send button
              _buildSendButton(),
              const SizedBox(height: 12),

              // Cancel button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePasswordReset,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: AppTheme.primaryGreen.withOpacity(0.6),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  key: ValueKey('text'),
                  'Send Reset Link',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Future<void> _handlePasswordReset() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(
        icon: Icons.mark_email_read_outlined,
        title: 'Check Your Email',
        message: 'We\'ve sent a password reset link to your email address.',
        buttonText: 'Got it',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _SuccessDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
