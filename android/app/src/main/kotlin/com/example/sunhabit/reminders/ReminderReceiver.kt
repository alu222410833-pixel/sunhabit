package com.example.sunhabit.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Recibe el disparo de `setAlarmClock()`.
 *
 * Todo ocurre en nativo: muestra la notificación o arranca la alarma y
 * reprograma la siguiente ocurrencia. No arranca el motor de Flutter.
 */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ReminderScheduler.ACTION_FIRE) return
        val key = intent.getStringExtra(ReminderScheduler.EXTRA_KEY) ?: return
        val store = ReminderStore(context)
        val spec = store.findSpec(key)
        Log.d("SunHabitReminders", "fire key=$key found=${spec != null}")
        if (spec != null) {
            try {
                if (spec.isAlarm) {
                    AlarmRingService.start(context, spec)
                } else {
                    ReminderNotifications.showReminder(context, spec)
                }
            } catch (e: Exception) {
                Log.e("SunHabitReminders", "error showing reminder, fallback to notification", e)
                ReminderNotifications.showReminder(context, spec)
            }
            if (spec.isSnooze) store.removeSpec(spec.key)
        }
        // Reprogramar todo (no solo este recordatorio) hace al motor
        // auto-reparable si el sistema descartó alguna alarma.
        ReminderScheduler.rescheduleAll(context)
    }
}
