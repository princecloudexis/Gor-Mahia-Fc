import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kogalo_network/theme/app_colors.dart';

/// A beautiful, full-screen payment processing widget that replaces all the
/// scattered popup dialogs and inconsistent screens across the app.
///
/// Usage: Navigate to this screen AFTER getting a Paystack reference.
/// It polls [verifyStatus] every 3s and calls [onSuccess] or [onFailure].
class UniversalPaymentProcessingScreen extends StatefulWidget {
  /// Short title shown below the logo e.g. "Processing Membership"
  final String title;

  /// Paystack payment reference (used only for display / debug)
  final String reference;

  /// Called every [pollingInterval] seconds. Return `true` = payment done.
  /// Throw to signal a hard failure. Return `false` = still pending.
  final Future<bool> Function() verifyStatus;

  /// Called when [verifyStatus] returns `true`.
  final VoidCallback onSuccess;

  /// Called when the timeout expires or [verifyStatus] throws.
  /// Receives an error message string.
  final void Function(String message) onFailure;

  /// How long in seconds before we give up (default 120 = 2 minutes).
  final int timeoutSeconds;

  /// How often to call [verifyStatus] in seconds (default 3).
  final int pollingInterval;

  const UniversalPaymentProcessingScreen({
    super.key,
    required this.title,
    required this.reference,
    required this.verifyStatus,
    required this.onSuccess,
    required this.onFailure,
    this.timeoutSeconds = 120,
    this.pollingInterval = 3,
  });

  @override
  State<UniversalPaymentProcessingScreen> createState() =>
      _UniversalPaymentProcessingScreenState();
}

class _UniversalPaymentProcessingScreenState
    extends State<UniversalPaymentProcessingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  int _secondsPassed = 0;
  bool _isFinished = false;
  String _statusMessage = 'Waiting for Paystack confirmation…';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulsing logo animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Give backend 4 seconds to process Paystack's webhook before first poll.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _startPolling();
    });
  }

  void _startPolling() {
    _pollTimer =
        Timer.periodic(Duration(seconds: widget.pollingInterval), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsPassed += widget.pollingInterval;
      });

      if (_secondsPassed >= widget.timeoutSeconds) {
        _handleTimeout();
        return;
      }

      try {
        final isDone = await widget.verifyStatus();
        if (isDone) {
          _handleSuccess();
        } else {
          if (mounted) {
            setState(() {
              _statusMessage = 'Still waiting for confirmation…';
            });
          }
        }
      } catch (e) {
        // Silently ignore transient network errors while polling
        debugPrint('🔄 [UniversalPayment] Polling error: $e');
      }
    });
  }

  void _handleSuccess() {
    if (_isFinished) return;
    _isFinished = true;
    _pollTimer?.cancel();
    widget.onSuccess();
  }

  void _handleTimeout() {
    if (_isFinished) return;
    _isFinished = true;
    _pollTimer?.cancel();
    widget.onFailure(
      'We did not receive a payment confirmation in time.\n'
      'If you were charged, please contact support with reference: ${widget.reference}',
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_secondsPassed / widget.timeoutSeconds).clamp(0.0, 1.0);
    final remaining = widget.timeoutSeconds - _secondsPassed;

    return PopScope(
      canPop: false, // Prevent accidental back-navigation during payment
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.bgDark
            : const Color(0xFFF5F9F5),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Pulsing Logo ────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen.withValues(alpha: 0.08),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.18),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/images/Gor-Mahia-FC-logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Title ────────────────────────────────────────────────
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Status Message ───────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _statusMessage,
                      key: ValueKey(_statusMessage),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Do-not-close hint ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Please do not close this screen while we verify your payment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black45,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Progress bar ─────────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Verification progress',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${remaining}s remaining',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: isDark
                              ? Colors.white10
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Secured by Paystack badge ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 14,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Secured by Paystack',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white30 : Colors.black26,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
