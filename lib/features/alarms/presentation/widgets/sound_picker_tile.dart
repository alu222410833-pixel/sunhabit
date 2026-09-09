import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

/// Tile reutilizable para seleccionar, recortar y quitar un sonido de alarma.
///
/// Unifica la UI que se duplicaba entre el selector de sonido por defecto de
/// una categoría y el selector de sonido de cada recordatorio de un hábito.
class SoundPickerTile extends StatelessWidget {
  /// Etiqueta principal que describe el sonido seleccionado.
  final String displayLabel;

  /// Texto opcional del fragmento (p. ej. `00:15 - 00:45 (30s)`).
  final String? fragmentText;

  /// Indica si hay un sonido válido (propio o heredado) configurado.
  final bool hasSound;

  /// Si se debe mostrar el botón de quitar sonido.
  ///
  /// Normalmente `true` solo cuando el usuario eligió un sonido propio; se
  /// omite cuando el sonido es heredado de la categoría y no se puede quitar
  /// desde este punto.
  final bool canRemove;

  final VoidCallback onPick;
  final VoidCallback onTrim;
  final VoidCallback? onRemove;

  const SoundPickerTile({
    super.key,
    required this.displayLabel,
    this.fragmentText,
    required this.hasSound,
    this.canRemove = true,
    required this.onPick,
    required this.onTrim,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelColor =
        hasSound ? AppColors.textPrimary : AppColors.textSecondary;
    final iconColor =
        hasSound ? AppColors.neonGreen : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPick,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note_rounded, color: iconColor, size: 20),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onPick,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayLabel,
                    style: textTheme.bodyMedium?.copyWith(color: labelColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasSound && fragmentText != null)
                    Text(
                      'Recorte: $fragmentText',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.neonGreen,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (hasSound)
            IconButton(
              onPressed: onTrim,
              icon: const Icon(
                Icons.content_cut_rounded,
                color: AppColors.neonGreen,
                size: 18,
              ),
              tooltip: 'Recortar fragmento',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          if (canRemove && onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 18,
              ),
              tooltip: 'Quitar sonido',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
        ],
      ),
    );
  }
}
