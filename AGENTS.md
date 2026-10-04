# SunHabit - Aprendizajes del proyecto

## Notificaciones y alarmas en dispositivos Huawei/Honor (2026-08-30)

### Problema
Las notificaciones programadas con `flutter_local_notifications` no sonaban en un
dispositivo Honor JDY-LX3 (MagicUI), aunque los permisos estaban concedidos y las
notificaciones se programaban correctamente (confirmado con logs).

### Causa
Huawei/Honor/Xiaomi tienen una optimización de batería muy agresiva que bloquea
las alarmas exactas (`AlarmManager.setExactAndAllowWhileIdle`) usadas por
`flutter_local_notifications`. Sin embargo, **NO bloquean**
`AlarmManager.setAlarmClock()` (el mecanismo del despertador del sistema), que es
el que usa el paquete `alarm`.

### Solución
Usar el paquete `alarm` para **ambos** tipos de recordatorio:
- **Notificación**: `alarm` con `loopAudio: false`, `vibrate: false`,
  `androidFullScreenIntent: false`, `assetAudioPath: null`.
- **Alarma**: `alarm` con `loopAudio: true`, `vibrate: true`,
  `androidFullScreenIntent: true`, `assetAudioPath: <sonido>`.

### Por qué otras apps no tienen este problema
1. Apps populares (WhatsApp, Telegram) están en listas blanc del fabricante.
2. Apps con servidor usan FCM (Firebase Cloud Messaging) que pasa el Doze mode.
3. `setAlarmClock()` se trata como alarma de despertador del usuario y no se
   bloquea, a diferencia de `setExactAndAllowWhileIdle`.

### Archivos relevantes
- `lib/core/services/alarm_service.dart` - Servicio de alarmas (paquete `alarm`).
- `lib/core/services/notification_service.dart` - Notificaciones del temporizador.
- `lib/core/services/reminder_service.dart` - Coordinador de recordatorios.
- `android/app/src/main/AndroidManifest.xml` - Permisos.

---

## Estructura de servicios (2026-08-30)

Se separó el código en tres servicios con responsabilidades claras:

- **`AlarmService`**: Todo lo relacionado con el paquete `alarm` (alarmas de
  hábitos, notificaciones de hábitos, alarmas de utilidad).
- **`NotificationService`**: Notificaciones locales con
  `flutter_local_notifications` (solo para la notificación persistente del
  temporizador en ejecución).
- **`ReminderService`**: Coordinador que decide a qué servicio delegar según
  `reminder.type` ('Alarma' o 'Notificación').

---

## Reset diario de hábitos (2026-08-30)

El estado de completado de los hábitos (`isCompleted`, `current`,
`completedChecklist`) se resetea diariamente. Esto ocurre:
- Al arrancar la app (`main.dart`).
- Al volver de background (`app.dart` → `didChangeAppLifecycleState`).
- Cada 60 segundos mientras la app está en foreground (`app.dart` → Timer).

Método: `HabitsRepository().checkDayChange()`.

---

## Inyección de dependencias en `HabitsRepository` (2026-08-30)

### Problema
`HabitsRepository` era un singleton con `StorageService` instanciado dentro del
mismo archivo. Eso dificultaba los tests unitarios porque no se podían crear
instancias aisladas ni usar un almacenamiento en memoria.

### Solución
Se mantuvo el singleton `HabitsRepository()` para la app, pero el
`StorageService` se recibe por constructor. Se añadió `HabitsRepository.test()`
para inyectar un `StorageService` concreto y `HabitsRepository.resetInstance()`
para limpiar la instancia singleton si es necesario.

### Archivos relevantes
- `lib/features/habits/data/habits_repository.dart` - Repositorio de hábitos.
- `test/helpers/fake_storage_service.dart` - Implementación en memoria para tests.
- `test/features/habits/data/habits_repository_test.dart` - Tests con instancias
  aisladas.

---

## Notificaciones nativas: diseño enriquecido vs. fiabilidad (2026-08-31)

### Problema
Se quiere mejorar el diseño visual de las notificaciones del sistema
(icono grande circular, color de acento, varias acciones, LED, vibración
personalizada). El paquete `alarm` (necesario para evitar bloqueos en
Huawei/Honor/Xiaomi) solo permite configurar título, cuerpo y el botón
`stopButton`. No expone `largeIcon`, `color`, `ledColor`, `vibrationPattern`
ni múltiples acciones.

### Limitación técnica
`flutter_local_notifications` sí soporta todo ese diseño, pero usa
`AlarmManager.setExactAndAllowWhileIdle`, que es bloqueado por la agresiva
optimización de batería de Huawei/Honor/Xiaomi. Volver a ese paquete para
recordatorios de hábitos reintroduciría el problema que ya se resolvió.

### Solución temporal
Usar el paquete `alarm` y mejorar solo lo que permite: título, cuerpo y
texto del botón. Ver `lib/core/services/alarm_service.dart`.

### Posibles soluciones futuras a investigar
1. **Canales de notificación por categoría**: usar `NotificationChannel`
   distintos con sonido, vibración y LED propios, aunque el paquete `alarm`
   no lo exponga actualmente.
2. **Notificaciones personalizadas con `RemoteViews`**: crear un layout XML
   nativo personalizado y dispararlo desde Android nativo (plugins Kotlin/Java).
3. **FCM + notificaciones remotas**: si en el futuro se añade backend, usar
   Firebase Cloud Messaging para recordatorios, que pasa Doze mode.
4. **Híbrido `alarm` + `flutter_local_notifications`**: usar `alarm` como
   despertador fiable y, al sonar, mostrar una notificación rica con
   `flutter_local_notifications` inmediatamente. Requiere probar en fabricantes
   problemáticos.
5. **Widget de inicio nativo**: mostrar recordatorios en un widget del launcher
   en lugar de depender de la sombra de notificaciones.

### Archivos relevantes
- `lib/core/services/alarm_service.dart` - Notificaciones de hábitos con `alarm`.
- `lib/core/services/notification_service.dart` - Notificaciones con
  `flutter_local_notifications` (actualmente solo temporizador).
- `lib/core/services/reminder_service.dart` - Coordinador de recordatorios.

---

## Quick actions en notificaciones de hábitos (2026-09-06)

### Problema
Se quería poder marcar un hábito como completado (sí/no, +1 cantidad, etc.)
directamente desde la notificación del sistema sin tener que abrir la app.

### Implementación
Se usa `flutter_local_notifications` con `AndroidScheduleMode.alarmClock`. Esta
modalidad utiliza `AlarmManager.setAlarmClock()` en Android, por lo que **sí**
pasa la agresiva optimización de batería de Huawei/Honor/Xiaomi, y además
soporta `AndroidNotificationAction` (botones de acción en la notificación).

- **'Notificación'** → `NotificationService.schedule` con acciones rápidas:
  - Sí/No para hábitos binarios.
  - +1 `<unidad>` para hábitos de cantidad.
  - Posponer 10 min.
  - Iniciar / Ver lista / Registrar según el tipo de hábito.
- **'Alarma'** → `AlarmService` (pantalla completa + sonido + vibración).

### Manejo en background
`NotificationService` registra un handler top-level anotado con
`@pragma('vm:entry-point')` (`onDidReceiveBackgroundNotificationResponse`). El
handler inicializa `WidgetsFlutterBinding`, `tz_data` y `HabitsRepository`, y
aplica la acción sin abrir la UI.

### Archivos relevantes
- `lib/core/services/notification_service.dart` - Notificaciones programadas
  con quick actions y handler de background.
- `lib/core/services/reminder_service.dart` - Decide a qué servicio delegar.
- `lib/core/services/alarm_service.dart` - Alarmas de pantalla completa.
- `android/app/src/main/AndroidManifest.xml` - Receptores de
  `flutter_local_notifications` (`ActionBroadcastReceiver`,
  `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`).

---

## Imágenes de categorías/hábitos desaparecen (2026-09-08)

### Problema
Las imágenes personalizadas de categorías y hábitos dejaban de mostrarse
(círculos vacíos) al cabo de un tiempo en el dispositivo.

### Causa
`image_picker`/`image_cropper` devuelven archivos en el directorio de **caché**
de la app, y ese path temporal era el que se guardaba en `imagePath`. Android
(especialmente MagicUI de Honor) borra la caché y `FileImage` falla en
silencio, mostrando el círculo sin imagen ni icono.

### Solución
- `ImagePickerService._persistToAppDir()` copia cada imagen elegida a
  `getApplicationDocumentsDirectory()/images/` y devuelve la ruta persistente.
- La UI ahora comprueba `File(path).existsSync()` antes de usar `FileImage` /
  `HabitImageAvatar`, con fallback al icono (`categories_menu_sheet.dart`,
  `habit_visuals.dart` → `effectiveImagePath`, `category_picker.dart`,
  `create_habit_category_step.dart`, `icon_and_customization_step.dart`).

### Nota
Las imágenes ya borradas por el sistema no se pueden recuperar; hay que
volver a elegirlas (ahora se persisten correctamente).

### Archivos relevantes
- `lib/core/services/image_picker_service.dart` - Copia a documentos.
- `lib/features/habits/presentation/widgets/habit_visuals.dart` - Helper
  `_existingImage` + `HabitImageAvatar`.

---

## Precisión de Zona Horaria y Alarmas Exactas (2026-09-08)

### Problema
Las notificaciones y recordatorios presentaban retrasos o desajustes al programarse,
debido a que `timezone` se inicializaba en UTC por defecto y no se asociaba a la
zona horaria local real del dispositivo.

### Solución
1. Se integró `flutter_timezone` para detectar la zona horaria del sistema (`FlutterTimezone.getLocalTimezone()`).
2. Se configuró `tz.setLocalLocation()` tanto en el arranque (`NotificationService.init()`) como en el isolate de background (`_notificationBackgroundHandler`).
3. Se cambió la construcción de fechas en `NotificationService.schedule` para usar `tz.TZDateTime(tz.local, ...)` garantizando la hora exacta local del usuario.
4. Se añadió `NotificationService.canScheduleExactAlarms()` para comprobar los permisos de alarmas exactas en Android 12+.
5. Se corrigió `ReminderService.scheduleAllHabits` para que respete los `reminder.weekDays` individuales de cada recordatorio (evitando que suenen en días no seleccionados cuando la app arranca o vuelve de background).
6. Se aseguró la cancelación de recordatorios (`cancelHabit`) al eliminar un hábito y la programación inmediata al crearlo desde `HabitsScreen`.
7. En `showTimerNotification` se configuraron `usesChronometer: true`, `chronometerCountDown: true` y el timestamp `when` para que Android actualice el segundero de forma nativa y fluida en la pantalla de bloqueo y barra de notificaciones sin congelarse en segundo plano.
8. Se ajustaron las acciones y la prioridad máxima (`Importance.max`, `Priority.max`, `category: reminder`) en las notificaciones para que los botones interactivos (Sí/No, +1, Registrar, Ver lista, Iniciar y Posponer) se muestren desplegados claramente.
9. Se creó un canal de notificación dedicado y silencioso (`sunhabit_timer_running`, `Importance.defaultImportance`, `visibility: public`, `playSound: false`, `enableVibration: false`) para el temporizador, asegurando que persista en la pantalla de bloqueo y barra de estado mostrando el tiempo restante en vivo con el cronómetro nativo, y se eliminó el spam de `_plugin.show()` en cada segundo dentro de `_onTick()`.
10. Se convirtieron los métodos de actualización de hábitos (`incrementHabitAmount`, `setHabitYesNo`, `setHabitAmount`, `toggleChecklistItem`) en asíncronos (`Future<void>`) con `await _save()` en `HabitsRepository` y se añadieron `await` en `_notificationBackgroundHandler`, asegurando que al pulsar "+1", "Sí" o "No" desde la notificación con la app cerrada, los datos se guarden en disco antes de que el sistema operativo cierre el isolate de fondo.

