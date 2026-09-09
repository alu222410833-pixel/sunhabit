import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/services/audio_extractor_service.dart';
import 'package:sunhabit/core/services/image_picker_service.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/core/theme/app_decorations.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/audio_trim_dialog.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/sound_source_picker.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/categories/presentation/widgets/icon_and_customization_step.dart';
import 'package:sunhabit/features/categories/presentation/widgets/name_and_color_step.dart';
import 'package:sunhabit/features/categories/presentation/widgets/step_indicator.dart';

class CreateCategoryDialog extends StatefulWidget {
  final Category? initialCategory;

  const CreateCategoryDialog({super.key, this.initialCategory});

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final _nameController = TextEditingController();
  final _pageController = PageController();
  int _currentStep = 0;

  static const _colors = [
    // Rojos / naranjas
    Color(0xFFEF4444), // rojo
    Color(0xFFF97316), // naranja
    Color(0xFFFB923C), // naranja melocotón
    AppColors.fire, // naranja fuego
    Color(0xFFF59E0B), // ámbar
    Color(0xFFEAB308), // dorado
    AppColors.gold, // oro

    // Amarillos / verdes
    AppColors.neonGreen, // verde neón
    Color(0xFF22C55E), // verde lima
    Color(0xFF10B981), // esmeralda

    // Turquesas / cian
    AppColors.water, // agua
    Color(0xFF14B8A6), // teal
    Color(0xFF2DD4BF), // turquesa
    Color(0xFF06B6D4), // cian

    // Azules / cielos
    Color(0xFF0EA5E9), // cielo
    Color(0xFF38BDF8), // celeste
    Color(0xFF3B82F6), // azul

    // Índigos / violetas
    Color(0xFF6366F1), // índigo
    Color(0xFF4F46E5), // índigo intenso
    AppColors.purple, // púrpura
    Color(0xFF8B5CF6), // violeta
    Color(0xFF7C3AED), // violeta-púrpura
    Color(0xFFA855F7), // morado suave

    // Magentas / rosas
    Color(0xFFD946EF), // fucsia
    Color(0xFFEC4899), // rosa
    AppColors.danger, // rojo-rosa
  ];

  static const _icons = [
    Icons.favorite_outline_rounded,
    Icons.menu_book_rounded,
    Icons.work_outline_rounded,
    Icons.fitness_center_rounded,
    Icons.self_improvement_rounded,
    Icons.savings_rounded,
    Icons.airplanemode_active_rounded,
    Icons.star_outline_rounded,

    // 20 iconos adicionales
    Icons.school_rounded,
    Icons.computer_rounded,
    Icons.brush_rounded,
    Icons.palette_rounded,
    Icons.music_note_rounded,
    Icons.sports_basketball_rounded,
    Icons.directions_run_rounded,
    Icons.directions_bike_rounded,
    Icons.shopping_cart_rounded,
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.bed_rounded,
    Icons.shower_rounded,
    Icons.pets_rounded,
    Icons.code_rounded,
    Icons.movie_rounded,
    Icons.videogame_asset_rounded,
    Icons.book_rounded,
    Icons.alarm_rounded,
    Icons.phone_rounded,
  ];

