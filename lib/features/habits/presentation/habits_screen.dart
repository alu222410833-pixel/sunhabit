import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/reminder_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/categories/presentation/categories_menu_sheet.dart';
import 'package:sunhabit/features/categories/presentation/create_category_dialog.dart';
import 'package:sunhabit/features/habits/presentation/create_habit/create_habit_dialog.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';
import 'package:sunhabit/features/habits/presentation/widgets/habit_visuals.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final HabitsRepository _repository = HabitsRepository();
  int _selectedPeriod = 0;

  List<Habit> get _habits => _repository.getHabits();

  List<bool> _weekFor(Habit habit) {
    final logs = _repository.getHabitLogs(habit.id);
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = DateTime(monday.year, monday.month, monday.day + i);
      return logs.any((l) =>
          l.date.year == day.year &&
          l.date.month == day.month &&
          l.date.day == day.day &&
          l.isCompleted);
    });
  }

  double get _periodProgress {
    if (_habits.isEmpty) return 0;
    if (_selectedPeriod == 0) {
      return _habits.where((habit) => habit.isCompleted).length /
          _habits.length;
    }
    if (_selectedPeriod == 2) return _monthProgress;
    final completedDays = <bool>[];
    for (var index = 0; index < _habits.length; index++) {
      completedDays.addAll(_weekFor(_habits[index]));
    }
    return completedDays.where((value) => value).length / completedDays.length;
  }

  /// Progreso del mes actual: días programados completados sobre el total de
  /// días programados del mes entero (los días futuros cuentan en el
  /// denominador).
  double get _monthProgress {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    var scheduled = 0;
    var completed = 0;
    for (final habit in _habits) {
      final logs = _repository.getHabitLogs(habit.id);
      for (var d = 1; d <= daysInMonth; d++) {
        final day = DateTime(now.year, now.month, d);
        if (!habit.isScheduledFor(day)) continue;
        scheduled++;
        final done = logs.any((l) =>
            l.date.year == day.year &&
            l.date.month == day.month &&
            l.date.day == day.day &&
            l.isCompleted);
        if (done) completed++;
      }
    }
    if (scheduled == 0) return 0;
    return completed / scheduled;
  }

  String get _progressDescription {
    final completed = _habits.where((habit) => habit.isCompleted).length;
    if (_selectedPeriod == 0) {
      return '$completed de ${_habits.length} hábitos completados';
    }
    if (_selectedPeriod == 1) return 'Progreso promedio de esta semana';
    return 'Progreso promedio de este mes';
  }

  Future<void> _openSearch() async {
    final habit = await showSearch<Habit?>(
      context: context,
      delegate: _HabitSearchDelegate(_habits),
    );
    if (!mounted || habit == null) return;
    AppRouter.goHabitDetail(context, habit.id);
  }

  Future<void> _openCreateMenu() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_task_rounded),
                  title: const Text('Crear hábito'),
                  subtitle: const Text('Añade una actividad a tu seguimiento.'),
                  onTap: () => Navigator.pop(context, 'habit'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Crear categoría'),
                  subtitle: const Text('Organiza tus hábitos por grupos.'),
                  onTap: () => Navigator.pop(context, 'category'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (selection == 'habit') await _showCreateHabitDialog();
    if (selection == 'category') await _showCreateCategoryDialog();
  }

  Future<void> _showCreateHabitDialog() async {
    final categories = _repository.getCategories();
    if (categories.isEmpty) return;

    final habit = await showDialog<Habit>(
      context: context,
      builder: (_) => CreateHabitDialog(categories: categories),
    );
    if (habit == null) return;
    _repository.addHabit(habit);
    await ReminderService.instance.scheduleHabit(habit);
  }

  Future<void> _showCreateCategoryDialog() async {
    final category = await showDialog<Category>(
      context: context,
      builder: (_) => const CreateCategoryDialog(),
    );
    if (category == null) return;
    _repository.addCategory(category);
  }

  Future<void> _openCategoriesMenu() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoriesMenuScreen(repository: _repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _repository,
            builder: (context, _) {
              final completed =
                  _habits.where((habit) => habit.isCompleted).length;
              final progress = _periodProgress;

              return ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _openCategoriesMenu,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Hábitos',
                                      style: textTheme.displayLarge),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.neonGreen,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '$completed de ${_habits.length}',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: AppColors.neonGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' completados hoy',
                                    style: textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _openSearch,
                        icon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.neonGreen,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PeriodSelector(
                    selected: _selectedPeriod,
                    onSelected: (index) {
                      setState(() => _selectedPeriod = index);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _selectedPeriod == 0
                        ? 'PROGRESO DE HOY'
                        : _selectedPeriod == 1
                        ? 'PROGRESO SEMANAL'
                        : 'PROGRESO MENSUAL',
                    style: textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: AppDecorations.card,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: AppColors.surfaceHighest,
                                  color: AppColors.neonGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Text(
                              '${(progress * 100).round()}%',
                              style: textTheme.displayMedium?.copyWith(
                                color: AppColors.neonGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _progressDescription,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MIS HÁBITOS',
                    style: textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._habits.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TrackingHabitCard(
                        habit: entry.value,
                        week: _weekFor(entry.value),
                        onTap: () =>
                            AppRouter.goHabitDetail(context, entry.value.id),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomNav(context, textTheme),
    );
  }

  Widget _buildBottomNav(BuildContext context, TextTheme textTheme) {
    return BottomAppBar(
      child: DecoratedBox(
        decoration: AppDecorations.bottomNavigation,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HabitBottomNavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                textTheme: textTheme,
                onTap: () => AppRouter.goHome(context),
              ),
              _HabitBottomNavItem(
                icon: Icons.task_alt_rounded,
                label: 'Hábitos',
                textTheme: textTheme,
                active: true,
              ),
              GestureDetector(
                onTap: _openCreateMenu,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: AppDecorations.centerAction,
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.neonGreen,
                    size: 30,
                  ),
                ),
              ),
              _HabitBottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Utilidades',
                textTheme: textTheme,
                onTap: () => context.go(AppRouter.utilities),
              ),
              _HabitBottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                textTheme: textTheme,
                onTap: () => context.go(AppRouter.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _PeriodSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const labels = ['Hoy', 'Semana', 'Mes'];
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                alignment: Alignment.center,
                decoration: active
                    ? BoxDecoration(
                        gradient: AppDecorations.neonGradient,
                        borderRadius: BorderRadius.circular(
                          AppConstants.cardRadius,
                        ),
                        boxShadow: AppDecorations.neonGlowSoft,
                      )
                    : null,
                child: Text(
                  labels[index],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: active
                        ? const Color(0xFF152000)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TrackingHabitCard extends StatelessWidget {
  final Habit habit;
  final List<bool> week;
  final VoidCallback onTap;

  const _TrackingHabitCard({
    required this.habit,
    required this.week,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final completedDays = week.where((day) => day).length;
    final percentage = completedDays / week.length;
    // Color principal custom del hábito (por usuario)
    final Color iconColor = habit.iconColor ?? (habit.id == '1' ? AppColors.water : AppColors.neonGreen);
    final imagePath = habit.effectiveImagePath;
    const dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    // --- NEÓN GLOW para hábito completado ---
    final bool isCompleted = habit.isCompleted;
    return Container(
      decoration: AppDecorations.habitCard.copyWith(
        border: Border.all(color: AppColors.borderDark, width: 1.2),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 14, 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                // Barra de color/glow en el borde izquierdo
                Container(
                  width: 6,
                  height: double.infinity,
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
                // Icono con GLOW más fuerte si está completado
                Container(
                  width: 54,
                  height: 54,
                  decoration: isCompleted
                      ? AppDecorations.iconGlow(iconColor)
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconColor.withValues(alpha:0.08),
                          border: Border.all(
                            color: iconColor.withValues(alpha:0.24),
                          ),
                          boxShadow: [
                            BoxShadow(color: iconColor.withValues(alpha:0.23), blurRadius: 7),
                          ],
                        ),
                  child: imagePath != null
                      ? HabitImageAvatar(imagePath: imagePath, size: 54)
                      : isCompleted
                          ? Icon(Icons.check_circle_rounded, color: iconColor, size: 36)
                          : Icon(habit.effectiveIcon, color: iconColor, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(habit.title, style: textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        habit.progressText ?? 'Sin progreso registrado',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.neonGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(week.length, (index) {
                          return Expanded(
                            child: Column(
                              children: [
                                Text(
                                  dayLabels[index],
                                  style: textTheme.labelSmall,
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: week[index]
                                        ? AppColors.neonGreen
                                        : AppColors.textMuted.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '$completedDays/7 días · '),
                              TextSpan(
                                text: '${(percentage * 100).round()}%',
                                style: const TextStyle(
                                  color: AppColors.neonGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),

              ],
            )),
          ),
        ),
      ),
    );
  }
}

class _HabitBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextTheme textTheme;
  final bool active;
  final VoidCallback? onTap;

  const _HabitBottomNavItem({
    required this.icon,
    required this.label,
    required this.textTheme,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.neonGreen : AppColors.textSecondary;
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: SizedBox(
        width: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: textTheme.labelSmall?.copyWith(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitSearchDelegate extends SearchDelegate<Habit?> {
  final List<Habit> habits;

  _HabitSearchDelegate(this.habits);

  List<Habit> get _results {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return habits;
    return habits.where((habit) {
      return habit.title.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  String get searchFieldLabel => 'Buscar hábitos';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear_rounded),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  bool get _isEveQuery => query.trim().toLowerCase() == 'eve';

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length + (_isEveQuery ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isEveQuery && index == 0) {
          return ListTile(
            leading: const Icon(Icons.favorite_border, color: AppColors.neonGreen),
            title: const Text('Eve is beautiful'),
            subtitle: const Text('Profile & Appreciation'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              close(context, null);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppRouter.router.go(AppRouter.eve);
              });
            },
          );
        }

        final habit = _results[index - (_isEveQuery ? 1 : 0)];
        return ListTile(
          leading: Icon(habit.icon, color: AppColors.neonGreen),
          title: Text(habit.title),
          subtitle: Text(habit.progressText ?? 'Sin progreso'),
          onTap: () => close(context, habit),
        );
      },
    );
  }
}
