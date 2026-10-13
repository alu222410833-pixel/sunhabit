import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/categories/presentation/create_category_dialog.dart';
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
      description: 'Construye hábitos, transforma tu vida.\n\nTe guiamos por la app en menos de un minuto.',
    ),
    _Slide(
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.fire,
      title: 'Registra tu progreso',
      description: 'Toca un hábito y regístralo a tu manera:',
      features: [
        _SlideFeature(
          icon: Icons.check_circle_rounded,
          color: AppColors.neonGreen,
          label: 'Sí / No',
          caption: 'un solo toque',
        ),
        _SlideFeature(
          icon: Icons.exposure_plus_1_rounded,
          color: AppColors.water,
          label: 'Cantidad',
          caption: 'suma tu progreso',
        ),
        _SlideFeature(
          icon: Icons.checklist_rounded,
          color: AppColors.purple,
          label: 'Checklist',
          caption: 'tacha cada tarea',
        ),
        _SlideFeature(
          icon: Icons.timer_rounded,
          color: AppColors.gold,
          label: 'Cronómetro',
          caption: 'mide tu tiempo',
        ),
      ],
    ),
    _Slide(
      icon: Icons.alarm_rounded,
      color: AppColors.purple,
      title: 'Recordatorios puntuales',
      description: 'A la hora y en los días que elijas:',
      features: [
        _SlideFeature(
          icon: Icons.notifications_rounded,
          color: AppColors.water,
          label: 'Notificación',
          caption: 'aviso + acciones rápidas',
        ),
        _SlideFeature(
          icon: Icons.alarm_rounded,
          color: AppColors.purple,
          label: 'Alarma',
          caption: 'pantalla completa + sonido',
        ),
        _SlideFeature(
          icon: Icons.music_note_rounded,
          color: AppColors.fire,
          label: 'Tu sonido',
          caption: 'audio o desde un video',
        ),
        _SlideFeature(
          icon: Icons.calendar_month_rounded,
          color: AppColors.neonGreen,
          label: 'Tus días',
          caption: 'elige cuándo suena',
        ),
      ],
    ),
    _Slide(
      icon: Icons.star_rounded,
      color: AppColors.star,
      title: 'Tu porqué',
      description: 'Cada hábito guarda tu motivación — ábrela con la ★ desde el registro:',
      features: [
        _SlideFeature(
          icon: Icons.image_rounded,
          color: AppColors.water,
          label: 'Imagen',
          caption: 'tu meta en foto',
        ),
        _SlideFeature(
          icon: Icons.format_quote_rounded,
          color: AppColors.star,
          label: 'Frase',
          caption: 'escrita por ti',
        ),
        _SlideFeature(
          icon: Icons.flag_rounded,
          color: AppColors.neonGreen,
          label: 'Meta',
          caption: 'lo que quieres lograr',
        ),
      ],
    ),
  ];

  /// La última página no es una slide de texto sino el paso interactivo:
  /// crear la primera categoría y el primer hábito con los diálogos reales.
  int get _interactivePage => _slides.length;
  int get _pageCount => _slides.length + 1;

  bool get _isLast => _page == _pageCount - 1;

  String? _createdCategoryName;
  String? _createdHabitTitle;

  Future<void> _finish() async {
    if (mounted) Navigator.of(context).pop();
  }

  /// Abre el diálogo de categoría sobre el propio tutorial. Al guardar,
  /// la categoría queda persistida y el paso se marca como completado.
  Future<void> _openCreateCategoryFromHere() async {
    final category = await showDialog<Category>(
      context: context,
      builder: (_) => const CreateCategoryDialog(),
    );
    if (category == null || !mounted) return;
    await HabitsRepository().addCategory(category);
    setState(() => _createdCategoryName = category.name);
  }

  /// Abre el wizard de creación sobre el propio tutorial. Al guardar, el
  /// hábito queda persistido y sus recordatorios programados.
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
    setState(() => _createdHabitTitle = habit.title);
  }

  void _next() {
    if (_isLast) {
      _finish();
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
                  itemCount: _pageCount,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => i == _interactivePage
                      ? _ActionsStep(
                          createdCategoryName: _createdCategoryName,
                          createdHabitTitle: _createdHabitTitle,
                          onCreateCategory: _openCreateCategoryFromHere,
                          onCreateHabit: _openCreateHabitFromHere,
                        )
                      : _SlideView(slide: _slides[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pageCount, (i) {
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
                          _isLast ? 'Listo' : 'Siguiente',
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
  final List<_SlideFeature>? features;

  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.features,
  });
}

/// Mini-tarjeta visual dentro de una slide: icono + etiqueta corta.
/// Sustituye a los párrafos largos cuando hay que mostrar varias
/// opciones (p. ej. las 4 formas de registrar un hábito).
class _SlideFeature {
  final IconData icon;
  final Color color;
  final String label;
  final String caption;

  const _SlideFeature({
    required this.icon,
    required this.color,
    required this.label,
    required this.caption,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasFeatures = slide.features != null;
    final iconSize = hasFeatures ? 84.0 : 120.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
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
                    child: Icon(
                      slide.icon,
                      color: slide.color,
                      size: hasFeatures ? 40 : 56,
                    ),
                  ),
                  SizedBox(height: hasFeatures ? 24 : 34),
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
                  if (slide.features != null) ...[
                    const SizedBox(height: 24),
                    _FeatureGrid(features: slide.features!),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<_SlideFeature> features;

  const _FeatureGrid({required this.features});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final f in features)
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: f.color.withValues(alpha: 0.14),
                    border: Border.all(color: f.color.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(f.icon, color: f.color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  f.label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  f.caption,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Última página del tutorial: guía al usuario a través de los diálogos
/// reales de creación en lugar de explicarlos con texto.
class _ActionsStep extends StatelessWidget {
  final String? createdCategoryName;
  final String? createdHabitTitle;
  final VoidCallback onCreateCategory;
  final VoidCallback onCreateHabit;

  const _ActionsStep({
    required this.createdCategoryName,
    required this.createdHabitTitle,
    required this.onCreateCategory,
    required this.onCreateHabit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonGreen.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonGreen.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: AppColors.neonGreen,
              size: 46,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Empecemos',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Dos pasos y listo — sin leer nada más:',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _StepCard(
            number: 1,
            icon: Icons.category_outlined,
            color: AppColors.water,
            title: 'Crear mi primera categoría',
            subtitle: 'Nombre, color, icono o imagen y sonido.',
            doneLabel: createdCategoryName != null
                ? 'Creada: $createdCategoryName'
                : null,
            onTap: onCreateCategory,
          ),
          const SizedBox(height: 12),
          _StepCard(
            number: 2,
            icon: Icons.add_task_rounded,
            color: AppColors.gold,
            title: 'Crear mi primer hábito',
            subtitle: 'Objetivo, frecuencia y recordatorios.',
            doneLabel: createdHabitTitle != null
                ? 'Creado: $createdHabitTitle'
                : null,
            onTap: onCreateHabit,
          ),
          const SizedBox(height: 14),
          Text(
            'También puedes hacerlo luego desde «+».',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? doneLabel;
  final VoidCallback onTap;

  const _StepCard({
    required this.number,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.doneLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final done = doneLabel != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: done
              ? color.withValues(alpha: 0.10)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done ? color.withValues(alpha: 0.6) : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              alignment: Alignment.center,
              child: done
                  ? Icon(Icons.check_rounded, color: color, size: 24)
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number · $title',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    done ? doneLabel! : subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: done ? color : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              done ? Icons.replay_rounded : Icons.chevron_right_rounded,
              color: done ? color : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
