import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/create_habit_dialog.dart';

/// Tutorial de bienvenida que se muestra la primera vez que se abre la app
/// (y se puede re-lanzar desde Ajustes → «Ver tutorial»).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String seenFlagKey = 'onboarding_seen_v1';

  /// Abre el tutorial como pantalla completa sobre el navegador raíz.
  static Future<void> launch() {
    final navigator = AppRouter.rootNavigatorKey.currentState;
    if (navigator == null) return Future.value();
    return navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.wb_sunny_rounded,
      color: AppColors.neonGreen,
      title: 'Bienvenido a SunHabit',
      description:
          'Construye hábitos, transforma tu vida.\n\nTe enseñamos lo esencial en menos de un minuto.',
    ),
    _Slide(
      icon: Icons.add_task_rounded,
      color: AppColors.water,
      title: 'Crea tu hábito',
      description:
          'Toca «+» y elige una categoría, el tipo de objetivo (Sí/No, cantidad, checklist o cronómetro), su frecuencia y cuándo empieza.\n\nTambién puedes crear tus propias categorías con icono, imagen y sonido.',
    ),
    _Slide(
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.fire,
      title: 'Registra tu progreso',
      description:
          'Toca un hábito para abrir su registro: marca Sí o No, suma cantidades, tacha tareas de la lista o usa el cronómetro.\n\nLos hábitos de Sí/No se completan con un solo toque.',
    ),
    _Slide(
      icon: Icons.alarm_rounded,
      color: AppColors.purple,
      title: 'Recordatorios puntuales',
      description:
          'Cada hábito puede tener notificaciones o alarmas con tu propio sonido, a la hora y en los días que elijas.\n\nActiva los permisos para que suenen siempre a tiempo.',
    ),
    _Slide(
      icon: Icons.star_rounded,
      color: AppColors.star,
      title: 'Tu porqué',
      description:
          'Cada hábito guarda tu motivación: una imagen, una frase y tu meta personal.\n\nÁbrela con la ★ desde el registro cuando necesites un empujón.',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish({bool createHabit = false}) async {
    if (createHabit) await _openCreateHabitFromHere();
    if (mounted) Navigator.of(context).pop();
  }

  /// Abre el wizard de creación sobre el propio tutorial. Al guardar, el
  /// hábito queda persistido y sus recordatorios programados antes de
  /// cerrar el tutorial.
  Future<void> _openCreateHabitFromHere() async {
    final categories = HabitsRepository().getCategories();
    if (categories.isEmpty || !mounted) return;
    final habit = await showDialog<Habit>(
      context: context,
      builder: (_) => CreateHabitDialog(categories: categories),
    );
    if (habit == null || !mounted) return;
    await HabitsRepository().addHabit(habit);
    unawaited(ReminderService.instance.scheduleHabit(habit));
  }

  void _next() {
    if (_isLast) {
      _finish(createHabit: true);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: TextButton(
                    onPressed: _isLast ? null : () => _finish(),
                    child: Text(
                      'Omitir',
                      style: textTheme.titleSmall?.copyWith(
                        color: _isLast
                            ? Colors.transparent
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) =>
                      _SlideView(slide: _slides[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final selected = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selected ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.neonGreen
                                : AppColors.borderDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: _next,
                      child: Container(
                        height: AppConstants.controlHeight,
                        decoration: AppDecorations.neonButton,
                        alignment: Alignment.center,
                        child: Text(
                          _isLast
                              ? 'Crear mi primer hábito'
                              : 'Siguiente',
                          style: textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF152000),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isLast)
                      GestureDetector(
                        onTap: () => _finish(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Explorar la app primero',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.color.withValues(alpha: 0.12),
              border: Border.all(
                color: slide.color.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.color.withValues(alpha: 0.25),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(slide.icon, color: slide.color, size: 56),
          ),
          const SizedBox(height: 34),
          Text(
            slide.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
