import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import 'note_card_widget.dart';

enum KanbanGroupMode {
  status, // 📋 Tiến độ công việc (Ưu tiên & Gấp / Cần làm / Đã hoàn thành)
  folder, // 📁 Danh mục thư mục
}

class KanbanView extends StatefulWidget {
  final List<NoteModel> notes;

  const KanbanView({super.key, required this.notes});

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  final ScrollController _horizontalController = ScrollController();
  KanbanGroupMode _groupMode = KanbanGroupMode.status;
  bool _isHoveringScrollableList = false;

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _horizontalController.hasClients) {
      if (event.scrollDelta.dx != 0) return;

      final isShift = HardwareKeyboard.instance.isShiftPressed;
      if (!_isHoveringScrollableList || isShift) {
        final double delta = event.scrollDelta.dy;
        if (delta != 0) {
          final double target = (_horizontalController.offset + delta).clamp(
            0.0,
            _horizontalController.position.maxScrollExtent,
          );
          _horizontalController.jumpTo(target);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final notesProvider = Provider.of<NotesProvider>(context);
    final folders = notesProvider.folders;

    final List<Widget> columns = [];

    if (_groupMode == KanbanGroupMode.status) {
      // 1. Priority & Urgent (Pinned or deadline within 3 days or overdue)
      final now = DateTime.now();
      final urgentThreshold = DateTime(now.year, now.month, now.day + 3, 23, 59, 59);

      final urgentNotes = widget.notes.where((n) {
        if (n.isCompleted) return false;
        if (n.isPinned) return true;
        if (n.reminderDateTime != null && n.reminderDateTime!.isBefore(urgentThreshold)) return true;
        return false;
      }).toList();

      // 2. To-Do (Regular uncompleted notes)
      final todoNotes = widget.notes.where((n) {
        if (n.isCompleted) return false;
        if (n.isPinned) return false;
        if (n.reminderDateTime != null && n.reminderDateTime!.isBefore(urgentThreshold)) return false;
        return true;
      }).toList();

      // 3. Completed notes
      final doneNotes = widget.notes.where((n) => n.isCompleted).toList();

      columns.add(
        _KanbanColumn(
          title: 'Ưu tiên & Sắp đến hạn',
          color: const Color(0xFFF59E0B),
          notes: urgentNotes,
          emptyMessage: 'Không có việc gấp hay cận hạn',
          onHoverScrollableList: (hovering) => _isHoveringScrollableList = hovering,
        ),
      );

      columns.add(
        _KanbanColumn(
          title: 'Cần làm (To-Do)',
          color: const Color(0xFF6366F1),
          notes: todoNotes,
          emptyMessage: 'Tuyệt vời! Không còn việc tồn đọng',
          onHoverScrollableList: (hovering) => _isHoveringScrollableList = hovering,
        ),
      );

      columns.add(
        _KanbanColumn(
          title: 'Đã hoàn thành',
          color: const Color(0xFF10B981),
          notes: doneNotes,
          emptyMessage: 'Chưa có việc nào hoàn thành',
          onHoverScrollableList: (hovering) => _isHoveringScrollableList = hovering,
        ),
      );
    } else {
      // Group by folder
      final Map<String, List<NoteModel>> groupedNotes = {};
      groupedNotes['default'] = widget.notes.where((n) => n.folderId == null || n.folderId!.isEmpty).toList();

      for (final folder in folders) {
        groupedNotes[folder.id] = widget.notes.where((n) => n.folderId == folder.id).toList();
      }

      columns.add(
        _KanbanColumn(
          title: 'Chung (Chưa phân loại)',
          color: Colors.blueGrey,
          notes: groupedNotes['default'] ?? [],
          onHoverScrollableList: (hovering) => _isHoveringScrollableList = hovering,
        ),
      );

      for (final folder in folders) {
        columns.add(
          _KanbanColumn(
            title: folder.name,
            color: Color(folder.colorValue),
            notes: groupedNotes[folder.id] ?? [],
            onHoverScrollableList: (hovering) => _isHoveringScrollableList = hovering,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Switcher Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Sắp xếp bảng theo:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                _GroupPill(
                  label: 'Tiến độ công việc (Gấp / To-Do / Xong)',
                  icon: Icons.checklist_rounded,
                  isSelected: _groupMode == KanbanGroupMode.status,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => setState(() => _groupMode = KanbanGroupMode.status),
                ),
                const SizedBox(width: 8),
                _GroupPill(
                  label: 'Danh mục thư mục',
                  icon: Icons.folder_outlined,
                  isSelected: _groupMode == KanbanGroupMode.folder,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => setState(() => _groupMode = KanbanGroupMode.folder),
                ),
              ],
            ),
          ),
        ),

        // Horizontal Board with Scrollbar
        Expanded(
          child: Listener(
            onPointerSignal: _onPointerSignal,
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 10,
              radius: const Radius.circular(5),
              child: ListView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                children: columns,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _GroupPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.6)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? primaryColor : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : primaryColor)
                    : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatefulWidget {
  final String title;
  final Color color;
  final List<NoteModel> notes;
  final String? emptyMessage;
  final ValueChanged<bool> onHoverScrollableList;

  const _KanbanColumn({
    super.key,
    required this.title,
    required this.color,
    required this.notes,
    this.emptyMessage,
    required this.onHoverScrollableList,
  });

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

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
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.notes.length.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cards list in column
          Expanded(
            child: widget.notes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.emptyMessage ?? 'Chưa có thẻ ghi chú nào',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                  )
                : MouseRegion(
                    onEnter: (_) => widget.onHoverScrollableList(true),
                    onExit: (_) => widget.onHoverScrollableList(false),
                    child: Scrollbar(
                      controller: _verticalController,
                      thumbVisibility: false,
                      interactive: true,
                      child: ListView.builder(
                        controller: _verticalController,
                        padding: const EdgeInsets.all(10),
                        itemCount: widget.notes.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NoteCardWidget(note: widget.notes[index]),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
