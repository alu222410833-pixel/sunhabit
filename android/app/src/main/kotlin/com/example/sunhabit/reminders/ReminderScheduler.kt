package com.example.sunhabit.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import com.example.sunhabit.MainActivity
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/**
 * Programa los recordatorios con `AlarmManager.setAlarmClock()`.
 *
 * Cada [ReminderSpec] tiene como máximo UNA alarma pendiente en el sistema
 * (su siguiente ocurrencia). Al dispararse, [ReminderReceiver] llama a
 * [rescheduleAll], que vuelve a calcular la siguiente ocurrencia de todos
 * los recordatorios sin depender de Flutter.
 */
object ReminderScheduler {
    private const val TAG = "SunHabitReminders"
    const val ACTION_FIRE = "com.example.sunhabit.REMINDER_FIRE"
    const val EXTRA_KEY = "key"
    const val EXTRA_TRIGGER = "trigger"

    /** Reemplaza el conjunto completo de recordatorios enviado por Flutter. */
    @Synchronized
    fun sync(context: Context, newSpecs: List<ReminderSpec>, keepSnoozes: Boolean): Int {
        val store = ReminderStore(context)
        val old = store.loadSpecs()
        val now = System.currentTimeMillis()
        val habitIds = newSpecs.map { it.habitId }.toSet()
        val snoozes = if (keepSnoozes) {
            old.filter { it.isSnooze && (it.atMillis ?: 0) > now && it.habitId in habitIds }
        } else {
            emptyList()
        }
        val merged = (newSpecs.filterNot { it.isSnooze } + snoozes).associateBy { it.key }
        old.filter { it.key !in merged }.forEach { cancel(context, it) }
        store.saveSpecs(merged.values)
        return scheduleAllInternal(context, merged.values.toList())
    }

    /** Recalcula y programa la siguiente ocurrencia de todos los recordatorios. */
    @Synchronized
    fun rescheduleAll(context: Context): Int {
        val store = ReminderStore(context)
        val now = System.currentTimeMillis()
        val specs = store.loadSpecs()
        val expired = specs.filter { it.isSnooze && (it.atMillis ?: 0) <= now }
        if (expired.isNotEmpty()) {
            store.saveSpecs(specs - expired.toSet())
        }
        return scheduleAllInternal(context, specs - expired.toSet())
    }

    /** Programa un recordatorio único dentro de [minutes] minutos. */
    @Synchronized
    fun snooze(context: Context, base: ReminderSpec, minutes: Int) {
        val snooze = base.copy(
            key = "snooze_${base.habitId}",
            atMillis = System.currentTimeMillis() + minutes * 60_000L,
            dates = null,
        )
        ReminderStore(context).upsertSpec(snooze)
        schedule(context, snooze)
    }

    fun scheduledCount(context: Context): Int {
        val now = System.currentTimeMillis()
        return ReminderStore(context).loadSpecs().count { nextTrigger(it, now) != null }
    }

    private fun scheduleAllInternal(context: Context, specs: List<ReminderSpec>): Int {
        var count = 0
        for (spec in specs) {
            if (schedule(context, spec)) count++
        }
        Log.d(TAG, "scheduled $count/${specs.size} reminders")
        return count
    }

    private fun schedule(context: Context, spec: ReminderSpec): Boolean {
        val trigger = nextTrigger(spec, System.currentTimeMillis())
        if (trigger == null) {
            cancel(context, spec)
            return false
        }
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val operation = firePendingIntent(context, spec, trigger)
        try {
            val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                alarmManager.canScheduleExactAlarms()
            if (canExact) {
                val showIntent = PendingIntent.getActivity(
                    context,
                    spec.requestCode,
                    Intent(context, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                alarmManager.setAlarmClock(AlarmManager.AlarmClockInfo(trigger, showIntent), operation)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, operation)
            }
            return true
        } catch (e: SecurityException) {
            Log.w(TAG, "exact alarm denied, falling back to inexact", e)
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, operation)
            return true
        }
    }

    fun cancel(context: Context, spec: ReminderSpec) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = PendingIntent.getBroadcast(
            context,
            spec.requestCode,
            fireIntent(context, spec, 0L),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        alarmManager.cancel(pi)
        pi.cancel()
    }

    private fun fireIntent(context: Context, spec: ReminderSpec, trigger: Long): Intent =
        Intent(context, ReminderReceiver::class.java)
            .setAction(ACTION_FIRE)
            // El URI hace único al PendingIntent por recordatorio aunque
            // dos claves colisionen en `requestCode`.
            .setData(Uri.parse("sunhabit://reminder/${Uri.encode(spec.key)}"))
            .putExtra(EXTRA_KEY, spec.key)
            .putExtra(EXTRA_TRIGGER, trigger)

    private fun firePendingIntent(context: Context, spec: ReminderSpec, trigger: Long): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            spec.requestCode,
            fireIntent(context, spec, trigger),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /**
     * Siguiente instante (ms) estrictamente posterior a [afterMillis] en que
     * debe sonar [spec], o `null` si ya no tiene más ocurrencias.
     */
    fun nextTrigger(spec: ReminderSpec, afterMillis: Long): Long? {
        spec.atMillis?.let { return if (it > afterMillis) it else null }
        val zone = ZoneId.systemDefault()
        val after = Instant.ofEpochMilli(afterMillis)

        fun at(day: LocalDate): Long? {
            val instant = day.atTime(spec.hour, spec.minute).atZone(zone).toInstant()
            return if (instant.isAfter(after)) instant.toEpochMilli() else null
        }

        val dates = spec.dates
        if (dates != null) {
            return dates.sorted().firstNotNullOfOrNull { at(LocalDate.ofEpochDay(it)) }
        }

        if (spec.weekdays and 0x7F == 0) return null
        val today = after.atZone(zone).toLocalDate()
        val startDay = spec.startEpochDay?.let { LocalDate.ofEpochDay(it) }
        val endDay = spec.endEpochDay?.let { LocalDate.ofEpochDay(it) }
        var day = if (startDay != null && startDay.isAfter(today)) startDay else today
        repeat(8) {
            if (endDay != null && day.isAfter(endDay)) return null
            val bit = 1 shl (day.dayOfWeek.value - 1)
            if (spec.weekdays and bit != 0) {
                at(day)?.let { return it }
            }
            day = day.plusDays(1)
        }
        return null
    }
}
