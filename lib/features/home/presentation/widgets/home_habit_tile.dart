import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';

/// Tarjeta individual para un hábito en la lista de inicio.
///
/// Muestra el icono/imagen del hábito, su título, el progreso
/// y un indicador circular que invita a abrir la ventana de completar.
/// Tanto la fila completa como el indicador responden al mismo [onTap].
class HomeHabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onTap;

  const HomeHabitTile({
    super.key,
    required this.habit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Color del icono: usa el color del hábito o el verde neón por defecto.
    final iconColor = habit.iconColor ?? AppColors.neonGreen;
    final imagePath = habit.effectiveImagePath;

    final subtitleParts = <String>[
      if (habit.progressText != null) habit.progressText!,
      if (habit.earliestReminderMinutes != null)
        '${(habit.earliestReminderMinutes! ~/ 60).toString().padLeft(2, '0')}:${(habit.earliestReminderMinutes! % 60).toString().padLeft(2, '0')}',
    ];
    final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join(' · ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: 64,
      decoration: AppDecorations.habitCard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra de color/glow en el borde izquierdo
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        iconColor.withValues(alpha: 0.6),
                        iconColor.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.cardRadius),
                      bottomLeft: Radius.circular(AppConstants.cardRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(-4, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Contenedor con el icono o imagen del hábito.
                Container(
                  width: 36,
                  height: 36,
                  decoration: AppDecorations.iconOnlyGlow(iconColor),
                  alignment: Alignment.center,
                  child: imagePath != null
                      ? HabitImageAvatar(imagePath: imagePath, size: 36)
                      : Icon(habit.effectiveIcon, color: iconColor, size: 27),
                ),
                const SizedBox(width: 13),

                // Título y texto de progreso del hábito.
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),

                // Indicador visual de completado. Tocarlo abre la misma ventana.
                Center(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: habit.isCompleted
                        ? Container(
                            key: const ValueKey(true),
                            width: 27,
                            height: 27,
                            decoration: AppDecorations.neonCircle,
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF101600),
                              size: 18,
                            ),
                          )
                        : Icon(
                            Icons.circle_outlined,
                            key: const ValueKey(false),
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            size: 27,
                          ),
                  ),
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