  Color _selectedColor = _colors.first;
  IconData? _selectedIcon = _icons.first;
  String? _imagePath;
  /// 0 = icono, 1 = imagen. Solo uno u otro es el visual activo.
  int _visualMode = 0;
  String? _defaultSoundPath;
  int? _defaultAudioStartSeconds;
  int? _defaultAudioDurationSeconds;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory;
    if (initial != null) {
      _nameController.text = initial.name;
      _selectedColor = initial.color;
      if (initial.imagePath != null && initial.imagePath!.isNotEmpty) {
        _visualMode = 1;
        _imagePath = initial.imagePath;
      } else if (initial.icon != null) {
        _visualMode = 0;
        _selectedIcon = initial.icon;
      }
      _defaultSoundPath = initial.defaultSoundPath;
      _defaultAudioStartSeconds = initial.defaultAudioStartSeconds;
      _defaultAudioDurationSeconds = initial.defaultAudioDurationSeconds;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep = 1);
    } else {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _showValidationMessage('Escribe un nombre para la categoría.');
        return;
      }
      // Solo se persiste el visual del modo activo (icono O imagen).
      final useImage = _visualMode == 1;
      final hasImage = _imagePath != null && _imagePath!.isNotEmpty;
      if (useImage ? !hasImage : _selectedIcon == null) {
        _showValidationMessage(useImage
            ? 'Selecciona una imagen para la categoría.'
            : 'Selecciona un icono para la categoría.');
        return;
      }
      final id = widget.initialCategory?.id ??
          DateTime.now().microsecondsSinceEpoch.toString();
      final category = Category(
        id: id,
        name: name,
        color: _selectedColor,
        icon: useImage ? null : _selectedIcon,
        iconColor: useImage ? null : _selectedColor,
        imagePath: useImage ? _imagePath : null,
        defaultSoundPath: _defaultSoundPath,
        defaultAudioStartSeconds: _defaultAudioStartSeconds,
        defaultAudioDurationSeconds: _defaultAudioDurationSeconds,
      );
      Navigator.of(context).pop(category);
    }
  }

  void _previousStep() {
    if (_currentStep == 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep = 0);
    }
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceHighest,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final path = await ImagePickerService().pickImage(source: source);
    if (path == null || !mounted) return;
    setState(() => _imagePath = path);
  }

  void _removeImage() => setState(() => _imagePath = null);

  Future<void> _pickDefaultSound() async {
    final path = await SoundSourcePicker.pick(context);
    if (path == null || path.isEmpty || !mounted) return;

    final trimResult = await AudioTrimDialog.show(
      context,
      soundPath: path,
      initialStartSeconds: 0,
      initialDurationSeconds: 30,
    );

    if (!mounted) return;

    String finalPath = path;
    if (trimResult != null &&
        (trimResult.startSeconds > 0 || trimResult.durationSeconds > 0)) {
      final trimmed = await AudioExtractorService().trimAudio(
        path,
        startSeconds: trimResult.startSeconds,
        durationSeconds: trimResult.durationSeconds,
      );
      if (trimmed != null && trimmed.isNotEmpty) {
        finalPath = trimmed;
      }
    }

    if (!mounted) return;
    setState(() {
      _defaultSoundPath = finalPath;
      _defaultAudioStartSeconds = trimResult?.startSeconds ?? 0;
      _defaultAudioDurationSeconds = trimResult?.durationSeconds ?? 30;
    });
  }

  Future<void> _trimDefaultSound() async {
    if (_defaultSoundPath == null || _defaultSoundPath!.isEmpty) return;

    final trimResult = await AudioTrimDialog.show(
      context,
      soundPath: _defaultSoundPath!,
      initialStartSeconds: _defaultAudioStartSeconds ?? 0,
      initialDurationSeconds: _defaultAudioDurationSeconds ?? 30,
    );

    if (trimResult != null && mounted) {
      String finalPath = _defaultSoundPath!;
      final trimmed = await AudioExtractorService().trimAudio(
        _defaultSoundPath!,
        startSeconds: trimResult.startSeconds,
        durationSeconds: trimResult.durationSeconds,
      );
      if (trimmed != null && trimmed.isNotEmpty) {
        finalPath = trimmed;
      }

      if (!mounted) return;
      setState(() {
        _defaultSoundPath = finalPath;
        _defaultAudioStartSeconds = trimResult.startSeconds;
        _defaultAudioDurationSeconds = trimResult.durationSeconds;
      });
    }
  }

  void _removeDefaultSound() => setState(() {
        _defaultSoundPath = null;
        _defaultAudioStartSeconds = null;
        _defaultAudioDurationSeconds = null;
      });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StepIndicator(currentStep: _currentStep),
              const SizedBox(height: 20),
              Text(
                _currentStep == 0
                    ? 'Nombre y color'
                    : 'Icono y personalización',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 420,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    NameAndColorStep(
                      nameController: _nameController,
                      colors: _colors,
                      selectedColor: _selectedColor,
                      onColorSelected: (color) {
                        setState(() => _selectedColor = color);
                      },
                    ),
                    IconAndCustomizationStep(
                      icons: _icons,
                      selectedIcon: _selectedIcon,
                      selectedColor: _selectedColor,
                      imagePath: _imagePath,
                      visualMode: _visualMode,
                      onVisualModeChanged: (mode) {
                        setState(() => _visualMode = mode);
                      },
                      defaultSoundPath: _defaultSoundPath,
                      defaultAudioStartSeconds: _defaultAudioStartSeconds,
                      defaultAudioDurationSeconds:
                          _defaultAudioDurationSeconds,
                      onIconSelected: (icon) {
                        setState(() => _selectedIcon = icon);
                      },
                      onPickImage: _pickAndCropImage,
                      onRemoveImage: _removeImage,
                      onPickSound: _pickDefaultSound,
                      onTrimSound: _trimDefaultSound,
                      onRemoveSound: _removeDefaultSound,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_currentStep == 1)
                    Expanded(
                      child: GestureDetector(
                        onTap: _previousStep,
                        child: Container(
                          height: AppConstants.controlHeight,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius,
                            ),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Volver',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep == 1) const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _nextStep,
                      child: Container(
                        height: AppConstants.controlHeight,
                        decoration: AppDecorations.neonButton,
                        alignment: Alignment.center,
                        child: Text(
                          _currentStep == 0
                              ? 'Siguiente'
                              : (widget.initialCategory != null
                                  ? 'Guardar'
                                  : 'Crear'),
                          style: textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF152000),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