---

## Extracción de audio desde video (2026-09-08)

### Problema
Se quería poder elegir el sonido de una alarma extrayéndolo de un archivo de
video (no solo de archivos de audio), reutilizando el `AudioTrimDialog` ya
existente para recortar el fragmento.

### Solución
1. Se añadió `ffmpeg_kit_flutter_new_audio: ^2.5.2` (variante `_audio` del fork
   mantenido de FFmpegKit, editor verificado, publicado hace >7 días). Soporta
   Android e iOS. La variante `_audio` pesa mucho menos que la `full-gpl` y
   basta para extraer/re-codificar audio.
2. `AudioExtractorService.extractAudio()` ejecuta
   `ffmpeg -y -i <video> -vn -c:a libmp3lame -b:a 192k <salida>.mp3` (con fallback AAC faststart)
   y persiste el resultado en `getApplicationDocumentsDirectory()/extracted_audio/` (para que
   Android/MagicUI no lo borre). El formato `.mp3` garantiza compatibilidad directa con el
   `MediaPlayer` nativo de Android usado por el paquete `alarm`.
3. Se añadió `AudioExtractorService.trimAudio()`, que genera el archivo `.mp3` físicamente
   recortado desde el segundo de inicio y con la duración seleccionada en `AudioTrimDialog`.
   Al seleccionar un sonido para un recordatorio, este se configura automáticamente como `'Alarma'`.
4. `SoundSourcePicker.pick()` muestra un bottom sheet con dos opciones:
   - **Archivo de audio**: `FilePicker` con `FileType.audio` (flujo anterior).
   - **Extraer audio de un video**: `FilePicker` con `FileType.video` +
     extracción con FFmpegKit + diálogo de progreso.
4. Se reemplazó `FilePicker.pickFiles(type: FileType.audio)` directo por
   `SoundSourcePicker.pick()` en `create_habit_schedule_step._pickAlarmSound`
   y `create_category_dialog._pickDefaultSound`. El resto del flujo
   (`AudioTrimDialog`, guardado de `soundPath`/`audioStartSeconds`/
   `audioDurationSeconds`) no cambia.

### Cambio de configuración
`android/app/build.gradle.kts`: `minSdk` subido de `flutter.minSdkVersion`
(21) a **24**, requerido por `ffmpeg_kit_flutter_new_audio`. Sin este cambio
la fusión de manifests del plugin falla.

### Tamaño del APK
La variante `_audio` añade librerías nativas (lame, opus, vorbis, etc.) pero
bastante menos que la `full-gpl`. Aún así el APK crece varios MB; si el tamaño
fuese crítico se podría evaluar la variante `_min` (solo FFmpeg core, sin
encoders externos) si los formatos de entrada lo permiten.

### Archivos relevantes
- `lib/core/services/audio_extractor_service.dart` - Extracción con FFmpegKit.
- `lib/features/alarms/presentation/widgets/sound_source_picker.dart` -
  Bottom sheet de elección de fuente (audio o video).
- `lib/features/habits/presentation/create_habit/create_habit_schedule_step.dart`
  - `_pickAlarmSound` ahora usa `SoundSourcePicker`.
- `lib/features/categories/presentation/create_category_dialog.dart` -
  `_pickDefaultSound` ahora usa `SoundSourcePicker`.
- `android/app/build.gradle.kts` - `minSdk = 24`.

---

## Persistencia de Categorías y Backup (2026-09-09)

### Problema
Al guardar un backup o inicializar la app, solo se persistían los hábitos y logs,
mientras que las categorías dependían de una lista global mutable en memoria
(`defaultCategories`), por lo que no se guardaban en `SharedPreferences` ni se
restauraban categorías personalizadas creadas por el usuario.

### Solución
1. En `HabitsRepository`, se integró `_categories` como lista de instancia privada.
2. Al inicializar (`initialize()`) o recargar (`_load()`), si el almacenamiento no
   tiene categorías guardadas, se cargan las categorías por defecto y se persisten
   inmediatamente con `_save()`.
3. Los métodos `addCategory()`, `updateCategory()` y `deleteCategory()` ahora operan
   directamente sobre `_categories` y guardan los cambios de forma asíncrona.
4. `BackupService` ahora exporta e importa las categorías persistidas de forma completa.

---

## Visualización y Ordenamiento de Recordatorios por Día de la Semana (2026-09-09)

### Problema
En la pantalla de inicio, los hábitos con recordatorios configurados para días específicos
(ej. recordatorio a las 05:50 solo los viernes) mostraban esa hora y se ordenaban según
ella incluso en días no programados (ej. miércoles), mostrando horas discordantes.

### Solución
1. Se añadieron los métodos `earliestReminderMinutesForDate(DateTime date)` y
   `reminderTimeTextForDate(DateTime date)` en `Habit`, los cuales filtran los
   recordatorios que realmente aplican según el día de la semana (`reminder.weekDays`).
2. `HabitsRepository.getHabitsForDate(date)` ahora ordena los hábitos usando la hora
   específica de esa fecha seleccionada.
3. `HomeHabitTile` recibe `selectedDate` y solo muestra la hora del recordatorio si el
   hábito tiene un recordatorio configurado para ese día específico.

---

## Rediseño del Editor de Hábitos y Editor de Recordatorios (2026-09-09)

### Problema
1. Al editar un hábito y cambiar su tipo de objetivo (ej. de Cantidad a Sí/No o Cronómetro)
   o su frecuencia, los cambios no se guardaban porque `Habit.copyWith` preservaba los
   valores antiguos no nulos cuando se pasaba `null`.
2. La pantalla de edición mostraba campos no pertinentes mezclados (ej. meta numérica
   en hábitos Sí/No).
3. El editor de recordatorios en edición solo permitía cambiar la hora, sin mostrar ni
   permitir seleccionar días de la semana activos (`L M X J V S D`) ni elegir sonido.

### Solución
1. En `EditHabitScreen._save()`, se reemplazó `copyWith` por la instanciación explícita
   de `Habit`, limpiando de forma segura los campos del tipo de evaluación o frecuencia anterior.
2. La UI de `EditHabitScreen` ahora es dinámica y solo muestra las tarjetas de configuración
   pertinentes al `_evaluationType` seleccionado.
3. Se rediseñó `showRemindersEditor` integrando para cada recordatorio: selector de hora,
   selector de tipo (Notificación/Alarma), selector de sonido con recorte (`SoundPickerTile`)
   y selector de días de la semana (`L M X J V S D`).

---

## 4 Mejoras Avanzadas en Notificaciones y Alarmas (2026-09-09)

1. **Interactividad con RemoteInput**: En hábitos de cantidad, la notificación ahora incluye
   la acción `✍ Escribir`, permitiendo ingresar un valor numérico directamente desde la
   barra de notificaciones (vía `AndroidNotificationActionInput`).
2. **Volumen Progresivo (Fade-In)**: En `AlarmService`, las alarmas nativas se configuran con
   `VolumeSettings.fade(volume: 1.0, fadeDuration: Duration(seconds: 15))`, aumentando
   el volumen gradualmente en 15 segundos para evitar despertares bruscos.
3. **LargeIcon con Imagen/Icono**: `NotificationService` adjunta `FilePathAndroidBitmap`
   cuando el hábito tiene una imagen o categoría asignada, mostrándola en grande en la notificación.
4. **Asistente de Optimización de Batería y Permisos**: En `SettingsScreen`, se añadió una
   tarjeta interactiva que comprueba el estado de optimización de batería y permisos de alarmas
   exactas, junto con un diálogo de guía paso a paso para fabricantes como Honor/Huawei,
   Xiaomi/Redmi/POCO y Samsung.

---

## Refuerzo de Hábitos y Categorías (2026-09-09)

### Problema
1. Eliminar una categoría con hábitos asociados dejaba hábitos huérfanos (con
   `categoryId` apuntando a una categoría inexistente), rompiendo la UI y el
   creador de hábitos.
2. Cambiar o eliminar la imagen/sonido de un hábito o categoría acumulaba
   archivos huérfanos en el directorio de documentos de la app, consumiendo
   espacio en el dispositivo sin limpieza.
3. Con muchos hábitos, no había forma de filtrar la lista por categoría.

### Solución
1. **Eliminación segura de categorías**:
   - `HabitsRepository.deleteCategory` ahora devuelve `CategoryDeletionResult`
     (`success`, `blockedLastCategory`, `notFound`).
   - Nunca permite eliminar la última categoría restante.
   - Reasigna los hábitos huérfanos a una categoría fallback (elegida por el
     usuario o la primera restante) antes de eliminar.
   - `CategoriesMenuScreen` muestra un diálogo de confirmación con conteo de
     hábitos afectados y un selector de categoría destino, y reprograma los
     recordatorios de los hábitos reasignados.
2. **Limpieza automática de medios huérfanos**:
   - Nuevo `MediaCleanupService` (`lib/core/services/media_cleanup_service.dart`)
     que borra de disco los archivos de imagen/audio que ya no están
     referenciados por ningún hábito, categoría o recordatorio.
   - Solo borra archivos dentro del directorio de documentos de la app
     (donde `ImagePickerService` y `AudioExtractorService` los guardan).
   - Se invoca desde `HabitsRepository.updateHabit`, `deleteHabit`,
     `updateCategory` y `deleteCategory` comparando los medios del estado
     anterior vs. el nuevo.
3. **Filtro por categorías en la lista de hábitos**:
   - `HabitsScreen` ahora muestra una fila horizontal de chips (`Todos` + cada
     categoría) que filtra la lista de hábitos mostrada y el progreso calculado.

### Archivos relevantes
- `lib/features/habits/data/habits_repository.dart` - `deleteCategory` seguro,
  helpers `_cleanupHabitMediaDiff` / `_cleanupCategoryMediaDiff`.
