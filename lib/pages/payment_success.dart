import 'dart:math';
import 'package:gormahiafc/pages/main_shell.dart';
import 'package:gormahiafc/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gormahiafc/providers/user_providers.dart';
import 'package:gormahiafc/providers/navigation_providers.dart';
import 'package:gormahiafc/pages/my_membership.dart';
import 'package:flutter_animate/flutter_animate.dart';
class PaymentSuccess extends ConsumerStatefulWidget {
  final String title;

  const PaymentSuccess({super.key, required this.title});

  @override
  ConsumerState<PaymentSuccess> createState() => _PaymentSuccessState();
}

class _PaymentSuccessState extends ConsumerState<PaymentSuccess>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() => setState(() {}));

    _generateParticles();
    _confettiController.forward();
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        delay: _random.nextDouble() * 0.6,
        speed: 0.4 + _random.nextDouble() * 0.6,
        size: 6 + _random.nextDouble() * 10,
        color: _randomColor(),
        shape: i % 3,
        drift: (_random.nextDouble() - 0.5) * 0.4,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 6,
      ));
    }
  }

  Color _randomColor() {
    final colors = [
      AppColors.primaryGreen,
      const Color(0xFF27AE60),
      Colors.amber,
      Colors.yellowAccent,
      Colors.white,
      const Color(0xFF1ABC9C),
      Colors.lightGreenAccent,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Confetti layer
          Positioned.fill(
            child: CustomPaint(
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _confettiController.value,
                screenHeight: MediaQuery.of(context).size.height,
                screenWidth: MediaQuery.of(context).size.width,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildSuccessIcon(),
                  const SizedBox(height: 36),
                  Text(
                    'WELCOME TO THE\n${widget.title.toUpperCase()}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 14),
                  Text(
                    'Your membership has been\nsuccessfully activated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                  const SizedBox(height: 48),
                  _buildDigitalCard(),
                  const SizedBox(height: 48),
                  _buildButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.15),
                width: 20,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 1200.ms, curve: Curves.easeInOut),

          // Middle ring
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.3),
                width: 8,
              ),
            ),
          ).animate()
           .scale(duration: 800.ms, delay: 100.ms, curve: Curves.elasticOut),

          // Green circle with checkmark
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x5027AE60),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
          ).animate()
           .scale(duration: 700.ms, delay: 200.ms, curve: Curves.elasticOut)
           .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildDigitalCard() {
    final membershipAsync = ref.watch(membershipDetailsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR DIGITAL CARD',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4), width: 1.5),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen.withOpacity(0.18),
                AppColors.bgSurfaceDark,
                AppColors.bgSurfaceDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.1),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: membershipAsync.when(
            data: (details) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                            details.memberName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            details.membershipType,
                            style: TextStyle(
                              color: AppColors.greenLight.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardLabel('Member ID'),
                          const SizedBox(height: 4),
                          _cardValue(details.memberId ?? 'N/A'),
                          const SizedBox(height: 16),
                          _cardLabel('Valid Until'),
                          const SizedBox(height: 4),
                          _cardValue(details.validUntil ?? 'N/A'),
                        ],
                      ),
                    ),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.qr_code_2,
                        color: Colors.black,
                        size: 60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            ),
            error: (e, s) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Error loading card', style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 700.ms).slideY(begin: 0.15),
      ],
    );
  }

  Widget _cardLabel(String text) => Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
      );

  Widget _cardValue(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyMembership()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'VIEW MY CARD',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 800.ms),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Reset tab to Home (index 0) before navigating back
              ref.read(mainShellTabIndexProvider.notifier).state = 0;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainShell()),
                (route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.15)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'BACK TO HOME',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 900.ms),
      ],
    );
  }
}

// ─── Confetti Particle Model ───────────────────────────────────────────────────
class _ConfettiParticle {
  final double x;      // 0–1 horizontal start
  final double delay;  // 0–1 fraction of animation to wait
  final double speed;  // relative fall speed
  final double size;
  final Color color;
  final int shape;     // 0=rect, 1=circle, 2=triangle
  final double drift;  // horizontal sway
  final double rotation;
  final double rotationSpeed;

  const _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.shape,
    required this.drift,
    required this.rotation,
    required this.rotationSpeed,
  });
}

// ─── Confetti CustomPainter ───────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final double screenHeight;
  final double screenWidth;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final effectiveT = t * p.speed;
      final x = p.x * size.width + p.drift * size.width * t * sin(t * 4);
      final y = -20 + effectiveT * (size.height + 40);
      final alpha = t < 0.7 ? 1.0 : (1.0 - t) / 0.3;
      final rotation = p.rotation + p.rotationSpeed * t;

      final paint = Paint()
        ..color = p.color.withOpacity(alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      switch (p.shape) {
        case 0: // Rectangle / strip
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size * 0.4, height: p.size),
            paint,
          );
          break;
        case 1: // Circle
          canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
          break;
        case 2: // Square
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size * 0.7, height: p.size * 0.7),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
