package com.example.sunhabit.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject

/** Botones de las notificaciones que no necesitan abrir la app. */
class ReminderActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val spec = intent.getStringExtra(EXTRA_SPEC)
            ?.let { ReminderSpec.fromJson(JSONObject(it)) }
            ?: return
        val notificationId = intent.getIntExtra(
            ReminderNotifications.EXTRA_NOTIFICATION_ID, spec.requestCode,
        )
        ReminderNotifications.cancel(context, notificationId)

        when (intent.action) {
            ACTION_YES, ACTION_NO -> {
                AlarmRingService.stop(context)
                val pending = goAsync()
                ReminderActions.quickAction(
                    context,
                    spec.habitId,
                    if (intent.action == ACTION_YES) "yes" else "no",
                ) { pending.finish() }
            }
            ACTION_SNOOZE -> {
                AlarmRingService.stop(context)
                ReminderScheduler.snooze(context, spec, SNOOZE_MINUTES)
            }
            ACTION_STOP_ALARM -> AlarmRingService.stop(context)
        }
    }

    companion object {
        const val ACTION_YES = "com.example.sunhabit.REMINDER_YES"
        const val ACTION_NO = "com.example.sunhabit.REMINDER_NO"
        const val ACTION_SNOOZE = "com.example.sunhabit.REMINDER_SNOOZE"
        const val ACTION_STOP_ALARM = "com.example.sunhabit.REMINDER_STOP_ALARM"
        const val EXTRA_SPEC = "spec"
        const val SNOOZE_MINUTES = 10
    }
}