- `lib/core/services/media_cleanup_service.dart` - Servicio de limpieza.
- `lib/features/categories/presentation/categories_menu_sheet.dart` - UI de
  borrado con confirmación y reasignación.
- `lib/features/habits/presentation/habits_screen.dart` - Chips de filtro.
- `test/features/habits/data/habits_repository_category_test.dart` - Tests
  de eliminación segura y reasignación.

---

## Audio extraído y reproducido en alarmas (2026-09-09)

### Problema
1. El audio extraído de videos a veces no sonaba en las alarmas, o el diálogo
   de recorte mostraba nombres de archivo largos y feos.
2. Los archivos de audio elegidos directamente por el usuario (`FilePicker`)
   quedaban en rutas temporales/caché que Android podía borrar, dejando la
   alarma sin sonido días después.
3. `AudioExtractorService` no validaba que el archivo generado fuera realmente
   un audio reproducible, ni limpiaba archivos parciales en caso de fallo.
4. `HabitsRepository.getEffectiveSound` devolvía rutas de sonido aunque el
   archivo ya no existiera, haciendo que `alarm` intentara reproducir un
   archivo inexistente y fallara silenciosamente.

### Solución
1. **Extracción robusta con FFmpegKit**:
   - `AudioExtractorService.extractAudio()` re-encodea a MP3 con LAME a
     192 kbps, estéreo, 44.1 kHz (`-c:a libmp3lame -b:a 192k -ac 2 -ar 44100`).
   - Fallback a AAC `.m4a` si LAME falla.
   - Validación post-proceso: el archivo existe, tiene contenido y FFmpeg
     reporta `Duration:` (lo que garantiza que `MediaPlayer` pueda leerlo).
   - Limpieza automática de archivos parciales si la extracción o el recorte
     fallan.
2. **Recorte fiable**:
   - `AudioExtractorService.trimAudio()` usa `-ss` antes del input y `-t`
     después del input, evitando recortes con duración errónea.
   - Si el recorte falla, devuelve el audio original en lugar de un archivo
     corrupto o nulo.
3. **Audios elegidos se copian a almacenamiento persistente**:
   - `SoundSourcePicker._pickAudio()` ahora copia el archivo elegido a
     `getApplicationDocumentsDirectory()/extracted_audio/` para que no desaparezca
     si el sistema limpia la caché o el picker borra el archivo temporal.
4. **Validación de rutas en `getEffectiveSound`**:
   - Antes de devolver una ruta de sonido, se verifica `File.existsSync()` y
     `lengthSync() > 0`. Si el archivo no existe, se usa el sonido por defecto
     de la categoría o el del sistema.
5. **Mejoras en `AudioTrimDialog`**:
   - El nombre de archivo mostrado limpia los sufijos internos
     (`_extracted_<timestamp>`, `_trimmed_<timestamp>`) para que sea legible.
   - `Tooltip` con el nombre completo al mantener presionado.
   - Si `just_audio` o FFmpeg no pueden leer el audio, se muestra un mensaje
     de error en lugar de permitir guardar un archivo inválido.

### Archivos relevantes
- `lib/core/services/audio_extractor_service.dart` - Extracción/recorte con
  validación FFmpeg.
- `lib/features/alarms/presentation/widgets/sound_source_picker.dart` - Copia
  de audios elegidos a almacenamiento persistente.
- `lib/features/alarms/presentation/widgets/audio_trim_dialog.dart` - UI de
  recorte con validación y nombre limpio.
- `lib/features/habits/data/habits_repository.dart` - `getEffectiveSound`
  valida existencia del archivo.

### Nota importante
- El paquete `alarm` en Android acepta rutas locales absolutas dentro del
  directorio de documentos de la app. Las rutas generadas por
  `AudioExtractorService` (p. ej. `/data/user/0/<paquete>/app_flutter/extracted_audio/...`)
  son rutas absolutas y deberían funcionar con `MediaPlayer` nativo.
- Si en iOS el audio personalizado siguiera sin funcionar, la causa es que el
  paquete `alarm` prefiere rutas relativas al directorio de documentos o
  archivos empaquetados como assets; en ese caso habría que convertir la ruta
  absoluta a relativa (`extracted_audio/nombre.mp3`) antes de pasarla a
  `AlarmService`.

---

## Editor de recordatorios: no se podían eliminar recordatorios (2026-09-09)

### Problema
En la pantalla de edición de hábitos, tocar la `X` de un recordatorio no lo
eliminaba. El bottom sheet seguía mostrando el mismo número de recordatorios.

### Causa
`showRemindersEditor` usaba `StatefulBuilder` pero operaba sobre la lista
original recibida del padre. Al eliminar/editar, se notificaba al padre con
`onRemindersChanged`, pero la UI del propio bottom sheet no se reconstruía con
la nueva lista porque `StatefulBuilder` no mantenía un estado local mutable.
Además, el área táctil del icono de cierre era muy pequeña (20×20).

### Solución
1. `showRemindersEditor` crea ahora una **copia local mutable** (`localReminders`)
   al abrirse. `addReminder`, `removeReminder`, `updateReminder` y
   `toggleReminderDay` actúan sobre esa lista local.
2. Cada cambio notifica al padre vía `onRemindersChanged(List.from(localReminders))`
   y reconstruye el bottom sheet con `setModalState`.
3. Se amplió el área táctil de la `X` de eliminación a un `Container` con padding
   de 8px y fondo `surfaceDark`, facilitando el toque.

### Archivos relevantes
- `lib/features/habits/presentation/edit_habit/pickers/reminders_editor.dart`

---

## AudioTrimDialog: recorte visual del punto final (2026-09-09)

### Problema
En el diálogo de recorte de audio, el texto "Punto final" (y el tiempo debajo)
se cortaba por el borde derecho del diálogo, especialmente en pantallas pequeñas
o con fuentes grandes.

### Causa
El `Row` que muestra inicio, duración y final usaba
`mainAxisAlignment: MainAxisAlignment.spaceBetween` sin `Expanded` ni
`TextOverflow` en las columnas laterales. Cuando el ancho disponible era
insuficiente, el `Row` desbordaba y cortaba la columna derecha.

### Solución
1. Las columnas de "Punto de inicio" y "Punto final" se envolvieron en
   `Expanded` para compartir el espacio disponible.
2. Cada texto (labels y tiempos) se envolvió en `FittedBox(fit: BoxFit.scaleDown)`
   para que se escale hacia abajo si no cupiera en el ancho asignado, evitando
   cualquier corte por overflow.
3. Se redujo el tamaño de fuente de los labels (`fontSize: 10`) y de los
   tiempos (`fontSize: 18`).
4. El contenedor central cambió de "Duración: 30s" a "30s" y se hizo más
   compacto (padding reducido) para dejar más espacio a los laterales.
5. Se redujo el padding interno del recuadro de 16 a 12 px.

### Archivos relevantes
- `lib/features/alarms/presentation/widgets/audio_trim_dialog.dart`

---

## Refactoring de `habit_model.dart` en modelos separados (2026-10-04)

### Problema
`lib/features/habits/data/habit_model.dart` acumulaba `Habit`, `Reminder` y
`HabitEvaluationType` en un solo archivo grande, dificultando la navegación y
el mantenimiento.

### Solución
Se creó `lib/features/habits/data/models/` con tres archivos:

- `habit_evaluation_type.dart` → `HabitEvaluationType` (enum).
- `reminder_model.dart` → `Reminder` (clase).
- `habit_log_model.dart` → `HabitLog` (clase).
- `habit_model.dart` → `Habit` (clase) + `export` de los otros dos.

`lib/features/habits/data/habit_model.dart` y
`lib/features/habits/data/habit_log_model.dart` quedaron como **barrel files**
que re-exportan desde `models/`. Todos los imports existentes
(`import 'habit_model.dart'` / `import 'habit_log_model.dart'`) siguen
funcionando sin cambios.

Además se extrajeron helpers estáticos para evitar duplicación:
- `Reminder._cleanFileName` / `_formatMMSS`.
- `Habit._formatTime` / `_formatDuration`.

### Archivos relevantes
- `lib/features/habits/data/models/` - Directorio de modelos.
- `lib/features/habits/data/habit_model.dart` - Facade re-export.
- `lib/features/habits/data/habit_log_model.dart` - Facade re-export.

---

## Optimización de `habits_repository.dart` (2026-10-04)

### Problema
`lib/features/habits/data/habits_repository.dart` tenía mucha lógica duplicada:
- Búsqueda manual de `HabitLog` por fecha en `_resetDailyCompletion` y
  `getHabitsForDate`.
- Proyección del estado del hábito para una fecha repetida en dos métodos.
- `getHabitById`/`getCategoryById` usaban `try/catch` con `firstWhere`.
- `completeHabit`/`uncompleteHabit` mutaban `isCompleted` en el objeto y luego
  hacían `copyWith`, además de no esperar `_save()`.
- `deleteCategory` creaba `affectedHabits` pero no lo usaba.
- `_load` tenía tres bloques casi idénticos para cargar JSON.
- `_isJsonEmpty` repetía la condición `json == null || json.isEmpty || json == '[]'`.

### Solución
1. **Helpers extraídos**:
   - `_isSameDay(a, b)` → compara año/mes/día.
   - `_isJsonEmpty(json)` → detecta `null`, cadena vacía o `[]`.
   - `_findLogForDate(habitId, date)` → busca el log del hábito en un día.
   - `_projectHabitForDate(habit, log)` → aplica el estado del log a un día
     distinto al actual.
   - `_blankHabitForDate(habit)` → estado en blanco para días sin log.
2. **Código muerto eliminado**: `affectedHabits` en `deleteCategory` ya no se
   declara (no se usaba).
3. **`getHabitById`/`getCategoryById`**: cambiados a `firstOrNull` en lugar
   de `try/catch`, más limpio y eficiente.
4. **`completeHabit`/`uncompleteHabit`/`completeHabitWithDuration`/
   `saveHabitDuration`**: pasados a `Future<void>` y `await _save()` para
   garantizar que la persistencia termine antes de que el OS cierre el
   proceso (igual que `setHabitYesNo`, `incrementHabitAmount`, etc.).
5. **`_load` refactorizado**: usa `_isJsonEmpty` para reducir repetición en
   los tres bloques de carga.
6. **`getHabitsForDate`/`_resetDailyCompletion`**: simplificados usando los
   nuevos helpers.

### Archivos relevantes
- `lib/features/habits/data/habits_repository.dart`

---

## Análisis: alarmas dejan de sonar tras ~3 semanas de uso (2026-10-04)

### Síntoma del usuario
Tras usar la app ~3 semanas, las alarmas dejan de sonar y la app se siente lenta ("se traba con la pila").

### Causas identificadas

