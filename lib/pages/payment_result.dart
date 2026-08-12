import 'package:gormahiafc/pages/details.dart';
import 'package:gormahiafc/pages/main_shell.dart';
import 'package:gormahiafc/pages/tickets.dart';
import 'package:gormahiafc/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaymentSuccess extends StatelessWidget {
  const PaymentSuccess({super.key});
  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainShell()),
      (route) => false, 
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goHome(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.accentGreen,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Successful!',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Your tickets are now available. We\'ve also sent a confirmation to your email.',
                  style: textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainShell()),
                    (route) => false,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const Tickets()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                ),
                child: const Text('View My Tickets'),
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }
}

class PaymentFailed extends StatelessWidget {
  final String eventSlug;
  final String errorMessage;

  const PaymentFailed({
    super.key,
    required this.eventSlug,
    required this.errorMessage,
  });

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goHome(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: AppTheme.accentRed, size: 100),
              const SizedBox(height: 24),
              Text(
                'Payment Failed',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  errorMessage,
                  style: textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainShell()),
                    (route) => false,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EventDetails(slug: eventSlug),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                ),
                child: const Text('Return to Match'),
              ),
            ],
          ),
        ).animate().shake(hz: 4, duration: 600.ms),
      ),
    );
  }
}