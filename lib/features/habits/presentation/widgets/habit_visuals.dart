import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:sunhabit/features/categories/data/category_model.dart';
import 'package:sunhabit/features/habits/data/habit_model.dart';
import 'package:sunhabit/features/habits/data/habits_repository.dart';

/// Helpers para resolver la imagen/icono que representa a un hábito en la UI.
///
/// El orden de resolución es:
/// 1. Imagen propia del hábito.
/// 2. Imagen de su categoría.
/// 3. Icono propio del hábito.
/// 4. Icono de su categoría.
/// 5. Icono por defecto.
extension HabitVisuals on Habit {
  Category? get _category => HabitsRepository().getCategoryById(categoryId);

  String? get effectiveImagePath {
    if (imagePath != null && imagePath!.isNotEmpty) return imagePath;
    final catPath = _category?.imagePath;
    if (catPath != null && catPath.isNotEmpty) return catPath;
    return null;
  }

  IconData get effectiveIcon =>
      icon ?? _category?.icon ?? Icons.check_circle_outline;
}

/// Muestra la imagen de un hábito (o su categoría) recortada en círculo.
///
/// Si no hay imagen disponible, devuelve un [SizedBox.shrink] para que el
/// llamador pueda mostrar el icono por defecto.
class HabitImageAvatar extends StatelessWidget {
  final String imagePath;
  final double size;

  const HabitImageAvatar({
    super.key,
    required this.imagePath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.file(
        io.File(imagePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => SizedBox(
          width: size,
          height: size,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
