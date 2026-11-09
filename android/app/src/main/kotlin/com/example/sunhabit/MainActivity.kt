package com.example.sunhabit

import android.content.Intent
import com.example.sunhabit.reminders.NativeRemindersChannel
import com.example.sunhabit.reminders.ReminderActions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NativeRemindersChannel.attachMain(this, flutterEngine.dartExecutor.binaryMessenger)
        ReminderActions.consumeLaunchIntent(this, intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        NativeRemindersChannel.detachMain()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        ReminderActions.consumeLaunchIntent(this, intent)
    }
}
