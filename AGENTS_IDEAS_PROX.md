SE PLAENA INTEGRAR UN EXTRACTOR DE AUDIO  [HECHO 2026-09-08]
* Colocar un botón en la pantalla de hábitos para extraer el audio de un video
  - Implementado en SoundSourcePicker: al elegir sonido de alarma aparece un
    bottom sheet con "Archivo de audio" o "Extraer audio de un video". La
    extracción se hace con ffmpeg_kit_flutter_new_audio y se persiste en
    documentos. Después pasa al AudioTrimDialog igual que un audio normal.
* El audio se guardará en la carpeta de documentos de la app
  - getApplicationDocumentsDirectory()/extracted_audio/ (no lo borra MagicUI)
* El audio se podrá reproducir en la pantalla de hábitos
  - Se previsualiza en AudioTrimDialog antes de guardar (igual que antes)
* El audio se podrá eliminar de la carpeta de documentos de la app
  - TODO: de momento no se limpian los .m4a huérfanos al quitar el sonido.
    Habría que añadir limpieza en _removeAlarmSound / _removeDefaultSound.
SE PLANEA TAMBIEN CREAR EN AJUSTES UNA PANTALLA PARA ACTIVAR/DESACTIVAR UN MODO DE RECOMPENSAS Y MODO NORMAL
- Ya que en el modo de recompensas se mostrarán las recompensas obtenidas
    -Motivo ya que modo recompensas pude ser tedioso para el usuario 
    -Solo se llevara un sistema de recomepensas que ahi si se llevariasn los puntos al completar cada habito
    
- Y en el modo normal se mostrarán los hábitos solo como finalizados 
    -Aun contara con la muestra de rechas 
    -Mayor racha 
    -Dias contados 

*Tambien los widgets para que etsen en la pantalla 
-Serian 3 widgets:
    -Widget de recompensas
    -Widget de hábitos listado de habitos
        -Para tambien ahi mismo registrarlos 
    -Widget de estadísticas
    -WIdget para mostar una imagen o video 

*Que cuando suene las alarmas  se puedan mostrar un video tambien 

