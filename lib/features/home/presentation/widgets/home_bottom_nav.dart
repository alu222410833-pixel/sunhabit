import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

/// Barra de navegación inferior de la aplicación.
///
/// Contiene las pestañas Inicio, Hábitos, Utilidades y Perfil,
/// además de un botón central flotante para añadir hábitos.
class HomeBottomNavBar extends StatelessWidget {
  final TextTheme textTheme;
  final VoidCallback onAddTap;

  const HomeBottomNavBar({
    super.key,
    required this.textTheme,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: DecoratedBox(
        decoration: AppDecorations.bottomNavigation,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Inicio',
                active: true,
                textTheme: textTheme,
              ),
              _BottomNavItem(
                icon: Icons.task_alt_outlined,
                label: 'Hábitos',
                textTheme: textTheme,
                onTap: () => context.go(AppRouter.habits),
              ),
              GestureDetector(
                onTap: onAddTap,
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
              _BottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Utilidades',
                textTheme: textTheme,
                onTap: () => context.go(AppRouter.utilities),
              ),
              _BottomNavItem(
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

/// Item individual de la barra de navegación inferior.
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool active;
  final TextTheme textTheme;
  final VoidCallback? onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.textTheme,
    this.activeIcon,
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
        width: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon ?? icon : icon, color: color, size: 22),
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
