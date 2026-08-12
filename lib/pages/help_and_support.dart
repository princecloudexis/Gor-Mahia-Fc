import 'package:gormahiafc/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/apptheme.dart';

class HelpAndSupport extends ConsumerStatefulWidget {
  const HelpAndSupport({super.key});

  @override
  ConsumerState<HelpAndSupport> createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends ConsumerState<HelpAndSupport> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    const String recipientEmail = 'your.personal.email@example.com';

    final String subject = Uri.encodeComponent(
      'Support Request from Gor Mahia FC App',
    );

    final String body = Uri.encodeComponent('''
Name: ${_firstNameController.text} ${_lastNameController.text}
Email: ${_emailController.text}
Phone: ${_phoneController.text}

Message:
${_messageController.text}
''');

    final Uri mailtoUri = Uri.parse(
      'mailto:$recipientEmail?subject=$subject&body=$body',
    );

    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
      } else {
        throw 'Could not launch $mailtoUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email app. Please check if you have one installed.',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Us',
                style: theme.textTheme.displaySmall,
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 8),
              Text(
                'Have a question or need support? Fill out the form below and we\'ll get back to you.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textLight,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
              const SizedBox(height: 40),
              _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your first name' : null,
                delay: 200,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your last name' : null,
                delay: 300,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Please enter your email';
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                delay: 400,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number (Optional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                delay: 500,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _messageController,
                label: 'Your Message',
                icon: Icons.message_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your message' : null,
                maxLines: 5,
                delay: 600,
              ),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    required int delay,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.hintColor.withOpacity(0.4),
        width: 1.5,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
    );
    final decoration = const InputDecoration()
        .applyDefaults(theme.inputDecorationTheme)
        .copyWith(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryPink),

          border: baseBorder,
          enabledBorder: baseBorder,
          focusedBorder: focusedBorder,
        );
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
      decoration: decoration,
      validator: validator,
    ).animate().fadeIn(duration: 500.ms, delay: delay.ms).slideY(begin: 0.2);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendMessage,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : const Text('Send Message'),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 800.ms).slideY(begin: 0.2);
  }
}
