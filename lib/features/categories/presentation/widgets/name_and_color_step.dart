import 'package:flutter/material.dart';

/// Paso 1 del diálogo de creación de categoría: nombre y color.
class NameAndColorStep extends StatelessWidget {
  final TextEditingController nameController;
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const NameAndColorStep({
    super.key,
    required this.nameController,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nombre de la categoría', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 24),
          Text('Elige un color', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              final selected = color == selectedColor;
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 38 : 32,
                  height: selected ? 38 : 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: selected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.black, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
