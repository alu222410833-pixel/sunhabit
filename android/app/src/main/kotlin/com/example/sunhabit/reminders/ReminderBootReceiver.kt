package com.example.sunhabit.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Reprograma los recordatorios cuando el sistema borra o invalida las
 * alarmas: reinicio, actualización de la app, cambio de hora/zona horaria
 * o cambio del permiso de alarmas exactas.
 */
class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val count = ReminderScheduler.rescheduleAll(context)
        Log.d("SunHabitReminders", "rescheduled $count reminders after ${intent.action}")
    }
}
