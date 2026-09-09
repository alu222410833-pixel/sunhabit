import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

/// Tarjeta de resumen del día.
///
/// Muestra el total de hábitos, cuántos se completaron, cuántos faltan
/// y un anillo circular con el porcentaje de progreso.
class HomeSummaryCard extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;
  final double percent;
  final TextTheme textTheme;

  const HomeSummaryCard({
    super.key,
    required this.total,
    required this.completed,
    required this.pending,
    required this.percent,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppDecorations.summaryCard,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen de hoy', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('$total', style: textTheme.displayMedium),
                  Text('Hábitos', style: textTheme.bodySmall),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStat(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.neonGreen,
                          value: completed,
                          label: 'Completados',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 38,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        color: AppColors.borderDark,
                      ),
                      Expanded(
                        child: _SummaryStat(
                          icon: Icons.close_rounded,
                          iconColor: AppColors.gold,
                          value: pending,
                          label: 'Pendientes',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ProgressRing(progress: percent, textTheme: textTheme),
          ],
        ),
      ),
    );
  }
}

/// Fila pequeña con un icono, un valor numérico y una etiqueta de texto.
class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;

  const _SummaryStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: textTheme.titleMedium?.copyWith(fontSize: 17),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}

/// Anillo circular animado que muestra el porcentaje de progreso.
class _ProgressRing extends StatelessWidget {
  final double progress;
  final TextTheme textTheme;

  const _ProgressRing({required this.progress, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.18)),
        boxShadow: AppDecorations.neonGlowSoft,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _ProgressRingPainter(value),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: textTheme.displayMedium,
                  ),
                  Text('Completado', style: textTheme.labelSmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pinta el anillo de progreso con glow y un degradado verde.
class _ProgressRingPainter extends CustomPainter {
  final double progress;

  const _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final normalized = progress.clamp(0.0, 1.0).toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = math.pi * 2 * normalized;

    // Fondo grisáceo del anillo.
    final trackPaint = Paint()
      ..color = AppColors.neonGreen.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (normalized == 0) return;

    // Capa de brillo exterior suave.
    final glowPaint = Paint()
      ..color = AppColors.neonGreen.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glowPaint);

    // Arco de progreso con degradado verde.
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.neonGreenDark, AppColors.neonGreenBright],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
