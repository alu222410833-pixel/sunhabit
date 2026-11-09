package com.example.sunhabit.reminders

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.io.File

/**
 * Servicio en primer plano que hace sonar una alarma de hábito: audio en
 * bucle con subida gradual de volumen, vibración y notificación con
 * intent de pantalla completa ([AlarmActivity]).
 */
class AlarmRingService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var volume = 0f

    private val fadeStep = object : Runnable {
        override fun run() {
            volume = (volume + FADE_STEP).coerceAtMost(1f)
            player?.setVolume(volume, volume)
            if (volume < 1f) handler.postDelayed(this, FADE_INTERVAL_MS)
        }
    }
    private val autoStop = Runnable { stopSelf() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val spec = intent?.getStringExtra(EXTRA_SPEC)
            ?.let { runCatching { ReminderSpec.fromJson(JSONObject(it)) }.getOrNull() }
        if (spec == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        val notification = ReminderNotifications.buildAlarmNotification(this, spec, NOTIFICATION_ID)
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            notification,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            } else {
                0
            },
        )
        currentSpec = spec
        stopPlayback()
        acquireWakeLock()
        startPlayback(spec.soundPath)
        startVibration()
        handler.postDelayed(autoStop, MAX_RING_MS)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopPlayback()
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        currentSpec = null
        sendBroadcast(Intent(BROADCAST_STOPPED).setPackage(packageName))
        super.onDestroy()
    }

    private fun startPlayback(soundPath: String?) {
        val candidates = listOfNotNull(resolveSound(soundPath)) + defaultAlarmUris()
        for (source in candidates) {
            try {
                val mp = MediaPlayer()
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                when (source) {
                    is File -> mp.setDataSource(source.absolutePath)
                    is Uri -> mp.setDataSource(this, source)
                }
                mp.isLooping = true
                volume = FADE_START
                mp.setVolume(volume, volume)
                mp.prepare()
                mp.start()
                player = mp
                handler.postDelayed(fadeStep, FADE_INTERVAL_MS)
                return
            } catch (e: Exception) {
                Log.w("SunHabitReminders", "cannot play $source", e)
            }
        }
    }

    /** Archivo del usuario, asset de Flutter (`assets/...`) o `null`. */
    private fun resolveSound(path: String?): File? {
        if (path.isNullOrEmpty()) return null
        val file = File(path)
        if (file.exists() && file.length() > 0) return file
        if (path.startsWith("assets/")) {
            return try {
                val out = File(cacheDir, "alarm_" + path.replace('/', '_'))
                if (!out.exists()) {
                    assets.open("flutter_assets/$path").use { input ->
                        out.outputStream().use { input.copyTo(it) }
                    }
                }
                out
            } catch (_: Exception) {
                null
            }
        }
        return null
    }

    private fun defaultAlarmUris(): List<Uri> = listOfNotNull(
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
    )

    @Suppress("DEPRECATION")
    private fun startVibration() {
        val vib = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        } ?: return
        val attrs = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vib.vibrate(VibrationEffect.createWaveform(VIBRATION_PATTERN, 0), attrs)
        } else {
            vib.vibrate(VIBRATION_PATTERN, 0, attrs)
        }
        vibrator = vib
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "SunHabit:AlarmRing").apply {
            acquire(MAX_RING_MS + 5_000)
        }
    }

    private fun stopPlayback() {
        handler.removeCallbacks(fadeStep)
        handler.removeCallbacks(autoStop)
        player?.let {
            runCatching { it.stop() }
            it.release()
        }
        player = null
        vibrator?.cancel()
        vibrator = null
    }

    companion object {
        const val NOTIFICATION_ID = 0x5A1A
        const val EXTRA_SPEC = "spec"
        const val BROADCAST_STOPPED = "com.example.sunhabit.ALARM_STOPPED"
        private const val MAX_RING_MS = 10 * 60_000L
        private const val FADE_START = 0.1f
        private const val FADE_INTERVAL_MS = 500L
        private const val FADE_STEP = 0.03f // ~15 s hasta volumen máximo
        private val VIBRATION_PATTERN = longArrayOf(0, 800, 600)

        @Volatile
        var currentSpec: ReminderSpec? = null
            private set

        fun start(context: Context, spec: ReminderSpec) {
            ContextCompat.startForegroundService(
                context,
                Intent(context, AlarmRingService::class.java)
                    .putExtra(EXTRA_SPEC, spec.toJson().toString()),
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, AlarmRingService::class.java))
        }
    }
}
