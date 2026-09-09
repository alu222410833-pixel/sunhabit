import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

Future<void> showChecklistEditor(
  BuildContext context, {
  required List<String> checklist,
  required VoidCallback onUpdate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final controller = TextEditingController();
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Objetivos adicionales',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...checklist.asMap().entries.map((entry) => ListTile(
                      dense: true,
                      title: Text(entry.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: AppColors.danger),
                        onPressed: () {
                          setModalState(() => checklist.removeAt(entry.key));
                          onUpdate();
                        },
                      ),
                    )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Nuevo objetivo',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.neonGreen),
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        setModalState(() {
                          checklist.add(text);
                          controller.clear();
                        });
                        onUpdate();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    },
  );
}
