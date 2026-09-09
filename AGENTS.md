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


