import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class EveProfileScreen extends StatefulWidget {
  const EveProfileScreen({super.key});

  @override
  State<EveProfileScreen> createState() => _EveProfileScreenState();
}

class _EveProfileScreenState extends State<EveProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: 0.9,
      upperBound: 1.08,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Halo verde pulsante detrás del texto.
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Center(
                  child: Container(
                    width: 360 * _pulseController.value,
                    height: 360 * _pulseController.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.neonGreen
                              .withValues(alpha: 0.14 * _pulseController.value),
                          AppColors.neonGreen.withValues(alpha: 0.04),
                          AppColors.backgroundDark.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Brillo verde en la parte inferior.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.2, 1.2),
                    radius: 1.2,
                    colors: [
                      AppColors.neonGreen.withValues(alpha: 0.24),
                      AppColors.neonGreen.withValues(alpha: 0.07),
                      AppColors.backgroundDark.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Ondas verdes en la parte inferior.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 280,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.neonGreen.withValues(alpha: 0.95),
                        AppColors.neonGreen.withValues(alpha: 0.0),
                      ],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.srcIn,
                  child: CustomPaint(
                    painter: _GlowWavesPainter(),
                  ),
                ),
              ),
            ),
            // Sparkles decorativos.
            Positioned.fill(
              child: CustomPaint(
                painter: _SparklesPainter(),
              ),
            ),
            // Contenido principal centrado.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _GlowIcon(
                    icon: Icons.favorite_border,
                    size: 36,
                    color: AppColors.neonGreen,
                  ),
                  const SizedBox(height: 24),
                  _GradientText(
                    'Eve',
                    style: textTheme.displayLarge?.copyWith(
                      fontFamily: 'serif',
                      fontSize: 96,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      shadows: const [
                        Shadow(
                          color: AppColors.neonGlowStrong,
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.neonGreenBright,
                        AppColors.neonGreen,
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'is',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  _GradientText(
                    'beautiful',
                    style: textTheme.displayMedium?.copyWith(
                      fontFamily: 'serif',
                      fontSize: 60,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      shadows: const [
                        Shadow(
                          color: AppColors.neonGlowStrong,
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.neonGreen,
                        AppColors.neonGreenBright,
                        AppColors.neonGreen,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 220,
                    height: 26,
                    child: CustomPaint(
                      painter: _UnderlinePainter(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseController.value,
                        child: _GlowIcon(
                          icon: Icons.favorite,
                          size: 20,
                          color: AppColors.neonGreen,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Botón de retroceso flotante.
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    AppRouter.goHome(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _GlowIcon({
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const _GradientText(
    this.text, {
    required this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: style?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final path = Path();
    path.moveTo(0, size.height * 0.65);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 1.25,
      size.width * 0.75,
      size.height * 0.45,
    );
    path.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.25,
      size.width,
      size.height * 0.35,
    );
    canvas.drawPath(path, paint);

    // Brillos en los extremos.
    final dotPaint = Paint()
      ..color = AppColors.neonGreen
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(0, size.height * 0.65), 3.5, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.35), 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var i = 0; i < 16; i++) {
      final path = Path();
      final baseY = size.height - 10 - (i * 14);
      final amplitude = 8 + i * 1.5;
      final frequency = 1.3 + i * 0.18;
      final phase = i * 0.65;
      path.moveTo(0, baseY);

      for (var step = 0; step <= 80; step++) {
        final x = size.width * step / 80;
        final t = step / 80;
        final wave = math.sin((t * frequency * 2 * math.pi) + phase);
        final envelope = t * (1 - t) * 4;
        final y = baseY - (i * 2.5 * t) - (amplitude * wave * envelope);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparklesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonGreen
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final positions = [
      const Offset(0.15, 0.22),
      const Offset(0.82, 0.18),
      const Offset(0.88, 0.42),
      const Offset(0.12, 0.48),
      const Offset(0.75, 0.62),
      const Offset(0.22, 0.68),
      const Offset(0.65, 0.28),
      const Offset(0.35, 0.75),
    ];

    for (final p in positions) {
      final center = Offset(size.width * p.dx, size.height * p.dy);
      canvas.drawCircle(center, 2.2, paint);
      // Pequeñas cruces en algunos.
      if ((p.dx * p.dy * 100).toInt() % 2 == 0) {
        final crossPaint = Paint()
          ..color = AppColors.neonGreen.withValues(alpha: 0.6)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          center.translate(-5, 0),
          center.translate(5, 0),
          crossPaint,
        );
        canvas.drawLine(
          center.translate(0, -5),
          center.translate(0, 5),
          crossPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
