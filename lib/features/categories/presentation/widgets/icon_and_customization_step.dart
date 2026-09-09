import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sunhabit/core/constants/app_constants.dart';
import 'package:sunhabit/core/theme/app_colors.dart';
import 'package:sunhabit/features/alarms/presentation/widgets/sound_picker_tile.dart';

/// Paso 2 del diálogo de creación de categoría: icono, imagen y sonido.
class IconAndCustomizationStep extends StatelessWidget {
  final List<IconData> icons;
  final IconData? selectedIcon;
  final Color selectedColor;
  final String? imagePath;
  /// 0 = icono, 1 = imagen.
  final int visualMode;
  final ValueChanged<int> onVisualModeChanged;
  final String? defaultSoundPath;
  final int? defaultAudioStartSeconds;
  final int? defaultAudioDurationSeconds;
  final ValueChanged<IconData> onIconSelected;
  final ValueChanged<ImageSource> onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onPickSound;
  final VoidCallback onTrimSound;
  final VoidCallback onRemoveSound;

  const IconAndCustomizationStep({
    super.key,
    required this.icons,
    required this.selectedIcon,
    required this.selectedColor,
    required this.imagePath,
    required this.visualMode,
    required this.onVisualModeChanged,
    required this.defaultSoundPath,
    this.defaultAudioStartSeconds,
    this.defaultAudioDurationSeconds,
    required this.onIconSelected,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onPickSound,
    required this.onTrimSound,
    required this.onRemoveSound,
  });

  String get _soundFileName {
    if (defaultSoundPath == null || defaultSoundPath!.isEmpty) return '';
    return defaultSoundPath!.split(RegExp(r'[/\\]')).last;
  }

  String? get _fragmentText {
    if (defaultSoundPath == null || defaultSoundPath!.isEmpty) return null;
    final start = defaultAudioStartSeconds ?? 0;
    final duration = defaultAudioDurationSeconds ?? 30;
    final end = start + duration;
    final startStr =
        '${(start ~/ 60).toString().padLeft(2, '0')}:${(start % 60).toString().padLeft(2, '0')}';
    final endStr =
        '${(end ~/ 60).toString().padLeft(2, '0')}:${(end % 60).toString().padLeft(2, '0')}';
    return '$startStr - $endStr (${duration}s)';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasSound = defaultSoundPath != null && defaultSoundPath!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Visual de la categoría',
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _VisualModeTabs(
            visualMode: visualMode,
            onChanged: onVisualModeChanged,
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: visualMode == 0
                ? _IconGrid(
                    key: const ValueKey('icon'),
                    icons: icons,
                    selectedIcon: selectedIcon,
                    selectedColor: selectedColor,
                    onIconSelected: onIconSelected,
                  )
                : _ImagePickerRow(
                    key: const ValueKey('image'),
                    imagePath: imagePath,
                    onPickImage: onPickImage,
                    onRemoveImage: onRemoveImage,
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            'Sonido de alarma predeterminado (opcional)',
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SoundPickerTile(
            displayLabel: hasSound
                ? _soundFileName
                : 'Predeterminado del sistema / app',
            fragmentText: _fragmentText,
            hasSound: hasSound,
            onPick: onPickSound,
            onTrim: onTrimSound,
            onRemove: onRemoveSound,
          ),
        ],
      ),
    );
  }
}

class _VisualModeTabs extends StatelessWidget {
  final int visualMode;
  final ValueChanged<int> onChanged;

  const _VisualModeTabs({required this.visualMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.borderDark),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Icono',
              icon: Icons.emoji_objects_outlined,
              selected: visualMode == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Imagen',
              icon: Icons.image_outlined,
              selected: visualMode == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.neonGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius - 4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? const Color(0xFF152000)
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                color: selected
                    ? const Color(0xFF152000)
                    : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  final List<IconData> icons;
  final IconData? selectedIcon;
  final Color selectedColor;
  final ValueChanged<IconData> onIconSelected;

  const _IconGrid({
    super.key,
    required this.icons,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: icons.map((icon) {
        final selected = icon == selectedIcon;
        return GestureDetector(
          onTap: () => onIconSelected(icon),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? selectedColor.withValues(alpha: 0.15)
                  : AppColors.surfaceHighest,
              border: Border.all(
                color: selected ? selectedColor : AppColors.borderDark,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: selected ? selectedColor : AppColors.textSecondary,
              size: 26,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ImagePickerRow extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<ImageSource> onPickImage;
  final VoidCallback onRemoveImage;

  const _ImagePickerRow({
    super.key,
    required this.imagePath,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    if (hasImage) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighest,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Imagen seleccionada',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: onRemoveImage,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              tooltip: 'Quitar imagen',
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onPickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Galería'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.borderDark),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.cardRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onPickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Cámara'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.borderDark),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.cardRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
