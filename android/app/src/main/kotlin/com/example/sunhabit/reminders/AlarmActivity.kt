package com.example.sunhabit.reminders

import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Pantalla completa nativa de la alarma de un hábito. Se muestra sobre la
 * pantalla de bloqueo sin necesidad de arrancar Flutter.
 */
class AlarmActivity : Activity() {
    private lateinit var spec: ReminderSpec

    private val stoppedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val parsed = intent.getStringExtra(EXTRA_SPEC)
            ?.let { runCatching { ReminderSpec.fromJson(JSONObject(it)) }.getOrNull() }
            ?: AlarmRingService.currentSpec
        if (parsed == null) {
            finish()
            return
        }
        spec = parsed
        showOverLockScreen()
        setContentView(buildContent())
        ContextCompat.registerReceiver(
            this,
            stoppedReceiver,
            IntentFilter(AlarmRingService.BROADCAST_STOPPED),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    override fun onDestroy() {
        runCatching { unregisterReceiver(stoppedReceiver) }
        super.onDestroy()
    }

    @Suppress("DEPRECATION")
    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun buildContent(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(BACKGROUND)
            setPadding(dp(28), dp(48), dp(28), dp(32))
        }
        ReminderNotifications.loadLargeIcon(spec.imagePath, dp(132))?.let { bitmap ->
            root.addView(
                ImageView(this).apply { setImageBitmap(bitmap) },
                LinearLayout.LayoutParams(dp(132), dp(132)).apply { bottomMargin = dp(24) },
            )
        }
        root.addView(text(SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date()), 64f, NEON, bold = true))
        root.addView(text(spec.title, 26f, Color.WHITE, bold = true, top = 12))
        root.addView(text(spec.body, 16f, MUTED, top = 8))
        spec.whyPhrase?.let { root.addView(text("“$it”", 17f, GOLD, italic = true, top = 20)) }

        val buttons = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(40), 0, 0)
        }
        when (spec.evaluationType) {
            "yesNo" -> {
                buttons.addView(button("Sí, ya lo hice", primary = true) { quick("yes") })
                buttons.addView(button("No", primary = false) { quick("no") })
            }
            "timer" -> buttons.addView(button("Iniciar", primary = true) { open(ReminderNotifications.LAUNCH_START_TIMER) })
            else -> buttons.addView(button("Abrir", primary = true) { open(ReminderNotifications.LAUNCH_OPEN) })
        }
        buttons.addView(button("Posponer 10 min", primary = false) {
            ReminderScheduler.snooze(this, spec, ReminderActionReceiver.SNOOZE_MINUTES)
            stopAndFinish()
        })
        buttons.addView(button("Detener", primary = false) { stopAndFinish() })
        root.addView(buttons, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        return root
    }

    private fun quick(action: String) {
        ReminderActions.quickAction(this, spec.habitId, action) {}
        stopAndFinish()
    }

    private fun open(action: String) {
        AlarmRingService.stop(this)
        val launch = ReminderNotifications.launchAppIntent(
            this, spec.habitId, action, AlarmRingService.NOTIFICATION_ID, stopAlarm = true,
        )
        val km = getSystemService(KeyguardManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && km?.isKeyguardLocked == true) {
            km.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                override fun onDismissSucceeded() {
                    startActivity(launch)
                    finish()
                }
            })
        } else {
            startActivity(launch)
            finish()
        }
    }

    private fun stopAndFinish() {
        AlarmRingService.stop(this)
        finish()
    }

    private fun text(
        value: String,
        sizeSp: Float,
        color: Int,
        bold: Boolean = false,
        italic: Boolean = false,
        top: Int = 0,
    ) = TextView(this).apply {
        text = value
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
        setTextColor(color)
        gravity = Gravity.CENTER
        val style = when {
            bold && italic -> Typeface.BOLD_ITALIC
            bold -> Typeface.BOLD
            italic -> Typeface.ITALIC
            else -> Typeface.NORMAL
        }
        setTypeface(typeface, style)
        setPadding(0, dp(top), 0, 0)
    }

    private fun button(label: String, primary: Boolean, onClick: () -> Unit) = Button(this).apply {
        text = label
        isAllCaps = false
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
        setTextColor(if (primary) Color.BLACK else Color.WHITE)
        background = GradientDrawable().apply {
            cornerRadius = dp(28).toFloat()
            if (primary) setColor(NEON) else {
                setColor(SURFACE)
                setStroke(dp(1), OUTLINE)
            }
        }
        layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(56)).apply {
            topMargin = dp(12)
        }
        setOnClickListener { onClick() }
    }

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics).toInt()

    companion object {
        private const val EXTRA_SPEC = "spec"
        private const val BACKGROUND = 0xFF0E0E12.toInt()
        private const val SURFACE = 0xFF1C1C24.toInt()
        private const val OUTLINE = 0xFF3A3A46.toInt()
        private const val NEON = 0xFFB5FF00.toInt()
        private const val GOLD = 0xFFFFD928.toInt()
        private const val MUTED = 0xFFB0B0BC.toInt()

        fun intent(context: Context, spec: ReminderSpec): Intent =
            Intent(context, AlarmActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION)
                .putExtra(EXTRA_SPEC, spec.toJson().toString())
    }
}
