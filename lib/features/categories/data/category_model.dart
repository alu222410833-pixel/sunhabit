// ignore_for_file: non_const_argument_for_const_parameter

import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final IconData? icon;
  final Color? iconColor;
  final String? imagePath;
  final String? defaultSoundPath;
  final int? defaultAudioStartSeconds;
  final int? defaultAudioDurationSeconds;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    this.iconColor,
    this.imagePath,
    this.defaultSoundPath,
    this.defaultAudioStartSeconds,
    this.defaultAudioDurationSeconds,
  });

  String get defaultSoundFileName {
    if (defaultSoundPath == null || defaultSoundPath!.isEmpty) return '';
    return defaultSoundPath!.split(RegExp(r'[/\\]')).last;
  }

  String? get defaultAudioFragmentText {
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

  Category copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
    Color? iconColor,
    String? imagePath,
    String? defaultSoundPath,
    int? defaultAudioStartSeconds,
    int? defaultAudioDurationSeconds,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      imagePath: imagePath ?? this.imagePath,
      defaultSoundPath: defaultSoundPath ?? this.defaultSoundPath,
      defaultAudioStartSeconds:
          defaultAudioStartSeconds ?? this.defaultAudioStartSeconds,
      defaultAudioDurationSeconds:
          defaultAudioDurationSeconds ?? this.defaultAudioDurationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'icon': icon != null
            ? {
                'codePoint': icon!.codePoint,
                'fontFamily': icon!.fontFamily ?? 'MaterialIcons',
              }
            : null,
        'iconColor': iconColor?.toARGB32(),
        'imagePath': imagePath,
        'defaultSoundPath': defaultSoundPath,
        'defaultAudioStartSeconds': defaultAudioStartSeconds,
        'defaultAudioDurationSeconds': defaultAudioDurationSeconds,
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    final iconJson = json['icon'] as Map<String, dynamic>?;
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: iconJson != null
          ? IconData(
              iconJson['codePoint'] as int,
              fontFamily: iconJson['fontFamily'] as String? ?? 'MaterialIcons',
            )
          : null,
      iconColor:
          json['iconColor'] != null ? Color(json['iconColor'] as int) : null,
      imagePath: json['imagePath'] as String?,
      defaultSoundPath: json['defaultSoundPath'] as String?,
      defaultAudioStartSeconds: json['defaultAudioStartSeconds'] as int?,
      defaultAudioDurationSeconds: json['defaultAudioDurationSeconds'] as int?,
    );
  }
}

final List<Category> defaultCategories = [
  const Category(
    id: 'health',
    name: 'Salud',
    color: AppColors.green,
    icon: Icons.favorite_outline_rounded,
    iconColor: AppColors.green,
  ),
  const Category(
    id: 'study',
    name: 'Estudio',
    color: AppColors.purple,
    icon: Icons.menu_book_rounded,
    iconColor: AppColors.purple,
  ),
  const Category(
    id: 'work',
    name: 'Trabajo',
    color: AppColors.gold,
    icon: Icons.work_outline_rounded,
    iconColor: AppColors.gold,
  ),
];
