import 'package:flutter/material.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class ChecklistEvaluationBody extends StatelessWidget {
  final TextEditingController checklistController;
  final List<String> checklistItems;
  final VoidCallback onChecklistAdded;
  final ValueChanged<int> onChecklistRemoved;
  final void Function(int oldIndex, int newIndex) onChecklistReordered;

  const ChecklistEvaluationBody({
    super.key,
    required this.checklistController,
    required this.checklistItems,
    required this.onChecklistAdded,
    required this.onChecklistRemoved,
    required this.onChecklistReordered,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ítems del checklist', style: textTheme.titleSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: checklistController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Nuevo ítem',
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onChecklistAdded,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonGreen,
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFF152000)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (checklistItems.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            primary: false,
            padding: EdgeInsets.zero,
            buildDefaultDragHandles: false,
            itemCount: checklistItems.length,
            itemBuilder: (context, index) {
              final item = checklistItems[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey('$item-$index'),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drag_handle_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• $item',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onChecklistRemoved(index),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            onReorderItem: (oldIndex, newIndex) {
              onChecklistReordered(oldIndex, newIndex);
            },
          ),
      ],
    );
  }
}