#### 1. `scheduleRangeDays = 14` en `ReminderService`
Los recordatorios solo se programan 14 días por adelantado. Si el usuario no
abre la app por más de 14 días, **todas las alarmas expiran**. Tras 3 semanas
sin abrir, ya no hay alarmas programadas.

**Solución aplicada**:
- En `app.dart`, añadí `_startScheduleWatcher()` que llama a
  `ReminderService.scheduleAllHabits()` cada **6 horas** mientras la app está
  en primer plano.
- En `_onRingingChanged`, cuando `Alarm.ringing` pasa de no-vacío a vacío
  (todas las alarmas terminaron), se llama a `scheduleAllHabits()` para
  re-programar los próximos 14 días automáticamente tras una alarma.

#### 2. `_logs` crece indefinidamente
`HabitsRepository._logs` acumula un `HabitLog` por hábito cada día. Tras 3
semanas son ~63 logs por hábito. Cada `_save()`/`_load()` serializa/
deserializa todo el JSON, y `_resetDailyCompletion`/`getHabitsForDate`
iteran toda la lista → la app se vuelve lenta con el tiempo.

**Solución aplicada**:
- `HabitsRepository._cleanupOldLogs()` elimina los logs más antiguos de 90 días
  en `_load()`. Si se borran logs, se marca `shouldSave = true` para persistir
  la lista reducida.

#### 3. `getHabitsForDate` recalcula todo cada vez
Cada llamada itera todos los hábitos y todos los logs. Con muchos logs esto
es O(hábitos × logs). No es un bug, pero agrava la lentitud si `_logs` crece.

**Mitigación**: `_cleanupOldLogs` mantiene `_logs` acotado.

### Archivos relevantes
- `lib/features/habits/data/habits_repository.dart` - `_cleanupOldLogs`.
- `lib/app.dart` - `_startScheduleWatcher` y `_onRingingChanged`.
- `lib/core/services/reminder_service.dart` - `scheduleAllHabits`.
- `lib/core/services/alarm_service.dart` - `Alarm.ringing` stream.

---

## Alarmas semanales auto-reprogramables (2026-10-04)

### Problema
Tras 3 semanas de uso, las alarmas dejaban de sonar porque
`scheduleRangeDays = 14` solo programaba 14 días por adelantado. Si el
usuario no abría la app por más de 14 días, todas las alarmas expiraban.

### Solución: una alarma semanal por día activo

En lugar de 14 alarmas diarias, se crea **una alarma por cada día de la
semana activo** (`weekday` 0-6). Cada alarma se **auto-reprograma** para la
misma semana siguiente cuando termina, creando una recurrencia semanal
"rodante" que no depende de abrir la app.

#### Ventajas vs. ventana de 14 días

| | Ventana 14 días | Alarmas semanales |
|---|---|---|
| Alarmas por reminder | 14 (una por día) | **máx. 7** (una por día activo) |
| ¿Sobrevive a app cerrada? | No (expira tras 14 días) | **Sí** (se auto-reprograma al sonar) |
| ¿Respeta `weekDays`? | Sí (filtra en código) | **Sí** (solo se crean para días activos) |
| Cuota `AlarmManager` | Alto (14×reminders) | **Bajo** (≤7×reminders) |

#### Frecuencias compatibles
- `Todos los días` / `frequency == null` → se crean alarmas para todos los
  días de la semana (o los días de `reminder.weekDays` si está restringido).
- `Días exactos de la semana` → se crean alarmas solo para los días activos
  en `habit.weekDays` ∩ `reminder.weekDays`.

#### Frecuencias NO compatibles (se usa ventana de 14 días)
- `Días específicos del mes` / `Días específicos del año` / `Repetir`
  (cada X días): `isScheduledFor` no es función pura del día de la semana.
- Hábitos con `endDate` próximo: la reprogramación rodante respeta
  `endDate` porque `_onRingingChanged` verifica `isScheduledFor(nextWeek)`
  antes de reprogramar.

#### Cómo funciona la reprogramación
1. `ReminderService.scheduleHabit`/`scheduleAllHabits` crean una alarma por
   cada `weekday` activo con `idForWeekday(habit, i, weekday)`.
2. Cuando la alarma suena, el `AlarmService` nativo despierta la app.
3. `SunHabitApp._onRingingChanged` detecta cuando `Alarm.ringing` pasa de
   no-vacío a vacío (todas las alarmas pararon).
4. Para cada alarma que era un recordatorio de hábito (`_isHabitReminder`),
   se obtiene el `habitId` del payload, se verifica `habit.isScheduledFor`
   para `dateTime + 7 días`, y se reprograma con `Alarm.set` usando el mismo
   ID y configuración pero nueva fecha.

#### IDs semanales vs. diarios
- `idFor(habit, i, date)` → IDs diarios (ventana rodante).
- `idForWeekday(habit, i, weekday)` → IDs semanales (día de la semana 0-6).

`cancelHabit` cancela **ambos** tipos de IDs (por compatibilidad con
programaciones antiguas).

### Archivos relevantes
- `lib/core/services/reminder_service.dart` - `_supportsWeeklyAlarms`,
  `idForWeekday`, `_nextDateWithWeekday`, `scheduleHabit`,
  `scheduleAllHabits` (devuelve `Future<int>`, nº de recordatorios
  programados), `cancelHabit`.
- `lib/app.dart` - `_onRingingChanged` (reprogramación rodante),
  `_isHabitReminder`, `_extractHabitId`.
- `lib/features/settings/presentation/settings_screen.dart` - tarjeta
  "Reactivar alarmas" que llama a `scheduleAllHabits()` manualmente y
  muestra `Alarm.getAlarms()` (conteo de alarmas activas en el sistema).

---

## Sistema visual: paleta de colores y estilos (2026-10-04)

Documentación del diseño para la migración a Kotlin/Compose. Los valores
hexadecimales se trasladan 1:1 a `Color(0xFF...)` en Compose.

### Paleta de marca (AppColors)

| Token | Hex | Uso |
|---|---|---|
| `purple` | `#9270FF` | Acento secundario |
| `green` / `neonGreen` | `#B5FF00` | Color de marca principal (verde lima neón) |
| `gold` / `star` | `#FFD928` | Acento terciario / estrellas |
| `purpleDark` | `#5B21B6` | Variante oscura |
| `greenDark` / `neonGreenDark` | `#58B800` | Variante oscura / primario en light theme |
| `goldDark` | `#B77900` | Variante oscura |
| `neonGreenBright` | `#D5FF52` | Tope del gradiente neón |
| `neonGreenSoft` | `#8FE000` | Indicadores suaves |

### Superficies (tema oscuro — identidad principal)

| Token | Hex | Uso |
|---|---|---|
| `backgroundDark` | `#020302` | Fondo de pantallas |
| `surfaceDark` | `#070907` | Cards base / nav bar |
| `surfaceElevated` | `#101410` | Cards elevadas, inputs, diálogos |
| `surfaceHighest` | `#1A2019` | Tracks de sliders/progress, estados disabled |
| `borderDark` | `#343C32` | Bordes de cards y dividers |

### Superficies (tema claro)

| Token | Hex |
|---|---|
| `backgroundLight` | `#F5F7F2` |
| `surfaceLight` | `#FFFFFF` |
| `borderLight` | `#DDE3D8` |
| `onSurface` (light) | `#151914` |
| `onSurfaceVariant` (light) | `#596356` |
| `muted` (light) | `#768073` |

### Texto (tema oscuro)

| Token | Hex | Uso |
|---|---|---|
| `textPrimary` | `#F9FBF8` | Títulos, contenido principal |
| `textSecondary` | `#C2C7C0` | Subtítulos, iconos secundarios |
| `textMuted` | `#899087` | Labels, hints, disabled |

### Colores semánticos

| Token | Hex | Uso |
|---|---|---|
| `water` | `#8DFFE1` | Categoría/hábito de hidratación |
| `fire` | `#FFA22E` | Rachas / streaks |
| `danger` | `#FF6377` | Errores, acciones destructivas |
| `success` | `#B5FF00` (= neonGreen) | Completado, confirmación |

### Efectos (glows/sombras)

| Token | Hex (con alpha) | Uso |
|---|---|---|
| `neonGlowStrong` | `#805EFF00` (50%) | Sombra de botón elevado |
| `neonGlowMedium` | `#4D5EFF00` (30%) | Track de switches activos |
| `neonGlowSoft` | `#265EFF00` (15%) | Splash, indicador nav, ripple |
| `blackShadow` | `#B3000000` (70%) | Sombras de cards |

### Gradientes (AppDecorations)

- `pageGradient`: radial, `Alignment(0.35, -0.15)`, radius 1.15,
  `#0A1007 → #030503 → #020302` (halo verdoso arriba-centro de cada pantalla)
- `neonGradient`: linear vertical,
  `#D5FF52 → #B5FF00 (42%) → #58B800` (botones y círculos neón)
- `darkCardGradient`: linear diagonal,
  `#171B17 → #090B09 (62%) → #0E140A` (todas las cards)
- `summaryGradient`: radial, `Alignment(0.72, -0.08)`,
  `#17220E → #111411 (52%) → #080A08` (card de resumen del día)

### Tipografía (Roboto)

| Estilo | Tamaño | Peso | Uso |
|---|---|---|---|
| `display` | 34 | w800 | Headers grandes |
| `percentage` | 30 | w800 | Porcentajes grandes |
| `greeting` | 26 | w700 | Saludos en home |
| `statNumber` | 24 | w800 | Números de stats |
| `sectionTitle` | 19 | w600 | Títulos de sección |
| `cardTitle` | 17 | w600 | Título de hábito/card |
| `cardSubtitle` | 15 | w400 | Subtítulos |
| `cardSubtitleDim` | 15 | w400 + tachado | Hábito ya completado |
| `subtitle` | 15 | w400 | Texto de apoyo |
| `statLabel` | 13 | w500 | Labels de stats |
| `label` | 12 | w500 | Labels pequeños / nav |
| `button` | 16 | w700 | Botones |

### Métricas (AppConstants)

- `defaultPadding` = 16dp
- `cardRadius` = 12dp (esquinas de cards, botones, inputs)
- `largeRadius` = 16dp (diálogos, bottom sheets, summary card)
- `controlHeight` = 54dp (altura mínima de botones/inputs)

### Componentes tematizados (darkTheme)

- **Cards**: `darkCardGradient` + borde `borderDark` + sombra negra 12dp/offset(0,5)
  + sombra neón lateral 12% offset(10,0) o 12% offset(18,0) en summary
- **Botón elevado/FAB**: `neonGreen` fondo, texto `#101600`, borde
  `neonGreenBright`, glow `neonGlowStrong`, radio 12
