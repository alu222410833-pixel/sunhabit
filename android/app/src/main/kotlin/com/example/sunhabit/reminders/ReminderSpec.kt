package com.example.sunhabit.reminders

import org.json.JSONArray
import org.json.JSONObject

/**
 * Recordatorio de un hábito tal como lo programa el motor nativo.
 *
 * Flutter envía la lista completa con [NativeRemindersChannel] y el motor
 * calcula por sí mismo la siguiente ocurrencia, así que las alarmas se
 * siguen reprogramando aunque la app (o el motor de Flutter) no se abra.
 *
 * Modos de recurrencia (excluyentes):
 * - [atMillis]: disparo único (posponer).
 * - [dates]: lista explícita de días (epoch day) para frecuencias que no
 *   dependen solo del día de la semana (mensual, anual, "Repetir"...).
 * - [weekdays]: máscara semanal (bit 0 = lunes ... bit 6 = domingo).
 */
data class ReminderSpec(
    val key: String,
    val habitId: String,
    val habitTitle: String,
    val kind: String,
    val evaluationType: String,
    val hour: Int,
    val minute: Int,
    val weekdays: Int,
    val startEpochDay: Long?,
    val endEpochDay: Long?,
    val dates: List<Long>?,
    val atMillis: Long?,
    val title: String,
    val body: String,
    val soundPath: String?,
    val imagePath: String?,
    val whyPhrase: String?,
) {
    val isAlarm: Boolean get() = kind == KIND_ALARM
    val isSnooze: Boolean get() = atMillis != null

    /** ID estable para `PendingIntent` y notificaciones. */
    val requestCode: Int get() = fnv1a(key) and 0x7FFFFFFF

    fun toJson(): JSONObject = JSONObject().apply {
        put("key", key)
        put("habitId", habitId)
        put("habitTitle", habitTitle)
        put("kind", kind)
        put("evaluationType", evaluationType)
        put("hour", hour)
        put("minute", minute)
        put("weekdays", weekdays)
        putOpt("startEpochDay", startEpochDay)
        putOpt("endEpochDay", endEpochDay)
        dates?.let { put("dates", JSONArray(it)) }
        putOpt("atMillis", atMillis)
        put("title", title)
        put("body", body)
        putOpt("soundPath", soundPath)
        putOpt("imagePath", imagePath)
        putOpt("whyPhrase", whyPhrase)
    }

    companion object {
        const val KIND_ALARM = "alarm"
        const val KIND_NOTIFICATION = "notification"

        fun fromJson(o: JSONObject): ReminderSpec {
            val datesJson = o.optJSONArray("dates")
            val dates = datesJson?.let { arr -> List(arr.length()) { arr.getLong(it) } }
            return ReminderSpec(
                key = o.getString("key"),
                habitId = o.getString("habitId"),
                habitTitle = o.optString("habitTitle", ""),
                kind = o.optString("kind", KIND_NOTIFICATION),
                evaluationType = o.optString("evaluationType", "yesNo"),
                hour = o.optInt("hour", 0),
                minute = o.optInt("minute", 0),
                weekdays = o.optInt("weekdays", 0x7F),
                startEpochDay = o.optLongOrNull("startEpochDay"),
                endEpochDay = o.optLongOrNull("endEpochDay"),
                dates = dates,
                atMillis = o.optLongOrNull("atMillis"),
                title = o.optString("title", ""),
                body = o.optString("body", ""),
                soundPath = o.optStringOrNull("soundPath"),
                imagePath = o.optStringOrNull("imagePath"),
                whyPhrase = o.optStringOrNull("whyPhrase"),
            )
        }

        fun listFromJson(json: String): List<ReminderSpec> {
            val arr = JSONArray(json)
            return List(arr.length()) { fromJson(arr.getJSONObject(it)) }
        }

        fun listToJson(specs: Collection<ReminderSpec>): String =
            JSONArray().apply { specs.forEach { put(it.toJson()) } }.toString()

        /** Mismo FNV-1a de 32 bits que `stableHash` en Dart. */
        fun fnv1a(input: String): Int {
            var hash = 0x811c9dc5.toInt()
            for (ch in input) {
                hash = hash xor ch.code
                hash *= 0x01000193
            }
            return hash
        }

        private fun JSONObject.optLongOrNull(name: String): Long? =
            if (has(name) && !isNull(name)) getLong(name) else null

        private fun JSONObject.optStringOrNull(name: String): String? =
            if (has(name) && !isNull(name)) getString(name).ifEmpty { null } else null
    }
}
