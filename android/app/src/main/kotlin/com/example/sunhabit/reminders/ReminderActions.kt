package com.example.sunhabit.reminders

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import java.time.LocalDate

/** Acciones compartidas por notificaciones, pantalla de alarma y `MainActivity`. */
object ReminderActions {
    /**
     * Encola una acción rápida (Sí/No) y la entrega a Dart: al motor
     * principal si la app está abierta o a un motor en segundo plano.
     * Si nada de eso funciona, la cola se aplica al abrir la app.
     */
    fun quickAction(context: Context, habitId: String, action: String, onDone: () -> Unit) {
        ReminderStore(context).enqueueAction(habitId, action, LocalDate.now().toEpochDay())
        NativeRemindersChannel.deliverPendingActions(context, onDone)
    }

    /** Procesa los extras de lanzamiento puestos por una notificación/alarma. */
    fun consumeLaunchIntent(context: Context, intent: Intent?) {
        intent ?: return
        val action = intent.getStringExtra(ReminderNotifications.EXTRA_LAUNCH_ACTION) ?: return
        val habitId = intent.getStringExtra(ReminderNotifications.EXTRA_HABIT_ID) ?: return
        val notificationId = intent.getIntExtra(ReminderNotifications.EXTRA_NOTIFICATION_ID, -1)
        if (notificationId != -1) ReminderNotifications.cancel(context, notificationId)
        if (intent.getBooleanExtra(ReminderNotifications.EXTRA_STOP_ALARM, false)) {
            AlarmRingService.stop(context)
        }
        intent.removeExtra(ReminderNotifications.EXTRA_LAUNCH_ACTION)
        NativeRemindersChannel.setLaunchAction(action, habitId)
    }

    /**
     * Abre la pantalla de inicio automático / apps protegidas del
     * fabricante (Huawei, Honor, Xiaomi...). Si no existe, abre los
     * detalles de la app en Ajustes.
     */
    fun openAutoStartSettings(context: Context): Boolean {
        val components = listOf(
            "com.hihonor.systemmanager" to "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            "com.huawei.systemmanager" to "com.huawei.systemmanager.optimize.process.ProtectActivity",
            "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
            "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
        )
        for ((pkg, cls) in components) {
            try {
                context.startActivity(
                    Intent().setComponent(ComponentName(pkg, cls)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                return true
            } catch (_: Exception) {
                // No existe o no es accesible en este fabricante.
            }
        }
        context.startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        return false
    }
}
