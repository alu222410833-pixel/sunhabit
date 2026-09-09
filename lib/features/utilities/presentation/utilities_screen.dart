import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final utilities = [
      _UtilityData(
        title: 'Temporizador',
        subtitle: 'Cuenta regresiva para tus actividades.',
        icon: Icons.timer_outlined,
        onTap: () => context.push(AppRouter.focus),
      ),
      _UtilityData(
        title: 'Cronómetro',
        subtitle: 'Mide el tiempo transcurrido.',
        icon: Icons.av_timer_rounded,
        onTap: () => context.push(AppRouter.stopwatch),
      ),
      _UtilityData(
        title: 'Intervalos',
        subtitle: 'Entrenamientos por intervalos de tiempo.',
        icon: Icons.bar_chart_rounded,
        onTap: () => context.push(AppRouter.intervals),
      ),
      _UtilityData(
        title: 'Modo cuidado visual',
        subtitle: 'Aplica la regla 20-20-20 y descansa tus ojos.',
        icon: Icons.visibility_outlined,
        onTap: () => context.push(AppRouter.eyeCare),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          child: Column(
            children: [
              _UtilitiesHeader(textTheme: textTheme),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  itemCount: utilities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _UtilityCard(data: utilities[index]);
                  },
                ),
              ),
            ],
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
              _UtilityBottomNavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                textTheme: textTheme,
                onTap: () => AppRouter.goHome(context),
              ),
              _UtilityBottomNavItem(
                icon: Icons.task_alt_outlined,
                label: 'Hábitos',
                textTheme: textTheme,
                onTap: () => context.go(AppRouter.habits),
              ),
              GestureDetector(
                onTap: () {},
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
              _UtilityBottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Utilidades',
                textTheme: textTheme,
                active: true,
              ),
              _UtilityBottomNavItem(
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

class _UtilitiesHeader extends StatelessWidget {
  final TextTheme textTheme;

  const _UtilitiesHeader({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(
            child: Column(
              children: [
                Text('Utilidades', style: textTheme.headlineSmall),
                const SizedBox(height: 5),
                Text(
                  'Herramientas para tu día a día',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _UtilityData {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _UtilityData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _UtilityCard extends StatelessWidget {
  final _UtilityData data;

  const _UtilityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 110,
      decoration: AppDecorations.habitCard,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonGreen.withValues(alpha: 0.24),
                        AppColors.neonGreen.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.neonGreen.withValues(alpha: 0.14),
                    ),
                    boxShadow: AppDecorations.neonGlowSoft,
                  ),
                  child: Icon(data.icon, color: AppColors.neonGreen, size: 38),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.title, style: textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.neonGreen,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UtilityBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextTheme textTheme;
  final bool active;
  final VoidCallback? onTap;

  const _UtilityBottomNavItem({
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
