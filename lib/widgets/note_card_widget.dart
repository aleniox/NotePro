import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/card_colors.dart';
import '../core/utils/app_snackbar.dart';
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
                AppSnackBar.showWarning(context, 'Mã PIN không chính xác!');
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

  List<PopupMenuEntry<String>> _buildCardMenuItems(BuildContext context, bool isDark) {
    final isPinned = widget.note.isPinned;
    final isDone = widget.note.isCompleted;
    final itemTextColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    PopupMenuItem<String> buildItem({
      required String value,
      required IconData icon,
      required Color iconColor,
      required Color iconBgColor,
      required String text,
      Color? textColor,
      bool isBold = false,
    }) {
      return PopupMenuItem<String>(
        value: value,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: -0.1,
                  color: textColor ?? itemTextColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return [
      buildItem(
        value: 'toggle_complete',
        icon: isDone ? Icons.undo_rounded : Icons.check_circle_rounded,
        iconColor: isDone ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        iconBgColor: (isDone ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.12),
        text: isDone ? 'Đánh dấu chưa xong' : 'Đánh dấu đã hoàn thành',
      ),
      buildItem(
        value: 'pin',
        icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
        iconColor: const Color(0xFF6366F1),
        iconBgColor: const Color(0xFF6366F1).withOpacity(0.12),
        text: isPinned ? 'Bỏ ghim thẻ' : 'Ghim thẻ lên đầu trang',
      ),
      buildItem(
        value: 'color',
        icon: Icons.palette_rounded,
        iconColor: const Color(0xFF8B5CF6),
        iconBgColor: const Color(0xFF8B5CF6).withOpacity(0.12),
        text: 'Đổi màu sắc thẻ',
      ),
      buildItem(
        value: 'duplicate',
        icon: Icons.copy_rounded,
        iconColor: const Color(0xFF3B82F6),
        iconBgColor: const Color(0xFF3B82F6).withOpacity(0.12),
        text: 'Nhân đôi ghi chú',
      ),
      buildItem(
        value: 'export',
        icon: Icons.file_download_rounded,
        iconColor: const Color(0xFF14B8A6),
        iconBgColor: const Color(0xFF14B8A6).withOpacity(0.12),
        text: 'Lưu thành tệp văn bản',
      ),
      buildItem(
        value: 'archive',
        icon: Icons.archive_rounded,
        iconColor: const Color(0xFFF97316),
        iconBgColor: const Color(0xFFF97316).withOpacity(0.12),
        text: 'Chuyển vào Lưu trữ',
      ),
      const PopupMenuDivider(height: 8),
      buildItem(
        value: 'trash',
        icon: Icons.delete_outline_rounded,
        iconColor: const Color(0xFFEF4444),
        iconBgColor: const Color(0xFFEF4444).withOpacity(0.12),
        text: 'Chuyển vào Thùng rác',
        textColor: const Color(0xFFEF4444),
        isBold: true,
      ),
    ];
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    if (action == 'toggle_complete') {
      notesProvider.toggleDeadlineCompleted(widget.note);
    } else if (action == 'pin') {
      notesProvider.togglePin(widget.note);
    } else if (action == 'color') {
      _showColorPickerModal(context);
    } else if (action == 'duplicate') {
      notesProvider.duplicateNote(widget.note);
      AppSnackBar.showSuccess(context, 'Đã nhân bản ghi chú');
    } else if (action == 'export') {
      final path = await FileHelper.exportNoteToMarkdown(widget.note);
      if (path != null && context.mounted) {
        AppSnackBar.showSuccess(context, 'Đã xuất ghi chú: $path');
      }
    } else if (action == 'archive') {
      notesProvider.toggleArchive(widget.note);
      AppSnackBar.showInfo(context, 'Đã chuyển ghi chú vào mục Lưu trữ');
    } else if (action == 'trash') {
      notesProvider.moveToTrash(widget.note);
      AppSnackBar.showTrash(
        context,
        'Đã chuyển ghi chú vào Thùng rác',
        undoLabel: 'Hoàn tác',
        onUndo: () => notesProvider.restoreFromTrash(widget.note),
      );
    }
  }

  void _showContextMenu(BuildContext context, Offset globalPos) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected = await showMenu<String>(
      context: context,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx + 1,
        globalPos.dy + 1,
      ),
      items: _buildCardMenuItems(context, isDark),
    );

    if (selected != null && context.mounted) {
      _handleMenuAction(context, selected);
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
                // Header: Checkbox, Title & Pin/Menu Buttons
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Quick complete check button
                      Tooltip(
                        message: widget.note.isCompleted ? 'Đánh dấu chưa hoàn thành' : 'Đánh dấu đã hoàn thành',
                        child: InkWell(
                          onTap: () => notesProvider.toggleDeadlineCompleted(widget.note),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
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
                        const Icon(Icons.lock_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                      ],
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          widget.note.title.isEmpty ? 'Ghi chú không tiêu đề' : widget.note.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: widget.note.isCompleted ? textColor.withOpacity(0.5) : textColor,
                            fontStyle: widget.note.title.isEmpty ? FontStyle.italic : FontStyle.normal,
                            decoration: widget.note.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Pin Button
                      InkWell(
                        onTap: () => notesProvider.togglePin(widget.note),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            widget.note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 17,
                            color: widget.note.isPinned
                                ? Theme.of(context).colorScheme.primary
                                : textColor.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
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

                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: InkWell(
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
                        Flexible(
                          child: Text(
                            'Nội dung đã được khóa bảo mật',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
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
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Footer: Folder badge & Date
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (widget.note.folderName != null && widget.note.folderName!.isNotEmpty)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
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
                        ),
                      ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(widget.note.updatedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withOpacity(0.5),
                        ),
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
