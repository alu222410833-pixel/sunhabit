import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/navigation/app_router.dart';
import 'package:sunhabit/core/services/alarm_service.dart';
import 'package:sunhabit/core/services/notification_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exactAlarmsAllowed = true;
  bool _batteryOptIgnored = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsStatus();
  }

  Future<void> _checkPermissionsStatus() async {
    if (!Platform.isAndroid) return;
    final canExact = await NotificationService.canScheduleExactAlarms();
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (mounted) {
      setState(() {
        _exactAlarmsAllowed = canExact;
        _batteryOptIgnored = batteryStatus.isGranted;
      });
    }
  }

  Future<void> _requestBatteryExemption(BuildContext context) async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Optimización de batería desactivada correctamente.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await openAppSettings();
    }
    await _checkPermissionsStatus();
  }

  Future<void> _runAlarmAndNotificationTest(BuildContext context) async {
    await NotificationService.requestPermissions();

    // Programar una alarma de prueba que suene dentro de 5 segundos con fade-in.
    AlarmService.instance.setUtilityAlarm(
      durationSeconds: 5,
      title: 'Prueba de alarma',
    );

    // Mostrar inmediatamente una notificación de prueba.
    await NotificationService.showTestNotification();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Prueba enviada: revisa la notificación y la alarma en 5 segundos.',
        ),
        backgroundColor: AppColors.surfaceHighest,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showOemGuideDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: const Text('Guía de fiabilidad por marca'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOemSection(
                'Honor / Huawei (MagicUI / EMUI)',
                '1. Ajustes → Batería → Inicio de aplicaciones.\n'
                '2. Busca SunHabit y desactiva "Gestionar automáticamente".\n'
                '3. Activa: Inicio automático, Inicio secundario y Ejecutar en segundo plano.',
              ),
              const Divider(color: AppColors.borderDark),
              _buildOemSection(
                'Xiaomi / Redmi / POCO (MIUI / HyperOS)',
                '1. Ajustes → Aplicaciones → Administrar aplicaciones → SunHabit.\n'
                '2. Activa "Inicio automático".\n'
                '3. En Ahorro de batería, selecciona "Sin restricciones".',
              ),
              const Divider(color: AppColors.borderDark),
              _buildOemSection(
                'Samsung (One UI)',
                '1. Ajustes → Aplicaciones → SunHabit → Batería.\n'
                '2. Selecciona "No restringido".',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Entendido',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOemSection(String title, String steps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.neonGreen,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            steps,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            children: [
              Text('Alarmas y Notificaciones', style: textTheme.titleMedium),
              const SizedBox(height: 12),

              // Tarjeta de prueba
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
                        vertical: 16,
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
                                  'Envía una notificación ahora y una alarma en 5s',
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

              const SizedBox(height: 24),
              Text('Optimización de Batería y Permisos', style: textTheme.titleMedium),
              const SizedBox(height: 12),

              // Tarjeta de estado de batería
              Container(
                decoration: AppDecorations.card,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _batteryOptIgnored
                              ? Icons.battery_charging_full_rounded
                              : Icons.battery_alert_rounded,
                          color: _batteryOptIgnored
                              ? AppColors.neonGreen
                              : AppColors.fire,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ahorro de batería del sistema',
                                style: textTheme.titleMedium,
                              ),
                              Text(
                                _batteryOptIgnored
                                    ? 'Sin restricciones (Máxima puntualidad)'
                                    : 'Optimizado por el sistema (Puede retrasar avisos)',
                                style: textTheme.bodySmall?.copyWith(
                                  color: _batteryOptIgnored
                                      ? AppColors.neonGreen
                                      : AppColors.fire,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!_exactAlarmsAllowed) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.alarm_off_rounded,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Alarmas exactas restringidas por el sistema.',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _requestBatteryExemption(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.neonGreen,
                              side: const BorderSide(color: AppColors.neonGreen),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Sin restricciones'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showOemGuideDialog(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderDark),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Guía de marcas'),
                          ),
                        ),
                      ],
                    ),
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