- **Outlined/TextButton**: texto/borde `neonGreen`
- **NavBar**: fondo `surfaceDark`, indicador seleccionado `neonGlowSoft`,
  icono/label seleccionado `neonGreen`, no seleccionado `textSecondary`,
  altura 68, glow superior
- **Inputs**: fondo `surfaceElevated`, borde `borderDark`, focus border
  `neonGreen` 1.5px, error `danger`
- **Switch**: thumb `neonGreen` activo / `textMuted` inactivo;
  track `neonGlowMedium` / `surfaceHighest`
- **Checkbox**: fill `neonGreen`, check `#101600`, radio 5
- **Dialog/BottomSheet**: fondo `surfaceElevated`, borde `borderDark`,
  dragHandle `neonGreen`
- **SnackBar**: fondo `surfaceHighest`, flotante, acción `neonGreen`

### Equivalencia a Compose

```kotlin
object SunHabitColors {
    val Purple = Color(0xFF9270FF)
    val NeonGreen = Color(0xFFB5FF00)
    val NeonGreenBright = Color(0xFFD5FF52)
    val NeonGreenDark = Color(0xFF58B800)
    val NeonGreenSoft = Color(0xFF8FE000)
    val Gold = Color(0xFFFFD928)
    val BackgroundDark = Color(0xFF020302)
    val SurfaceDark = Color(0xFF070907)
    val SurfaceElevated = Color(0xFF101410)
    val SurfaceHighest = Color(0xFF1A2019)
    val BorderDark = Color(0xFF343C32)
    val TextPrimary = Color(0xFFF9FBF8)
    val TextSecondary = Color(0xFFC2C7C0)
    val TextMuted = Color(0xFF899087)
    val Water = Color(0xFF8DFFE1)
    val Fire = Color(0xFFFFA22E)
    val Danger = Color(0xFFFF6377)
    // Glows con alpha:
    // NeonGlowStrong = Color(0x805EFF00), etc.
}

// Gradientes en Compose:
// Brush.radialGradient(listOf(Color(0xFF0A1007), Color(0xFF030503), Color(0xFF020302)))
// Brush.verticalGradient(listOf(Color(0xFFD5FF52), Color(0xFFB5FF00), Color(0xFF58B800)))
```

### Posibles mejoras pendientes

1. **Consolidar colores hardcodeados**: hay ~106 usos de
   `Color(0xFF...)` fuera de `AppColors`. En la migración todos deberían
   pasar por el objeto de colores (o `ColorScheme` de Material 3).
2. **Duplicados de tokens**: `green` == `neonGreen`, `star` == `gold`,
   `greenDark` == `neonGreenDark`, `success` == `neonGreen`. Unificar en
   Kotlin para evitar ambigüedad.
3. **Light theme es secundario**: la identidad visual es el dark+neón.
   El light theme existe pero tiene pocos recursos visuales (sin glows,
   sin gradientes). Decidir si mantenerlo completo o simplificar.
