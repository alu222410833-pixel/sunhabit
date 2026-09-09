import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/backup_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  Future<void> _export(BuildContext context) async {
    try {
      final saved = await BackupService().export();
      if (!context.mounted) return;
      if (saved != null) {
        _showSnackBar(context, 'Backup guardado correctamente.');
      }
    } on BackupException catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Error al exportar: $e');
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final imported = await BackupService().import();
      if (!context.mounted) return;
      if (imported) {
        await HabitsRepository().reload();
        if (!context.mounted) return;
        _showSnackBar(context, 'Backup importado correctamente.');
      }
    } on BackupException catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Error al importar: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            children: [
              Text('Perfil', style: textTheme.displaySmall),
              const SizedBox(height: 28),
              _BackupSection(
                textTheme: textTheme,
                onExport: () => _export(context),
                onImport: () => _import(context),
              ),
              const SizedBox(height: 28),
              _SettingsTile(
                textTheme: textTheme,
                onTap: () => context.go(AppRouter.settings),
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
              _ProfileBottomNavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                textTheme: textTheme,
                onTap: () => AppRouter.goHome(context),
              ),
              _ProfileBottomNavItem(
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
              _ProfileBottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Utilidades',
                textTheme: textTheme,
                onTap: () => context.go(AppRouter.utilities),
              ),
              _ProfileBottomNavItem(
                icon: Icons.person_rounded,
                label: 'Perfil',
                textTheme: textTheme,
                active: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupSection extends StatelessWidget {
  final TextTheme textTheme;
  final VoidCallback onExport;
  final VoidCallback onImport;

  const _BackupSection({
    required this.textTheme,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tus datos', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.upload_rounded,
          title: 'Exportar hábitos',
          subtitle: 'Guarda una copia de seguridad en tu teléfono.',
          textTheme: textTheme,
          onTap: onExport,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.download_rounded,
          title: 'Importar hábitos',
          subtitle: 'Restaura una copia anterior.',
          textTheme: textTheme,
          onTap: onImport,
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.settings_outlined,
      title: 'Ajustes',
      subtitle: 'Configura la app a tu gusto',
      textTheme: textTheme,
      onTap: onTap,
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonGreen.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.neonGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.neonGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextTheme textTheme;
  final bool active;
  final VoidCallback? onTap;

  const _ProfileBottomNavItem({
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
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
