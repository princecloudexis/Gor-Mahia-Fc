import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gormahiafc/pages/main_shell.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../providers/fcm_providers.dart';
import '../theme/app_colors.dart';
import 'login.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background Pattern Painter
// ─────────────────────────────────────────────────────────────────────────────
class SplashPatternPainter extends CustomPainter {
  final double animationValue;
  SplashPatternPainter({this.animationValue = 0});

  @override
  void paint(Canvas canvas, Size size) {
    _drawBase(canvas, size);
    _drawHexGrid(canvas, size);
    _drawDiagonalLines(canvas, size);
    _drawVignettes(canvas, size);
  }

  void _drawBase(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.greenDarkest,
          AppColors.greenDark,
          AppColors.greenDarkest,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawHexGrid(Canvas canvas, Size size) {
    const double hexSize = 26.0;
    final double hexH = math.sqrt(3) * hexSize;
    final double colW = hexSize * 1.5;
    final double drift = animationValue * hexH;

    for (
      double col = -hexSize * 2;
      col < size.width + hexSize * 2;
      col += colW
    ) {
      final bool isOdd = ((col / colW).round() % 2) != 0;
      final double rowOffset = isOdd ? hexH * 0.5 : 0;

      for (
        double row = -hexH * 2 + (drift % hexH);
        row < size.height + hexH * 2;
        row += hexH
      ) {
        final double cx = col;
        final double cy = row + rowOffset;

        final double nx = (cx - size.width * 0.5) / size.width;
        final double ny = (cy - size.height * 0.5) / size.height;
        final double dist = math.sqrt(nx * nx + ny * ny);
        final double alpha = (0.04 + (1 - dist) * 0.07).clamp(0.02, 0.11);

        _drawHexagon(
          canvas,
          Paint()
            ..color = AppColors.greenLight.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7,
          cx,
          cy,
          hexSize - 1,
        );

        final int ci = (col / colW).round();
        final int ri = (row / hexH).round();
        if ((ci + ri) % 9 == 0) {
          _drawHexagon(
            canvas,
            Paint()
              ..color = AppColors.greenMain.withValues(alpha: 0.15)
              ..style = PaintingStyle.fill,
            cx,
            cy,
            hexSize - 2,
          );
        }
      }
    }
  }

  void _drawHexagon(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double r,
  ) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (math.pi / 3) * i - math.pi / 6;
      final double x = cx + r * math.cos(angle);
      final double y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDiagonalLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;

    const double spacing = 24.0;
    final double shift = animationValue * spacing * 2;

    for (int i = 0; i < 20; i++) {
      final double x = (i * spacing + shift) % (size.width + spacing) - spacing;
      paint.color = Colors.white.withValues(alpha: i % 3 == 0 ? 0.05 : 0.025);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * 0.22, size.height),
        paint,
      );
    }
  }

  void _drawVignettes(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Top vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgDark.withValues(alpha: 0.60),
            Colors.transparent,
          ],
          stops: const [0.0, 0.30],
        ).createShader(rect),
    );

    // Bottom vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.bgDark.withValues(alpha: 0.60),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35],
        ).createShader(rect),
    );

    // Center spotlight
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.52,
          colors: [
            AppColors.greenMedium.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(SplashPatternPainter old) =>
      old.animationValue != animationValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// Rotating Ring Painter
// ─────────────────────────────────────────────────────────────────────────────
class RotatingRingPainter extends CustomPainter {
  final double rotation;
  final double pulseValue;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashCount;
  final bool reverse;

  RotatingRingPainter({
    required this.rotation,
    required this.pulseValue,
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashCount,
    this.reverse = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double r = radius + pulseValue * 4;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double dashAngle = (math.pi * 2) / (dashCount * 2);
    final double rot = reverse ? -rotation : rotation;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = rot + i * dashAngle * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        dashAngle * 0.65,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(RotatingRingPainter old) =>
      old.rotation != rotation || old.pulseValue != pulseValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash Screen
// ─────────────────────────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  bool _isInitialized = false;

  late AnimationController _pulseController;
  late AnimationController _bgController;
  late AnimationController _ring1Controller;
  late AnimationController _ring2Controller;
  late AnimationController _ring3Controller;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _ring1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _ring2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    _ring3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bgController.dispose();
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    _ring3Controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      _initFCM();
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 3200)),
        _checkAuth(),
      ]);
      await Future.delayed(const Duration(milliseconds: 100));
      _navigate();
    } catch (e) {
      debugPrint('❌ Splash init error: $e');
      _navigateToLogin();
    }
  }

  void _navigate() {
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    switch (authState.status) {
      case AuthStatus.authenticated:
        _navigateToHome();
      default:
        _navigateToLogin();
    }
  }

  void _initFCM() {
    Future.microtask(() {
      try {
        ref.read(fcmServiceProvider).init();
      } catch (e) {
        debugPrint('⚠️ FCM init error: $e');
      }
    });
  }

  Future<void> _checkAuth() async {
    await ref.read(authControllerProvider.notifier).checkInitialAuthStatus();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const Login(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) => CustomPaint(
          painter: SplashPatternPainter(animationValue: _bgController.value),
          child: child,
        ),
        child: SizedBox.expand(
          child: SafeArea(
            child: Stack(
              children: [
                // ── Centered column ─────────────────────────────────────
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 28),
                      _buildClubName(),
                      const SizedBox(height: 26),
                      _buildDivider(),
                      const SizedBox(height: 42),
                      _buildBranchBadge(),
                    ],
                  ),
                ),

                // ── Bottom footer ───────────────────────────────────────
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: _buildFooter(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo with animated rings ──────────────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _ring1Controller,
            _ring2Controller,
            _ring3Controller,
          ]),
          builder: (context, child) {
            final double pulse = _pulseController.value;
            final double r1 = _ring1Controller.value * math.pi * 2;
            final double r2 = _ring2Controller.value * math.pi * 2;
            final double r3 = _ring3Controller.value * math.pi * 2;

            return SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Outermost breathing circle ──────────────────────────
                  Container(
                    width: 238 + pulse * 6,
                    height: 238 + pulse * 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.greenLight.withValues(
                          alpha: 0.04 + pulse * 0.05,
                        ),
                        width: 1,
                      ),
                    ),
                  ),

                  // ── Ring A: slow clockwise green dashes ─────────────────
                  CustomPaint(
                    size: const Size(224, 224),
                    painter: RotatingRingPainter(
                      rotation: r1,
                      pulseValue: pulse,
                      color: AppColors.greenLight.withValues(alpha: 0.20),
                      radius: 110,
                      strokeWidth: 1.2,
                      dashCount: 12,
                      reverse: false,
                    ),
                  ),

                  // ── Ring B: medium counter-clockwise blue dashes ─────────
                  CustomPaint(
                    size: const Size(204, 204),
                    painter: RotatingRingPainter(
                      rotation: r2,
                      pulseValue: pulse * 0.7,
                      color: AppColors.blueLight.withValues(alpha: 0.28),
                      radius: 98,
                      strokeWidth: 1.6,
                      dashCount: 8,
                      reverse: true,
                    ),
                  ),

                  // // ── Ring C: fast clockwise bright green dashes ───────────
                  // CustomPaint(
                  //   size: const Size(186, 186),
                  //   painter: RotatingRingPainter(
                  //     rotation: r3,
                  //     pulseValue: pulse * 0.5,
                  //     color: AppColors.greenMedium.withValues(alpha: 0.38),
                  //     radius: 89,
                  //     strokeWidth: 2.0,
                  //     dashCount: 6,
                  //     reverse: false,
                  //   ),
                  // ),

                  // ── Glow behind logo ────────────────────────────────────
                  Container(
                    width: 174,
                    height: 174,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greenMedium.withValues(
                            alpha: 0.18 + pulse * 0.22,
                          ),
                          blurRadius: 30 + pulse * 24,
                          spreadRadius: 2 + pulse * 10,
                        ),
                        BoxShadow(
                          color: AppColors.blueMain.withValues(
                            alpha: 0.10 + pulse * 0.08,
                          ),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),

                  // ── Logo container ───────────────────────────────────────
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.greenSurface.withValues(alpha: 0.7),
                          AppColors.bgDark.withValues(alpha: 0.95),
                        ],
                        stops: const [0.25, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: child,
                  ),
                ],
              ),
            );
          },
          child: Image.asset(
            'assets/images/Gor-Mahia-FC-logo.png',
            fit: BoxFit.contain,
          ),
        )
        .animate()
        .scale(
          duration: 1000.ms,
          curve: Curves.elasticOut,
          begin: const Offset(0.1, 0.1),
          end: const Offset(1.0, 1.0),
        )
        .fadeIn(duration: 600.ms);
  }

  // ── Club name ─────────────────────────────────────────────────────────────
  Widget _buildClubName() {
    return AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final double s = _shimmerController.value;
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.75),
                  AppColors.greenPale,
                  Colors.white,
                  AppColors.greenPale,
                  Colors.white.withValues(alpha: 0.75),
                ],
                stops: [
                  (s - 0.3).clamp(0.0, 1.0),
                  (s - 0.1).clamp(0.0, 1.0),
                  s,
                  (s + 0.1).clamp(0.0, 1.0),
                  (s + 0.3).clamp(0.0, 1.0),
                ],
                begin: Alignment(-1.0 + (s * 2), 0.0),
                end: Alignment(1.0 + (s * 2), 0.0),
              ).createShader(bounds),
              child: child,
            );
          },
          child: Text(
            'GOR MAHIA FC',
            style: TextStyle(
              fontSize: 33,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 5.0,
              fontFamily: 'Manrope',
              height: 1.0,
              shadows: [
                Shadow(
                  color: AppColors.greenMain.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 700.ms, delay: 500.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }



  // ── Divider ───────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _gradLine(toRight: false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _dot(3, 0.4),
              const SizedBox(width: 5),
              _dot(6, 1.0),
              const SizedBox(width: 5),
              _dot(3, 0.4),
            ],
          ),
        ),
        _gradLine(toRight: true),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 900.ms);
  }

  Widget _gradLine({required bool toRight}) => Container(
    width: 52,
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: toRight
            ? [AppColors.gold.withValues(alpha: 0.7), Colors.transparent]
            : [Colors.transparent, AppColors.gold.withValues(alpha: 0.7)],
      ),
    ),
  );

  Widget _dot(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.gold.withValues(alpha: alpha),
    ),
  );

  // ── Branch Badge ────────────────────────────────────────────────────────
  Widget _buildBranchBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.4),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/branch-logo.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.shield, color: Colors.white54, size: 48),
          ),
          const SizedBox(width: 18),
          Container(
            width: 1,
            height: 38,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MACHAKOS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.5,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'BRANCH',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 3.5,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms, delay: 1100.ms)
    .scale(
      begin: const Offset(0.9, 0.9),
      end: const Offset(1.0, 1.0),
      duration: 500.ms,
      delay: 1100.ms,
      curve: Curves.easeOutBack,
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 1,
              color: Colors.white.withValues(alpha: 0.10),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.sports_soccer,
              size: 11,
              color: Colors.white.withValues(alpha: 0.16),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 1,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'EST. 1968  ·  NAIROBI, KENYA',
          style: TextStyle(
            fontSize: 9.5,
            color: Colors.white.withValues(alpha: 0.22),
            letterSpacing: 2.2,
            fontWeight: FontWeight.w500,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 1500.ms);
  }
}
