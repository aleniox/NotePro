import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../providers/notes_provider.dart';
import '../widgets/note_card_widget.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final archived = notesProvider.archivedNotes;
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / 280).floor().clamp(1, 6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thẻ đã lưu trữ'),
      ),
      body: archived.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Không có ghi chú nào trong mục lưu trữ',
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
                itemCount: archived.length,
                itemBuilder: (context, index) {
                  final note = archived[index];
                  return Stack(
                    children: [
                      NoteCardWidget(note: note),
                      Positioned(
                        top: 8,
                        right: 36,
                        child: IconButton(
                          icon: const Icon(Icons.unarchive_outlined, size: 20),
                          tooltip: 'Khôi phục về trang chính',
                          onPressed: () {
                            notesProvider.toggleArchive(note);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã chuyển ghi chú về trang chính')),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
