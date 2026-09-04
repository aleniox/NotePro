import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/card_colors.dart';
import '../core/utils/file_helper.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../screens/note_editor_screen.dart';

class NoteCardWidget extends StatefulWidget {
  final NoteModel note;
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const NoteCardWidget({
    super.key,
    required this.note,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  @override
  State<NoteCardWidget> createState() => _NoteCardWidgetState();
}

class _NoteCardWidgetState extends State<NoteCardWidget> {
  bool _isHovered = false;

  void _openEditor(BuildContext context) {
    if (widget.note.isLocked) {
      _promptUnlock(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteEditorScreen(note: widget.note),
        ),
      );
    }
  }

  void _promptUnlock(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 8),
            Text('Mở khóa ghi chú'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ghi chú này đã được khóa bằng mã PIN.'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nhập mã PIN',
                prefixIcon: Icon(Icons.password),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text == widget.note.pinCode) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorScreen(note: widget.note),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mã PIN không chính xác!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Mở khóa'),
          ),
        ],
      ),
    );
  }

  void _showColorPickerModal(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn màu sắc cho Thẻ Note',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(CardPalette.colors.length, (index) {
                final palette = CardPalette.getColor(index);
                final isSelected = widget.note.colorIndex == index;
                return InkWell(
                  onTap: () {
                    notesProvider.changeNoteColor(widget.note, index);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.getBackground(isDark),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : palette.getBorder(isDark),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 20, color: palette.getText(isDark))
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset globalPos) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final isPinned = widget.note.isPinned;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx + 1,
        globalPos.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: 'toggle_complete',
          child: Row(
            children: [
              Icon(
                widget.note.isCompleted ? Icons.radio_button_unchecked_rounded : Icons.check_circle_rounded,
                size: 18,
                color: widget.note.isCompleted ? null : Colors.green,
              ),
              const SizedBox(width: 10),
              Text(widget.note.isCompleted ? 'Đánh dấu chưa xong' : 'Đánh dấu đã hoàn thành'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 18),
              const SizedBox(width: 10),
              Text(isPinned ? 'Bỏ ghim' : 'Ghim lên đầu trang'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'color',
          child: Row(
            children: [
              Icon(Icons.palette_outlined, size: 18),
              SizedBox(width: 10),
              Text('Đổi màu ghi chú'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy_outlined, size: 18),
              SizedBox(width: 10),
              Text('Nhân đôi ghi chú'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.file_download_outlined, size: 18),
              SizedBox(width: 10),
              Text('Lưu thành tệp văn bản'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_outlined, size: 18),
              SizedBox(width: 10),
              Text('Chuyển vào Lưu trữ'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'trash',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              SizedBox(width: 10),
              Text('Chuyển vào Thùng rác', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted) return;

    if (selected == 'toggle_complete') {
      notesProvider.toggleDeadlineCompleted(widget.note);
    } else if (selected == 'pin') {
      notesProvider.togglePin(widget.note);
    } else if (selected == 'color') {
      _showColorPickerModal(context);
    } else if (selected == 'duplicate') {
      notesProvider.duplicateNote(widget.note);
    } else if (selected == 'export') {
      final path = await FileHelper.exportNoteToMarkdown(widget.note);
      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xuất ghi chú: $path')),
        );
      }
    } else if (selected == 'archive') {
      notesProvider.toggleArchive(widget.note);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chuyển ghi chú vào mục Lưu trữ')),
      );
    } else if (selected == 'trash') {
      notesProvider.moveToTrash(widget.note);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chuyển ghi chú vào Thùng rác')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = CardPalette.getColor(widget.note.colorIndex);
    final cardBg = palette.getBackground(isDark);
    final cardBorder = palette.getBorder(isDark);
    final textColor = palette.getText(isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _openEditor(context),
        onLongPressStart: (details) => _showContextMenu(context, details.globalPosition),
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.6)
                  : cardBorder,
              width: _isHovered ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? (isDark ? 0.35 : 0.08) : 0.03),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Checkbox, Title & Pin Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick complete check button
                    Tooltip(
                      message: widget.note.isCompleted ? 'Đánh dấu chưa hoàn thành' : 'Đánh dấu đã hoàn thành',
                      child: InkWell(
                        onTap: () => notesProvider.toggleDeadlineCompleted(widget.note),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 7, top: 1),
                          child: Icon(
                            widget.note.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 19,
                            color: widget.note.isCompleted
                                ? Colors.green
                                : textColor.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ),
                    if (widget.note.isLocked) ...[
                      const Icon(Icons.lock_rounded, size: 18, color: Colors.amber),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        widget.note.title.isEmpty ? 'Ghi chú không tiêu đề' : widget.note.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.note.isCompleted ? textColor.withOpacity(0.5) : textColor,
                          fontStyle: widget.note.title.isEmpty ? FontStyle.italic : FontStyle.normal,
                          decoration: widget.note.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Pin Button
                    InkWell(
                      onTap: () => notesProvider.togglePin(widget.note),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          widget.note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 18,
                          color: widget.note.isPinned
                              ? Theme.of(context).colorScheme.primary
                              : textColor.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Deadline Badge if set
                if (widget.note.reminderDateTime != null) ...[
                  Builder(
                    builder: (context) {
                      final deadline = widget.note.reminderDateTime!;
                      final now = DateTime.now();
                      final isOverdue = deadline.isBefore(now) && !widget.note.isCompleted;
                      final isDone = widget.note.isCompleted;

                      Color badgeBg;
                      Color badgeBorder;
                      Color badgeText;
                      IconData badgeIcon;

                      if (isDone) {
                        badgeBg = Colors.green.withOpacity(0.12);
                        badgeBorder = Colors.green.withOpacity(0.4);
                        badgeText = Colors.green.shade700;
                        badgeIcon = Icons.check_circle_rounded;
                      } else if (isOverdue) {
                        badgeBg = Colors.red.withOpacity(0.12);
                        badgeBorder = Colors.red.withOpacity(0.4);
                        badgeText = Colors.red.shade700;
                        badgeIcon = Icons.error_outline_rounded;
                      } else {
                        badgeBg = Colors.amber.withOpacity(0.12);
                        badgeBorder = Colors.amber.withOpacity(0.4);
                        badgeText = Colors.amber.shade800;
                        badgeIcon = Icons.alarm_rounded;
                      }

                      return InkWell(
                        onTap: () => notesProvider.toggleDeadlineCompleted(widget.note),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 14, color: badgeText),
                              const SizedBox(width: 5),
                              Text(
                                isDone
                                    ? 'Đã xong: ${deadline.day}/${deadline.month}'
                                    : (isOverdue
                                        ? 'Quá hạn: ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')} ${deadline.day}/${deadline.month}'
                                        : 'Hạn chót: ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')} ${deadline.day}/${deadline.month}'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: badgeText,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isDone ? Icons.undo_rounded : Icons.check_rounded,
                                size: 12,
                                color: badgeText,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // Content Preview / Locked State
                if (widget.note.isLocked) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: textColor.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(
                          'Nội dung đã được khóa bảo mật',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Plain Content preview
                  if (widget.note.content.isNotEmpty) ...[
                    Text(
                      widget.note.content,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: textColor.withOpacity(0.85),
                        height: 1.4,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Checklist preview (Interactive on card!)
                  if (widget.note.checklist.isNotEmpty) ...[
                    ...widget.note.checklist.take(4).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: item.isDone,
                                activeColor: Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (_) {
                                  notesProvider.toggleChecklistItem(widget.note, item.id);
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: item.isDone
                                      ? textColor.withOpacity(0.5)
                                      : textColor.withOpacity(0.9),
                                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (widget.note.checklist.length > 4) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 2),
                        child: Text(
                          '+ ${widget.note.checklist.length - 4} mục khác...',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textColor.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ],

                // Tags chips
                if (widget.note.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.note.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Footer: Folder badge & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.note.folderName != null && widget.note.folderName!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_outlined, size: 12, color: textColor.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              widget.note.folderName!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(),
                    Text(
                      DateFormat('dd/MM/yyyy').format(widget.note.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