4. **Contraste/accesibilidad**: `neonGreen` sobre `backgroundDark` pasa
   WCAG bien, pero `textMuted` (#899087) en textos pequeños puede quedar
   justo en fondos `surfaceElevated`. Verificar contraste mínimo 4.5:1.
5. **Dynamic color (Material You)**: en Android 12+ se puede ofrecer el
   tema basado en el wallpaper del usuario como opción, manteniendo el
   neón como tema por defecto.
6. **Escala de sombras unificada**: hay muchas combinaciones de glows
   puntuales (11dp, 18dp, 22dp...). Convendría definir 3 niveles:
   `glowS` (chips/iconos), `glowM` (cards/botones), `glowL` (summary/FAB).
7. **Colores de categorías**: los hábitos usan `iconColor` por categoría
   (water, green, gold, redAccent...). En nativo convendría una paleta
   fija de ~12 colores accesibles para el color picker de categorías.

---

## Inventario de pantallas, diálogos y bottom sheets (2026-10-04)

Mapa completo de la UI para la migración a Kotlin/Compose.

### Navegación global

La app **no usa `ShellRoute`**; cada pantalla raíz repite su propia
`BottomAppBar` con 4 tabs + botón central "+":

| Tab | Ruta | Pantalla |
|---|---|---|
| Inicio | `/` | `HomeScreen` |
| Hábitos | `/habits` | `HabitsScreen` |
| **+** (central) | — | Abre creación de hábito (en Home) o menú crear hábito/categoría (en Habits). **En Utilidades y Perfil el "+" no hace nada** (`onTap: () {}`). |
| Utilidades | `/utilities` | `UtilitiesScreen` |
| Perfil | `/profile` | `UserProfileScreen` |

Rutas adicionales: `/alarm` (AlarmSettings como extra), `/habits/:habitId`,
`/focus`, `/eye-care`, `/utilities/stopwatch`, `/utilities/intervals`,
`/settings`, `/eve`, `/rewards` (sin uso).

### Pantallas

#### 1. HomeScreen — `home/presentation/home_screen.dart`
- **Ruta:** `/` (inicial). Dashboard diario de hábitos.
- **Secciones:** header "SunHabit" + icono notificaciones,
  `HomeSummaryCard` (total/completados/pendientes + anillo %),
  `HomeDateRow` (fecha en español + date picker), lista de
  `HomeHabitTile` (icono/imagen, título, progreso, hora del recordatorio
  del día), banner de temporizador activo (`HabitExecutionService`),
  `HomeBottomNavBar`.
- **Acciones:** cambiar fecha (días pasados = solo lectura), tap en
  hábito Sí/No = toggle directo; otros tipos abren
  `HabitCompletionBottomSheet`; "+" abre `ExpressHabitDialog` y, si se
  cierra sin guardar, `CreateHabitDialog`.
- **Datos:** `HabitsRepository` (`getHabitsForDate`),
  `HabitExecutionService`, `ReminderService`.

#### 2. HabitsScreen — `habits/presentation/habits_screen.dart`
- **Ruta:** `/habits`. Listado completo con métricas.
- **Secciones:** título "Hábitos" con dropdown → `CategoriesMenuScreen`,
  botón buscar (`_HabitSearchDelegate`; easter egg: el query exacto
  `|||~~ev~` abre `/eve`),
  `_PeriodSelector` (Hoy/Semana/Mes), card de progreso con barra+%,
  `_CategoryFilterChips`, cards `_TrackingHabitCard` (barra de color,
  icono con glow, progreso, dots L-D de la semana).
- **Acciones:** filtrar por categoría/período, tap card →
  `/habits/:habitId`, "+" → sheet "Crear hábito / Crear categoría".
- **Datos:** `HabitsRepository`, `ReminderService`.

#### 3. HabitDetailScreen — `habits/presentation/habit_detail_screen.dart`
- **Ruta:** `/habits/:habitId`. Detalle con 3 tabs:
  - **Calendario:** `_HabitCalendarSheet` (grid mensual con estados
    completado/no completado/pendiente + leyenda).
  - **Estadísticas:** `_HabitDetailBody` → `_HabitHero` (anillo+avatar+
    badge), `_HabitStatsCard` (3 columnas según tipo),
    `_HabitDailyProgressCard` (barra % que abre el completion sheet),
    `_HabitStreaksCard` (racha actual/mejor), `_HabitHistorySection`
    (dots semanales + "Ver calendario" abre el sheet como bottom sheet),
    `_HabitEmptyState`.
  - **Editar:** `EditHabitScreen` embebido (`isEmbedded: true`).
- **Acciones:** eliminar hábito (AlertDialog + cancela recordatorios),
  completar vía card de progreso.
- **Datos:** `HabitsRepository`, `HabitStreakCalculator`,
  `ReminderService`. Nota: `_HabitActions` existe pero no se usa
  (`unused_element`).

#### 4. EditHabitScreen — `habits/presentation/edit_habit/edit_habit_screen.dart`
- **Acceso:** embebido como tab "Editar" del detalle (siempre embebido;
  `isEmbedded=false` existe pero no se usa). `edit_habit_screen.dart` en
  la raíz de presentation es **solo un re-export**, no duplicado.
- **Secciones:** tiles `EditHabitTile`/`EditHabitTextFieldTile`: nombre,
  categoría (`showCategoryPicker`), descripción, "Hora y recordatorios"
  (`showRemindersEditor`), tipo de objetivo
  (`showEvaluationTypePicker`), meta cantidad/duración/checklist
  (`showGoalEditor`/`showChecklistEditor`), frecuencia
  (`showFrequencyEditor`), fecha inicio/fin (date picker), botón
  "Guardar cambios".
- **Datos:** `HabitsRepository.updateHabit`,
  `ReminderService.scheduleHabit`.

#### 5. AlarmRingingScreen — `alarms/presentation/alarm_ringing_screen.dart`
- **Ruta:** `/alarm` (`extra` = `AlarmSettings`; la lanzan las alarmas
  del paquete `alarm`).
- **Secciones:** fondo con imagen del hábito/categoría o icono gigante
  atenuado + gradiente, `AlarmSoundBanner` ("Silenciar"), icono circular
  con glow (180px), título "¡Es hora de X!", chip de categoría, card de
  stats (puntos + tareas/minutos), vista por tipo:
  `YesNoExecutionView` (slider Sí/No), `AmountExecutionView` (contador ±
  con incrementos por unidad), `ChecklistExecutionView` (checkboxes +
  barra), `TimerExecutionView` (anillo con start/pausa, modo cuidado
  visual), fallback "Detener".
- **Acciones:** silenciar, posponer 10 min
  (`NotificationService.snoozeHabit`), responder/incrementar/marcar/
  detener → guarda y `goHome`. Auto-cierra al completarse el hábito.
- **Datos:** `HabitsRepository`, `HabitExecutionService`,
  `NotificationService`, paquete `alarm`.

#### 6. FocusScreen — `focus/presentation/focus_screen.dart`
- **Ruta:** `/focus`. Temporizador de cuenta regresiva (tipo Pomodoro).
- **Secciones:** `TimeInputFields` (HH:MM:SS), anillo circular 230px con
  tiempo restante, botones Reiniciar/Iniciar-Pausar-Detener.
- **Datos:** `FocusTimerService.instance` (singleton sobrevive
  navegación).

#### 7. EyeCareScreen — `eye_care/presentation/eye_care_screen.dart`
- **Ruta:** `/eye-care`. Regla 20-20-20 (20 min pantalla → descanso).
- **Secciones:** anillo circular con icono de ojo, tiempo restante,
  "Ciclos completados", botones Reiniciar/Iniciar-Pausar, card
  informativa con chips (20 min / 20 pies / descanso) y slider de
  duración del descanso (10–60 s).
- **Datos:** `EyeCareService.instance`.

#### 8. UtilitiesScreen — `utilities/presentation/utilities_screen.dart`
- **Ruta:** `/utilities`. Hub de herramientas.
- **Secciones:** lista de `_UtilityCard` (icono circular con glow,
  título, subtítulo): Temporizador → `/focus`, Cronómetro →
  `/utilities/stopwatch`, Intervalos → `/utilities/intervals`, Cuidado
  visual → `/eye-care`.

#### 9. StopwatchScreen — `utilities/presentation/stopwatch_screen.dart`
- **Ruta:** `/utilities/stopwatch`. Cronómetro con círculo neón
  (HH:MM:SS.cc), Reiniciar/Iniciar-Pausar, "Registrar vuelta" + lista de
  vueltas. **Datos:** `StopwatchService.instance`.

#### 10. IntervalTimerScreen — `utilities/presentation/interval_timer_screen.dart`
- **Ruta:** `/utilities/intervals`. Timer por rondas trabajo/descanso:
  anillo, "Ronda X de Y", card con 3 sliders (`_IntervalSetting`:
  actividad 10–300 s, descanso 5–120 s, rondas 1–20).
  **Datos:** `IntervalTimerService.instance`.

#### 11. UserProfileScreen — `profile/presentation/user_profile_screen.dart`
- **Ruta:** `/profile`. "Tus datos" → `_ActionCard` Exportar/Importar
  hábitos (`BackupService`), tile "Ajustes" → `/settings`.

#### 12. SettingsScreen — `settings/presentation/settings_screen.dart`
- **Ruta:** `/settings` (desde Perfil).
- **Secciones:** card "Probar alarmas y notificaciones" (notificación
  inmediata + alarma en 5 s), card "Reactivar alarmas" (reprograma todo
  + muestra count), card de estado de batería/permisos (iconos
  verde/naranja, aviso de alarmas exactas, "Sin restricciones" →
  `Permission.ignoreBatteryOptimizations`, "Guía de marcas" →
  AlertDialog con pasos OEM Honor/Xiaomi/Samsung).
- **Datos:** `NotificationService`, `AlarmService`, `ReminderService`,
  `permission_handler`.

#### 13. EveProfileScreen — `eve/presentation/eve_profile_screen.dart`
- **Ruta:** `/eve`. Easter egg: buscar "eve" en HabitsScreen. Pantalla
  decorativa "Eve is beautiful": halo pulsante, gradientes, ondas y
  sparkles con `CustomPaint`. Sin datos.

#### 14. RewardsScreen — `rewards/presentation/rewards_screen.dart`
- **Ruta:** `/rewards` (definida pero **nadie navega a ella**).
  Placeholder "Sistema de recompensas". Código muerto.

#### 15. AnalyticsScreen — `analytics/presentation/analytics_screen.dart`
- **Sin ruta** (existe pero ni en el router ni referenciada).
  Placeholder "Seguimiento de hábitos". Código muerto.

#### 16. CategoriesMenuScreen — `categories/presentation/categories_menu_sheet.dart`
- **Acceso:** `Navigator.push` (MaterialPageRoute) desde el dropdown del
  título en HabitsScreen. **No es un sheet** a pesar del nombre del
  archivo.
- **Secciones:** header con botón atrás, contador "N categorías · M
  hábitos", lista de `_CategoryListTile` (avatar imagen/icono, nombre,
  # hábitos, botón eliminar), FAB "+".
- **Acciones:** tap avatar → diálogo de vista ampliada (círculo 260px);
  tap tile → `CreateCategoryDialog` edición; eliminar → AlertDialog
  confirmación + AlertDialog "Reasignar hábitos" si hay hábitos
  asociados; FAB → crear categoría.
- **Datos:** `HabitsRepository` (add/update/deleteCategory),
  `ReminderService` (reprograma hábitos reasignados).

### Diálogos

#### 17. ExpressHabitDialog — `create_habit/express_habit_dialog.dart`
- **Desde:** Home "+". Creación rápida por comando de texto con `|`:
  TextField + chips de plantillas (`mainExpressTemplates`,
  `frequencyExpressTemplates`), vista previa con `HabitCard`, lista de
  errores, "Modo detallado" → `CreateHabitDialog`, "Crear".
- **Datos:** `ExpressHabitParser`. Devuelve `Habit`.

#### 18. CreateHabitDialog — `create_habit/create_habit_dialog.dart`
- **Desde:** Home (tras cerrar Express) y HabitsScreen. Wizard de 5
  pasos (`PageView` + `CreateHabitStepIndicator` +
  Atrás/Siguiente/Guardar):
  1. `CreateHabitCategoryStep` — grid de categorías.
  2. `CreateHabitEvaluationTypeStep` — Sí/No, Cantidad, Cronómetro,
     Checklist.
  3. `CreateHabitEvaluationConfigStep` — nombre, descripción + config
     según tipo (`evaluation/`: `YesNoEvaluationBody`,
     `AmountEvaluationBody` (condición/target/unidad),
     `TimerEvaluationBody` (HH:MM:SS), `ChecklistEvaluationBody`
     (lista reordenable)).
  4. `CreateHabitFrequencyStep` — 6 frecuencias con pickers
     (`frequency/`).
  5. `CreateHabitScheduleStep` — fecha inicio/fin + recordatorios
     (hora, tipo Alarma/Notificación, días de semana, sonido vía
     `SoundSourcePicker` + `AudioTrimDialog`).
- Devuelve `Habit`; el llamador lo guarda y programa recordatorios.
  Soporta `initialHabit` para pre-rellenar.

#### 19. CreateCategoryDialog — `categories/presentation/create_category_dialog.dart`
- **Desde:** HabitsScreen (menú "+") y CategoriesMenuScreen. Wizard de
  2 pasos: `NameAndColorStep` (nombre + grid ~25 colores),
  `IconAndCustomizationStep` (toggle icono/imagen: grid ~28 iconos o
  imagen con `ImagePickerService`, sonido por defecto con
  `SoundPickerTile`). Devuelve `Category`.

#### 20. AudioTrimDialog — `alarms/presentation/widgets/audio_trim_dialog.dart`
- **Desde:** schedule step, create_category_dialog, reminders_editor
  (vía `AudioTrimDialog.show`). Recorte de sonido: timeline
  inicio–duración–fin, progreso de reproducción, slider de inicio,
  chips de duración (15/30/45/60 s), preview con loop, Guardar.
- Devuelve `AudioTrimResult(startSeconds, durationSeconds)`.
- **Datos:** `AudioService`, `AudioExtractorService`.

#### 21. AlertDialogs inline (sin clase propia)
- Eliminar hábito — `HabitDetailScreen._delete`.
- Eliminar categoría + Reasignar hábitos — `CategoriesMenuScreen`.
- Guía OEM por marca — `SettingsScreen._showOemGuideDialog`.
- Vista ampliada de categoría — `_CategoryListTile._showEnlargedPreview`.
- Progreso de extracción de audio — `SoundSourcePicker._pickVideoAndExtract`.

### Bottom sheets

#### 22. HabitCompletionBottomSheet — `habit_completion_bottom_sheet/`
- **Desde:** Home (tap en hábito) y `_HabitDailyProgressCard` del
  detalle. No descartable salvo con la X. Soporta `readOnly`/
  `habitOverride` para días pasados.
- **Secciones:** header (avatar, título, "Solo visualización", X) +
  cuerpo por tipo: `YesNoSection` (Hecho/Deshacer), `AmountSection`
  (contador ±, input numérico), `ChecklistSection` (CheckboxListTile),
  `TimerSection` (start/pausa/stop + opción cuidado visual, usa
  `EyeCareProgress`). Aux: `ActionButton`, `CounterButton`.
- **Datos:** `HabitsRepository`, `HabitExecutionService`.

#### 23. Menú de creación (inline) — `HabitsScreen._openCreateMenu`
- Sheet con 2 ListTile: "Crear hábito" → `CreateHabitDialog`,
  "Crear categoría" → `CreateCategoryDialog`.

#### 24. SoundSourcePicker — `alarms/presentation/widgets/sound_source_picker.dart`
- Sheet "Elegir sonido": archivo de audio (`FilePicker.audio` + copia a
  storage persistente) o extraer de video (`FilePicker.video` +
  FFmpegKit + diálogo de progreso). Devuelve path.
- Usado por schedule step, create_category_dialog y reminders_editor.

#### 25. Pickers de edición (`edit_habit/pickers/`)
- `category_picker.dart` `showCategoryPicker` — lista de categorías con
  avatar; devuelve id.
- `evaluation_type_picker.dart` `showEvaluationTypePicker` — 4 tipos
  con check.
- `reminders_editor.dart` `showRemindersEditor` — lista editable de
  recordatorios (hora, tipo, días, sonido), añadir/eliminar.
- `goal_editor.dart` `showGoalEditor` — target/unidad o duración según
  tipo.
- `checklist_editor.dart` `showChecklistEditor` — añadir/eliminar/
  reordenar tareas.
- `frequency_editor.dart` `showFrequencyEditor` — editor de las 6
  frecuencias con sub-opciones.

#### 26. `_HabitCalendarSheet` — `detail/habit_calendar_sheet.dart`
- Tab "Calendario" del detalle y también bottom sheet desde "Ver
  calendario". Grid mensual con navegación de meses y leyenda.

### Código muerto / notas

- `RewardsScreen` y `AnalyticsScreen` existen pero no se usan
  (placeholders).
- El "+" de las bottom navs de Utilidades y Perfil no hace nada.
- `_HabitActions` (detail) es código no usado.
- `edit_habit_screen.dart` raíz es solo re-export.

---

## Tipos de evaluación del hábito (2026-10-04)

Cómo funciona cada `HabitEvaluationType` (enum en
`models/habit_evaluation_type.dart`). El tipo se **infiere de los campos**
(no hay campo explícito): `checklist` no vacío → checklist; si no,
`estimatedDuration` != null → timer; si no, `target`/`unit` != null →
amount; si no → yesNo. Ver `Habit.evaluationType`.

### 1. Sí/No (`yesNo`)

- **Campos:** `yesNo` (bool). `isCompleted` se sincroniza con `yesNo`.
- **UI creación:** solo texto explicativo (`YesNoEvaluationBody`).
- **Completado:** `completeHabit`/`setHabitYesNo(id, v)` → `yesNo = v`,
  `isCompleted = v`. Tap directo en el tile del Home hace toggle (no
  abre sheet).
- **Log del día:** `currentValue` = 1 si sí, 0 si no.
- **Puntos por defecto:** 10.

### 2. Cantidad (`amount`)

- **Campos:** `current`, `target`, `unit` (ej. "vasos", "páginas",
  "km"). `isCompleted` = `current >= target`.
- **UI creación:** `AmountEvaluationBody` = condición + input numérico
  "Objetivo" + dropdown de unidad.
- **Completado:** `incrementHabitAmount(id, delta)` y
  `setHabitAmount(id, n)` → `clamp(0, 999999)`; se marca completado
  automáticamente al alcanzar `target`. También se descompleta si baja
  del target.
- **Log del día:** `currentValue` = `current` actual.
- **Puntos por defecto:** 15.
- **UI ejecución:** contador ± con incrementos sugeridos por unidad
  (`AmountExecutionView` en la alarma, `AmountSection` en el sheet).

### 3. Checklist (`checklist`)

- **Campos:** `checklist` (lista de ítems), `completedChecklist`
  (ítems marcados). `isCompleted` = todos los ítems de `checklist`
  están en `completedChecklist` (y `checklist` no vacío).
- **UI creación:** `ChecklistEvaluationBody` = input + botón "+" +
  `ReorderableListView` (arrastrar para reordenar, X para eliminar).
- **Completado:** `toggleChecklistItem(id, item)` → marca/desmarca el
  ítem; recalcula `isCompleted`.
- **Log del día:** guarda `completedChecklist` (snapshot de ítems
  marcados) para mostrar el progreso real en días pasados.
- **Puntos por defecto:** 15.

### 4. Cronómetro (`timer`)

- **Campos:** `estimatedDuration` (duración objetivo HH:MM:SS).
- **UI creación:** `TimerEvaluationBody` = condición + 3 inputs
  numéricos (H / Min / Seg).
- **Completado:** `completeHabitWithDuration(id, seconds)` →
  `isCompleted = true` + log con `currentValue` = segundos reales
  transcurridos. `saveHabitDuration` guarda sin completar.
  `HabitExecutionService` corre el cronómetro en background con
  notificación persistente.
- **Progreso:** `progressText` muestra la duración estimada
  (`HH:MM:SS`) o "Completado".
- **Puntos por defecto:** 15.

### Condición (⚠️ no se persiste)

Los tipos `amount` y `timer` muestran un `EvaluationSegmentedControl`
de condición con valores `['Al menos', 'Menos de', 'Exactamente',
'Libre']`, pero **el campo no se guarda en el `Habit`** (se descarta en
el diálogo). Hoy el completado siempre se evalúa como `>= target`.
En la migración: o se persiste como campo `condition` y se usa al
calcular `isCompleted`, o se elimina del wizard para no prometer algo
que no hace nada.

---

## Opciones de frecuencia (2026-10-04)

Las 6 frecuencias (`frequency` guarda el string literal en español).
La lógica central es `Habit.isScheduledFor(date)` — primero verifica
`startDate`/`endDate` (rango de validez inclusive) y luego aplica la
frecuencia.

### Resumen de lógica (`Habit.isScheduledFor`)

```dart
if (start != null && target.isBefore(start)) return false;
if (end != null && target.isAfter(end)) return false;
switch (frequency) {
  'Todos los días' / null   → true
  'Días exactos de la semana' → weekDays[weekday - 1]
  'Días específicos del mes'  → monthDays.contains(day)
  'Días específicos del año'  → yearDays.any(mes+dia coincide)  // año se ignora
  'Algunas veces por período' → igual que 'Repetir' (!)
  'Repetir'                   → (target - startDate).days % repeatInterval == 0
}
```

### Las 6 frecuencias en detalle

| Frecuencia | Campos que usa | Picker UI | Alarmas semanales nativas |
|---|---|---|---|
| `Todos los días` (o `null`) | — | Sin picker extra | Sí |
| `Días exactos de la semana` | `weekDays` (`List<bool>` ×7, L→D) | `WeekDayPicker`: 7 círculos toggle | Sí |
| `Días específicos del mes` | `monthDays` (`List<int>` 1-31) | `MonthDayPicker`: grid de 31 círculos | No (ventana 14 días) |
| `Días específicos del año` | `yearDays` (`List<DateTime>`, máx. 10; solo mes+día) | `YearDayPicker`: dropdown mes + día + chips | No (ventana 14 días) |
| `Algunas veces por período` | `timesPerPeriod`, `periodType` ('semana'/'mes'/'año'), `repeatInterval` | `PeriodFrequencyPicker`: "Veces" + "Por" + "Repetir cada X días" | No (ventana 14 días) |
| `Repetir` | `repeatInterval` | `RepeatFrequencyPicker`: "Repetir cada X días" | No (ventana 14 días) |

### ⚠️ Incosistencia importante: 'Algunas veces por período'

La UI ofrece `timesPerPeriod` y `periodType`, pero `isScheduledFor`
**los ignora**: trata esta frecuencia exactamente igual que `Repetir`
(`diff % repeatInterval == 0`). Guardar `timesPerPeriod`/`periodType`
no cambia en qué días aparece el hábito. En la migración hay que decidir:
- Implementar la semántica real (N veces por semana/mes/año → requiere
  contar logs del período, no es una función pura del día), o
- Fusionarla con `Repetir` y quitar los campos de la UI.

### Recordatorios (`Reminder`)

Cada hábito tiene `reminders` (`List<Reminder>`):

| Campo | Tipo | Notas |
|---|---|---|
| `hour`, `minute` | int | Hora local 24h |
| `type` | String | `'Notificación'` (FLN + quick actions) o `'Alarma'` (pantalla completa + sonido) |
| `soundPath` | String? | Audio recortado en docs de la app |
| `audioStartSeconds`, `audioDurationSeconds` | int? | Fragmento recortado |
| `weekDays` | `List<bool>?` | null = todos los días programados del hábito; si no, intersecta con la frecuencia |

- Un recordatorio suena solo si `isScheduledFor(date)` **y**
  `reminder.weekDays[weekday-1]` (si weekDays != null).
- Sonido efectivo: recordatorio > `category.defaultSoundPath` > sistema
  (`HabitsRepository.getEffectiveSound`).

### Estado proyectado por fecha (`getHabitsForDate`)

- **Hoy**: devuelve el hábito "vivo" (estado en memoria).
- **Otro día**: si hay `HabitLog` de ese día, proyecta
  `isCompleted`/`current`/`completedChecklist`/`yesNo` del log; si no,
  devuelve el hábito "en blanco" (no completado).
- Por eso el estado diario se persiste en `habit_logs` (no solo en el
  hábito) y las días pasados son de solo lectura.

### Puntos

`points` por defecto: 10 para yesNo, 15 para los demás tipos (definido
en `CreateHabitDialog._buildHabit`).

---

## Utilidades / herramientas (2026-10-04)

Las 4 herramientas accesibles desde el tab "Utilidades"
(`UtilitiesScreen` es un hub de `_UtilityCard`). Todas comparten el
mismo patrón arquitectónico:

### Patrón común

- **Singleton `ChangeNotifier`** (`.instance`): el estado vive fuera del
  widget, así que el timer sigue corriendo aunque el usuario navegue.
  Al volver, la UI lee el estado actual.
- **`Timer.periodic(1s)`** para decrementar el tiempo mostrado.
- **`_endTime`/`_phaseEndTime` (reloj real)** al iniciar:
  `DateTime.now().add(remaining)`. Permite recalcular el tiempo real
  transcurrido al volver de background.
- **`syncFromWallClock()`**: llamado al volver a la pantalla o de
  background. Compara `DateTime.now()` con `endTime` y corrige el
  estado (el `Timer.periodic` puede haberse pausado por el OS).
  Interval y EyeCare avanzan **múltiples fases** en un `while` si el
  dispositivo estuvo suspendido varios ciclos.
- **Notificación de fin de fase**: `AlarmService.setUtilityNotification`
  (una alarma exacta del paquete `alarm`) que dispara aunque la app
  esté cerrada. Se cancela al pausar/resetear.

### 1. Temporizador de enfoque (`FocusScreen` `/focus`)

**Servicio:** `FocusTimerService`
(`lib/core/services/focus_timer_service.dart`)

- Cuenta regresiva libre estilo Pomodoro. Default 25 min
  (`initialSeconds = 25*60`, `remaining` igual al inicio).
- UI: `TimeInputFields` (HH:MM:SS, solo editable detenido) + anillo
  circular 230px + Reiniciar/Iniciar-Pausar-Detener.
- `toggle()` inicia/pausa; si `remaining <= 0` reinicia a
  `initialSeconds`.
- Al llegar a 0 se marca `running = false` (la notificación de fin ya
  está programada).
- Al iniciar programa una alarma de utilidad con
  `durationSeconds = remaining` ("El temporizador ha terminado").

### 2. Cronómetro (`StopwatchScreen` `/utilities/stopwatch`)

**Servicio:** `StopwatchService`
(`lib/core/services/stopwatch_service.dart`)

- Cuenta ascendente HH:MM:SS.cc (con centésimas).
- Usa `Stopwatch` nativo de Dart (**reloj monótono**): no necesita
  ticker, el tiempo es exacto aunque la app se suspenda.
- `toggle()` start/pause, `reset()` vuelve a 0 y limpia vueltas.
- **Vueltas:** `addLap()` inserta el `elapsed` actual al inicio de
  `laps` (la más reciente primero). Ignora vueltas con
  `elapsed == Duration.zero`.
- UI: círculo neón con el tiempo, lista de vueltas numeradas.

### 3. Intervalos (`IntervalTimerScreen` `/utilities/intervals`)

**Servicio:** `IntervalTimerService`
(`lib/core/services/interval_timer_service.dart`)

- Alterna fases **trabajo/descanso** durante N rondas (tipo HIIT/tabata).
- Config: `workSeconds` (default 45, slider 10–300 s), `restSeconds`
  (default 15, slider 5–120 s), `rounds` (default 8, slider 1–20).
  Solo editables detenido.
- Estado: `currentRound`, `isWork`, `remaining`, `finished`.
- `_tick()` decrece; al llegar a 0:
  - si era trabajo → pasa a descanso (`remaining = restSeconds`),
  - si era descanso y `currentRound < rounds` → siguiente ronda
    (`currentRound++`, vuelve a trabajo),
  - si era la última ronda → `finished = true`.
- Cada cambio de fase programa una notificación con título/cuerpo
  distintos ("Tiempo de descansar", "Tiempo de trabajar",
  "Entrenamiento completado") vía `_scheduleUtilityNotification`.
- `syncFromWallClock` con `_phaseEndTime` avanza fases en bucle si la
  app estuvo suspendida.
- UI: anillo, "Ronda X de Y", 3 sliders `_IntervalSetting`.

### 4. Modo cuidado visual (`EyeCareScreen` `/eye-care`)

**Servicio:** `EyeCareService`
(`lib/core/services/eye_care_service.dart`)

- Implementa la **regla 20-20-20**: cada `eyeCareWorkSeconds` (20 min,
  `AppConstants`) de pantalla → un descanso de `restSeconds`.
- `restSeconds` configurable con slider 10–60 s (default
  `eyeCareBreakSeconds` = 20 s). Solo editable detenido.
- Estado: `isWorkPhase`, `remaining`, `completedCycles`.
- `_advancePhase()`: trabajo→descanso (sin contar ciclo);
  descanso→trabajo (`completedCycles++` y vuelve a 20 min). Es un ciclo
  infinito hasta que el usuario pausa/resetea.
- Notificaciones por fase: "Hora de descansar la vista" / "Descanso
  terminado".
- `syncFromWallClock` avanza las fases que hayan pasado durante la
  suspensión (puede saltarse varios ciclos).
- UI: anillo con icono de ojo, "Ciclos completados", chips explicativos
  (20 min / 20 pies / descanso), slider de descanso.
- `EyeCareService` también se integra con los hábitos tipo timer: la
  sección `TimerSection`/`EyeCareProgress` del completion sheet puede
  activar cuidado visual durante la ejecución del hábito.

### Resumen para migración

| Servicio | Estado clave | Fases | Completa automático | Config editable |
|---|---|---|---|---|
| `FocusTimerService` | `initialSeconds`, `remaining`, `running` | 1 | Sí (a 0) | HH:MM:SS detenido |
| `StopwatchService` | `Stopwatch.elapsed`, `laps` | — | No | — |
| `IntervalTimerService` | `work`/`rest`/`rounds`, `currentRound`, `isWork`, `finished` | 2N | Sí (última ronda) | sliders detenido |
| `EyeCareService` | `restSeconds`, `isWorkPhase`, `completedCycles` | ∞ cíclico | No (infinito) | descanso detenido |

---

## Flujo de creación de hábitos (2026-10-04)

Hay **dos formas de crear un hábito**: el modo Exprés (comando de texto)
y el wizard detallado (5 pasos). El botón "+" de Home intenta siempre
Exprés primero; el "+" de HabitsScreen abre un menú con "Crear hábito"
(wizard directo) o "Crear categoría".

### Flujo general

```
Home "+"  →  ExpressHabitDialog
             ├─ devuelve Habit → addHabit + scheduleHabit
             └─ devuelve null ("Modo detallado" o cerrado)
                → CreateHabitDialog
                  └─ devuelve Habit → addHabit + scheduleHabit

HabitsScreen "+"  →  sheet: "Crear hábito" → CreateHabitDialog
                       "Crear categoría" → CreateCategoryDialog
```

Tras crear, el hábito se guarda (`HabitsRepository.addHabit`) y sus
recordatorios se programan (`ReminderService.scheduleHabit`)
inmediatamente, sin necesidad de reiniciar la app.

### Modo Exprés — `ExpressHabitDialog`

Creación con una sola línea de texto separada por `|`:

```
Título en Categoría | Métrica | Frecuencia | Fecha inicio | Hora
```

- **Parser:** `ExpressHabitParser` → `ParsedExpressHabit` (no es un
  `Habit` todavía; falta icono/color de la categoría).
- **Preview en vivo:** `_onTextChanged` re-parsea cada tecla y muestra
  el `HabitCard` resultante + lista de errores.
- **Chips de plantillas:** `mainExpressTemplates` (una por tipo de
  evaluación) + `frequencyExpressTemplates` (tras "Más frecuencias").
  Insertan el comando y seleccionan la parte editable.
- **Botones:** "Modo detallado" (cierra → wizard) / "Crear" (solo si
  `parsed.isValid`).
- `isValid` requiere: sin errores + título + categoría + evaluationType.

#### Gramática del parser

**Segmento 1 — Título y categoría** (`_parseTitleAndCategory`):
- `Título en Categoría` — busca ` en ` (última aparición) y resuelve la
  categoría por nombre/id (case-insensitive).
- Solo nombre de categoría → título = nombre, categoría = esa.
- Sin categoría reconocida → título = texto, categoría = primera
  disponible (fallback para no bloquear el preview).

**Segmento 2 — Métrica** (`_parseMetric`):

| Formato | Tipo | Extrae |
|---|---|---|
| `Sí/No`, `si`, vacío o no reconocido | `yesNo` | — (default) |
| `Cantidad:` o `cant:` `2 vasos al menos` | `amount` | `target` (primer dígito), `unit` (texto tras número), `condition` ⚠️ |
| `Timer:`/`Tiempo:`/`Duración:` `10 min` | `timer` | `estimatedDuration` (`1 hora`/`30 min`/`45 seg`/número suelto→min), `condition` ⚠️ |
| `Lista:`/`Checklist:`/`Tareas:` `a, b, c` | `checklist` | ítems separados por `,` o `;` |

⚠️ `condition` se parsea (`al menos`/`menos de`/`exactamente`/`libre`)
pero **tampoco se persiste** aquí (el `Habit` no tiene el campo).

**Segmento 3 — Frecuencia** (`_parseFrequency`):

| Formato | Frecuencia |
|---|---|
| vacío, `todos los días`, `diario`, `diaria` | `Todos los días` |
| `Lunes, Miércoles` / `L, X, V` / `Lunes a Viernes` | `Días exactos de la semana` (mapa de abreviaturas con/sin tilde) |
| `Días mes:` / `dias mes:` / `mes:` `1, 15` | `Días específicos del mes` |
| `3 veces por semana`/`mes`/`año` | `Algunas veces por período` |
| `cada 3 días`/`cada 3 dias` | `Repetir` (intervalo) |
| cualquier otra cosa | `Todos los días` (fallback) |

⚠️ `yearDays` (Días específicos del año) **no se puede crear por
Exprés** — no hay sintaxis para fechas del año.

**Segmento 4 — Fecha inicio** (`_parseDate`):
`hoy` (default/vacío), `mañana`, `DD/MM/AAAA` (también `-` y `.`, año
de 2 o 4 dígitos). Si no matchea → hoy.

**Segmento 5 — Hora** (`_parseTime`):
`8:00 AM`/`8 pm` (12h, parsea antes que 24h), `20:00`/`20h` (24h),
`8 h`/`8h` (solo hora). Devuelve un único `Reminder` (tipo
`'Notificación'` por defecto, sin sonido).

#### Limitaciones del modo Exprés vs. wizard

- Solo **un** recordatorio, siempre tipo `'Notificación'`, sin sonido.
- No soporta: `endDate`, `yearDays`, `weekDays` por recordatorio,
  descripción, imagen/icono propios (hereda los de la categoría).
- No se puede elegir tipo 'Alarma' ni recortar audio.

### Wizard detallado — `CreateHabitDialog`

5 pasos en `PageView` con `CreateHabitStepIndicator` +
Atrás/Siguiente/Guardar:

| Paso | Widget | Contenido |
|---|---|---|
| 0 | `CreateHabitCategoryStep` | Lista de categorías (avatar imagen/icono + check neón) |
| 1 | `CreateHabitEvaluationTypeStep` | 4 opciones con icono+descripción: Sí/No, Cantidad, Checklist, Cronómetro |
| 2 | `CreateHabitEvaluationConfigStep` | Nombre (requerido) + descripción + cuerpo por tipo (`yes_no`/`amount`/`checklist`/`timer` bodies) |
| 3 | `CreateHabitFrequencyStep` | 6 frecuencias con pickers expandibles |
| 4 | `CreateHabitScheduleStep` | Fecha inicio/fin (date picker) + lista de recordatorios |

- **Validación:** solo el nombre es obligatorio (paso 2, SnackBar si
  vacío). No valida que haya recordatorios ni frecuencia concreta
  (sin días seleccionados en `weekDays` el hábito nunca aparece: ver
  `isScheduledFor`).
- **Recordatorios (paso 4):** cada uno tiene hora (time picker), tipo
  (dropdown `'Notificación'`/`'Alarma'`), y:
  - si frecuencia = `Días exactos de la semana` → picker de 7 días
    propio (al menos 1 activo; todos → `null`);
  - si tipo = `Alarma` → `SoundPickerTile` con sonido
    (recordatorio > categoría > app), `SoundSourcePicker` +
    `AudioTrimDialog` para elegir/recortar.
- **`initialHabit`:** soporta pre-rellenar todos los campos (usado por
  `_prefill`) — aunque en la práctica la edición se hace con
  `EditHabitScreen`, no con este diálogo.
- **Herencia visual:** el hábito nuevo toma `icon`, `iconColor` e
  `imagePath` de la categoría elegida.

### Posibilidades resultantes por vía

| Capacidad | Exprés | Wizard | Edición |
|---|---|---|---|
| Categoría | solo por nombre/id | sí | sí (picker) |
| Descripción | no | sí | sí |
| Tipo evaluación | los 4 | los 4 | los 4 |
| Condición (al menos/menos de...) | parsea, no guarda | muestra, no guarda | no existe |
| Checklist ítems | sí (`,`/`;`) | sí (reordenable) | sí |
| Frecuencias | 5 de 6 (sin `yearDays`) | las 6 | las 6 |
| Fecha fin | no | sí | sí |
| Recordatorios | 1, siempre notif. | varios, con tipo/días/sonido | varios, igual |
| Sonido + recorte | no | sí (alarma) | sí (alarma) |

---

## Generar APK release (2026-10-04)

### Comando

```powershell
flutter build apk --release --split-per-abi --no-tree-shake-icons
```

### Por qué `--no-tree-shake-icons` es obligatorio

Los modelos `Category` y `Habit` guardan iconos como `IconData(codePoint,
fontFamily: 'MaterialIcons')` **no constantes** (se reconstruyen desde
JSON). El tree-shaker de iconos de Flutter no puede analizar eso y el
build release falla con `Target aot_android_asset_bundle failed`.

Alternativas futuras: usar un enum de iconos constantes + mapa, o
serializar el icono como `int codePoint` en vez de `IconData`.

### APKs generados (build/app/outputs/flutter-apk/)

| Archivo | Arquitectura | Tamaño | Para quién |
|---|---|---|---|
| `app-arm64-v8a-release.apk` | ARM 64-bit | ~43 MB | **Dispositivos modernos** (casi todos, incl. Honor/Huawei/Xiaomi/Samsung actuales) — compartir este |
| `app-armeabi-v7a-release.apk` | ARM 32-bit | ~57 MB | Dispositivos antiguos (pre-2016 aprox.) |
| `app-x86_64-release.apk` | x86 64-bit | ~46 MB | Emuladores / Android-x86 en PC |

El APK pesa más de lo normal por `ffmpeg_kit_flutter_new_audio`
(librerías nativas de FFmpeg por ABI).

### Firma

`buildTypes.release.signingConfig` usa la **debug key** (ver
`build.gradle.kts`): el APK instala sin problema por sideloading, pero
no sirve para Play Store ni para actualizaciones entre dispositivos con
firma distinta. Para publicar, hace falta un keystore propio +
`key.properties` (ya ignorado en `.gitignore`).

### Instalación en el dispositivo

Copiar el APK al teléfono → abrir → Android pedirá "Instalar apps de
origen desconocido" para la app que lo abre (archivos/navegador) →
aceptar. En Honor/MagicUI puede aparecer una advertencia extra de
seguridad.

