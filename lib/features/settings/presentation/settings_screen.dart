import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _runAlarmAndNotificationTest(BuildContext context) async {
    await NotificationService.requestPermissions();

    // Programar una alarma de prueba que suene dentro de 5 segundos.
    AlarmService.instance.setUtilityAlarm(
      durationSeconds: 5,
      title: 'Prueba de alarma',
    );

    // Mostrar inmediatamente una notificación de prueba.
    await NotificationService.showTestNotification();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Prueba enviada: revisa la notificación y la alarma en 5 segundos.'),
        backgroundColor: AppColors.surfaceHighest,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ajustes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRouter.profile),
        ),
      ),
      body: DecoratedBox(
        decoration: AppDecorations.pageBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('General', style: textTheme.titleMedium),
                const SizedBox(height: 12),
                Container(
                  decoration: AppDecorations.card,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                      onTap: () => _runAlarmAndNotificationTest(context),
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
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                color: AppColors.neonGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Probar alarmas y notificaciones',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Envía una notificación ahora y una alarma en 5 segundos',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
