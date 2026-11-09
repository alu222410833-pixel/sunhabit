package com.example.sunhabit.reminders

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Persistencia nativa de los recordatorios y de las acciones rápidas
 * pendientes de aplicar en Dart.
 *
 * Se usa un `SharedPreferences` propio (no el de Flutter) para que los
 * receptores puedan reprogramar tras un reinicio sin arrancar Flutter.
 */
class ReminderStore(context: Context) {
    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    @Synchronized
    fun loadSpecs(): List<ReminderSpec> {
        val json = prefs.getString(KEY_SPECS, null) ?: return emptyList()
        return try {
            ReminderSpec.listFromJson(json)
        } catch (_: Exception) {
            emptyList()
        }
    }

    @Synchronized
    fun saveSpecs(specs: Collection<ReminderSpec>) {
        prefs.edit().putString(KEY_SPECS, ReminderSpec.listToJson(specs)).commit()
    }

    fun findSpec(key: String): ReminderSpec? = loadSpecs().firstOrNull { it.key == key }

    @Synchronized
    fun upsertSpec(spec: ReminderSpec) {
        val specs = loadSpecs().filterNot { it.key == spec.key } + spec
        saveSpecs(specs)
    }

    @Synchronized
    fun removeSpec(key: String) {
        saveSpecs(loadSpecs().filterNot { it.key == key })
    }

    /** Encola una acción rápida (p. ej. "yes"/"no") para que Dart la aplique. */
    @Synchronized
    fun enqueueAction(habitId: String, action: String, epochDay: Long) {
        val arr = JSONArray(prefs.getString(KEY_ACTIONS, "[]"))
        arr.put(JSONObject().apply {
            put("habitId", habitId)
            put("action", action)
            put("epochDay", epochDay)
            put("timestamp", System.currentTimeMillis())
        })
        prefs.edit().putString(KEY_ACTIONS, arr.toString()).commit()
    }

    /** Devuelve y borra las acciones pendientes (JSON array). */
    @Synchronized
    fun takeActions(): String {
        val json = prefs.getString(KEY_ACTIONS, "[]") ?: "[]"
        prefs.edit().remove(KEY_ACTIONS).commit()
        return json
    }

    @Synchronized
    fun hasActions(): Boolean = (prefs.getString(KEY_ACTIONS, "[]") ?: "[]") != "[]"

    companion object {
        private const val PREFS_NAME = "sunhabit_native_reminders"
        private const val KEY_SPECS = "specs"
        private const val KEY_ACTIONS = "pending_actions"
    }
}
