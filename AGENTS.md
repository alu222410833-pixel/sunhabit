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

