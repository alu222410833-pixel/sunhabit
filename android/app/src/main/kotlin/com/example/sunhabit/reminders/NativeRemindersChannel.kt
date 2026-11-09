package com.example.sunhabit.reminders

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Puente Dart ↔ motor nativo de recordatorios (`sunhabit/native_reminders`).
 *
 * Además del motor principal de la app, puede arrancar un motor de
 * Flutter en segundo plano (`nativeActionMain`) solo para aplicar las
 * acciones Sí/No pulsadas con la app cerrada.
 */
object NativeRemindersChannel {
    const val CHANNEL = "sunhabit/native_reminders"
    private const val TAG = "SunHabitReminders"
    private const val HEADLESS_TIMEOUT_MS = 9_000L

    private val mainHandler = Handler(Looper.getMainLooper())
    private var mainChannel: MethodChannel? = null
    private var launchAction: Map<String, String>? = null
    private var headlessEngine: FlutterEngine? = null
    private val headlessCallbacks = mutableListOf<() -> Unit>()
    private val headlessTimeout = Runnable { finishHeadless() }

    fun attachMain(context: Context, messenger: BinaryMessenger) {
        mainChannel = MethodChannel(messenger, CHANNEL).also {
            it.setMethodCallHandler(CallHandler(context.applicationContext))
        }
    }

    fun detachMain() {
        mainChannel?.setMethodCallHandler(null)
        mainChannel = null
    }

    fun setLaunchAction(action: String, habitId: String) {
        launchAction = mapOf("action" to action, "habitId" to habitId)
        mainChannel?.invokeMethod("launchActionAvailable", null)
    }

    fun deliverPendingActions(context: Context, onDone: () -> Unit) {
        mainHandler.post {
            val channel = mainChannel
            if (channel != null) {
                channel.invokeMethod("pendingActionsAvailable", null)
                onDone()
            } else {
                runHeadless(context.applicationContext, onDone)
            }
        }
    }

    private fun runHeadless(context: Context, onDone: () -> Unit) {
        headlessCallbacks += onDone
        if (headlessEngine != null) return
        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context)
            loader.ensureInitializationComplete(context, null)
            val engine = FlutterEngine(context)
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(CallHandler(context))
            headlessEngine = engine
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "nativeActionMain"),
            )
            mainHandler.postDelayed(headlessTimeout, HEADLESS_TIMEOUT_MS)
        } catch (e: Exception) {
            Log.e(TAG, "headless engine failed; actions stay queued", e)
            finishHeadless()
        }
    }

    private fun finishHeadless() {
        mainHandler.removeCallbacks(headlessTimeout)
        headlessEngine?.destroy()
        headlessEngine = null
        val callbacks = headlessCallbacks.toList()
        headlessCallbacks.clear()
        callbacks.forEach { runCatching { it() } }
    }

    private class CallHandler(private val context: Context) : MethodChannel.MethodCallHandler {
        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            try {
                when (call.method) {
                    "sync" -> {
                        val specs = ReminderSpec.listFromJson(call.argument<String>("specs") ?: "[]")
                        val keepSnoozes = call.argument<Boolean>("keepSnoozes") ?: true
                        result.success(ReminderScheduler.sync(context, specs, keepSnoozes))
                    }
                    "snooze" -> {
                        val spec = ReminderSpec.fromJson(JSONObject(call.argument<String>("spec")!!))
                        ReminderScheduler.snooze(context, spec, call.argument<Int>("minutes") ?: 10)
                        result.success(null)
                    }
                    "scheduledCount" -> result.success(ReminderScheduler.scheduledCount(context))
                    "takePendingActions" -> result.success(ReminderStore(context).takeActions())
                    "takeLaunchAction" -> {
                        result.success(launchAction)
                        launchAction = null
                    }
                    "headlessDone" -> {
                        result.success(null)
                        mainHandler.post { finishHeadless() }
                    }
                    "openAutoStartSettings" ->
                        result.success(ReminderActions.openAutoStartSettings(context))
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("native_reminders", e.message, null)
            }
        }
    }
}
