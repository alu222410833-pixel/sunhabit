package com.example.sunhabit.reminders

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Shader
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.sunhabit.MainActivity
import com.example.sunhabit.R
import java.io.File

/** Canales, notificaciones y `PendingIntent` de los recordatorios nativos. */
object ReminderNotifications {
    const val CHANNEL_REMINDERS = "sunhabit_native_reminders"
    const val CHANNEL_ALARM = "sunhabit_native_alarm"
    const val ACCENT_COLOR = 0xFF58B800.toInt()

    const val EXTRA_LAUNCH_ACTION = "sunhabit_launch_action"
    const val EXTRA_HABIT_ID = "sunhabit_habit_id"
    const val EXTRA_NOTIFICATION_ID = "sunhabit_notification_id"
    const val EXTRA_STOP_ALARM = "sunhabit_stop_alarm"
    const val LAUNCH_OPEN = "open"
    const val LAUNCH_START_TIMER = "start_timer"

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_REMINDERS,
                "Recordatorios de hábitos",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Recordatorios programados de tus hábitos"
                enableVibration(true)
                enableLights(true)
                lightColor = ACCENT_COLOR
            },
        )
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ALARM,
                "Alarmas de hábitos",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alarmas de pantalla completa (el sonido lo reproduce la app)"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            },
        )
    }

    /** Muestra el recordatorio tipo 'Notificación' con sus acciones rápidas. */
    fun showReminder(context: Context, spec: ReminderSpec) {
        ensureChannels(context)
        val id = spec.requestCode
        val builder = NotificationCompat.Builder(context, CHANNEL_REMINDERS)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(spec.title)
            .setContentText(spec.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(spec.body))
            .setColor(ACCENT_COLOR)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setShowWhen(true)
            .setContentIntent(launchIntent(context, spec, LAUNCH_OPEN, id, stopAlarm = false))
        loadLargeIcon(spec.imagePath)?.let { builder.setLargeIcon(it) }
        addHabitActions(context, builder, spec, id, stopAlarm = false)
        builder.addAction(0, "Posponer 10 min", actionIntent(context, spec, ReminderActionReceiver.ACTION_SNOOZE, id))
        notify(context, id, builder.build())
    }

    /** Notificación del servicio de alarma con intent de pantalla completa. */
    fun buildAlarmNotification(context: Context, spec: ReminderSpec, id: Int): Notification {
        ensureChannels(context)
        val fullScreen = PendingIntent.getActivity(
            context,
            id,
            AlarmActivity.intent(context, spec),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = NotificationCompat.Builder(context, CHANNEL_ALARM)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(spec.title)
            .setContentText(spec.body)
            .setColor(ACCENT_COLOR)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSilent(true)
            .setContentIntent(fullScreen)
            .setFullScreenIntent(fullScreen, true)
        loadLargeIcon(spec.imagePath)?.let { builder.setLargeIcon(it) }
        addHabitActions(context, builder, spec, id, stopAlarm = true)
        builder.addAction(0, "Posponer 10 min", actionIntent(context, spec, ReminderActionReceiver.ACTION_SNOOZE, id))
        builder.addAction(0, "Detener", actionIntent(context, spec, ReminderActionReceiver.ACTION_STOP_ALARM, id))
        return builder.build()
    }

    private fun addHabitActions(
        context: Context,
        builder: NotificationCompat.Builder,
        spec: ReminderSpec,
        id: Int,
        stopAlarm: Boolean,
    ) {
        when (spec.evaluationType) {
            "yesNo" -> {
                builder.addAction(0, "Sí", actionIntent(context, spec, ReminderActionReceiver.ACTION_YES, id))
                if (!stopAlarm) {
                    builder.addAction(0, "No", actionIntent(context, spec, ReminderActionReceiver.ACTION_NO, id))
                }
            }
            "timer" -> builder.addAction(
                0, "Iniciar", launchIntent(context, spec, LAUNCH_START_TIMER, id, stopAlarm),
            )
            "checklist" -> builder.addAction(
                0, "Ver lista", launchIntent(context, spec, LAUNCH_OPEN, id, stopAlarm),
            )
            else -> builder.addAction(
                0, "Abrir", launchIntent(context, spec, LAUNCH_OPEN, id, stopAlarm),
            )
        }
    }

    fun launchAppIntent(
        context: Context,
        habitId: String,
        action: String,
        notificationId: Int,
        stopAlarm: Boolean,
    ): Intent = Intent(context, MainActivity::class.java)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        .setData(Uri.parse("sunhabit://launch/$action/${Uri.encode(habitId)}/$notificationId"))
        .putExtra(EXTRA_LAUNCH_ACTION, action)
        .putExtra(EXTRA_HABIT_ID, habitId)
        .putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        .putExtra(EXTRA_STOP_ALARM, stopAlarm)

    private fun launchIntent(
        context: Context,
        spec: ReminderSpec,
        action: String,
        id: Int,
        stopAlarm: Boolean,
    ): PendingIntent = PendingIntent.getActivity(
        context,
        id,
        launchAppIntent(context, spec.habitId, action, id, stopAlarm),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun actionIntent(context: Context, spec: ReminderSpec, action: String, id: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, ReminderActionReceiver::class.java)
                .setAction(action)
                .setData(Uri.parse("sunhabit://action/${Uri.encode(spec.key)}/$id"))
                .putExtra(ReminderActionReceiver.EXTRA_SPEC, spec.toJson().toString())
                .putExtra(EXTRA_NOTIFICATION_ID, id),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun notify(context: Context, id: Int, notification: Notification) {
        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (_: SecurityException) {
            // Sin permiso POST_NOTIFICATIONS: no hay nada que mostrar.
        }
    }

    fun cancel(context: Context, id: Int) {
        NotificationManagerCompat.from(context).cancel(id)
    }

    /** Carga la imagen del hábito recortada en círculo (o `null`). */
    fun loadLargeIcon(path: String?, sizePx: Int = 192): Bitmap? {
        if (path.isNullOrEmpty() || !File(path).exists()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= sizePx && bounds.outHeight / (sample * 2) >= sizePx) {
                sample *= 2
            }
            val src = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
                ?: return null
            val side = minOf(src.width, src.height)
            val square = Bitmap.createBitmap(src, (src.width - side) / 2, (src.height - side) / 2, side, side)
            val scaled = Bitmap.createScaledBitmap(square, sizePx, sizePx, true)
            val out = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = BitmapShader(scaled, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
            }
            Canvas(out).drawCircle(sizePx / 2f, sizePx / 2f, sizePx / 2f, paint)
            out
        } catch (_: Exception) {
            null
        }
    }
}
