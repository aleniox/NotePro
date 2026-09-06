import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../core/theme/card_colors.dart';
import '../core/utils/app_snackbar.dart';
import '../providers/notes_provider.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  void _confirmEmptyTrash(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dọn sạch Thùng rác?'),
        content: const Text('Tất cả ghi chú trong thùng rác sẽ bị xóa vĩnh viễn và không thể khôi phục. Bạn có chắc chắn muốn xóa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<NotesProvider>(context, listen: false).emptyTrash();
              Navigator.pop(ctx);
              AppSnackBar.showTrash(context, 'Đã dọn sạch thùng rác');
            },
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final trash = notesProvider.trashNotes;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / 280).floor().clamp(1, 6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rác'),
        actions: [
          if (trash.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              label: const Text('Dọn sạch', style: TextStyle(color: Colors.redAccent)),
              onPressed: () => _confirmEmptyTrash(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: trash.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Thùng rác đang trống',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: MasonryGridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: trash.length,
                itemBuilder: (context, index) {
                  final note = trash[index];
                  final palette = CardPalette.getColor(note.colorIndex);
                  final cardBg = palette.getBackground(isDark);
                  final cardBorder = palette.getBorder(isDark);
                  final textColor = palette.getText(isDark);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title.isEmpty ? 'Ghi chú không tiêu đề' : note.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (note.content.isNotEmpty)
                          Text(
                            note.content,
                            style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.8)),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.restore, size: 16),
                              label: const Text('Khôi phục'),
                              onPressed: () {
                                notesProvider.restoreFromTrash(note);
                                AppSnackBar.showSuccess(context, 'Đã khôi phục ghi chú');
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, size: 18, color: Colors.redAccent),
                              tooltip: 'Xóa vĩnh viễn',
                              onPressed: () {
                                notesProvider.deletePermanently(note.id);
                                AppSnackBar.showTrash(context, 'Đã xóa vĩnh viễn ghi chú');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
