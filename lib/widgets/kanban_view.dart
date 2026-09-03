import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import 'note_card_widget.dart';

class KanbanView extends StatelessWidget {
  final List<NoteModel> notes;

  const KanbanView({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final folders = notesProvider.folders;

    // Group notes by folder
    final Map<String, List<NoteModel>> groupedNotes = {};
    
    // Group for "Chung" (Uncategorized)
    groupedNotes['default'] = notes.where((n) => n.folderId == null || n.folderId!.isEmpty).toList();

    for (final folder in folders) {
      groupedNotes[folder.id] = notes.where((n) => n.folderId == folder.id).toList();
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Column: Chưa phân loại
        _KanbanColumn(
          title: 'Chung (Chưa phân loại)',
          color: Colors.blueGrey,
          notes: groupedNotes['default'] ?? [],
        ),
        // Columns for each folder
        ...folders.map((folder) {
          return _KanbanColumn(
            title: folder.name,
            color: Color(folder.colorValue),
            notes: groupedNotes[folder.id] ?? [],
          );
        }),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<NoteModel> notes;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2D) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    notes.length.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cards list in column
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Chưa có thẻ ghi chú nào',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NoteCardWidget(note: notes[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
