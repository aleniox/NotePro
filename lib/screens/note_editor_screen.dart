import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/theme/card_colors.dart';
import '../core/utils/file_helper.dart';
import '../models/checklist_item.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagInputController;
  late TextEditingController _checklistInputController;

  late String _noteId;
  late int _colorIndex;
  late bool _isPinned;
  late bool _isArchived;
  late bool _isLocked;
  String? _pinCode;
  String? _selectedFolderId;
  String? _selectedFolderName;
  late List<String> _tags;
  late List<ChecklistItem> _checklist;
  late DateTime _createdAt;
  DateTime? _reminderDateTime;
  bool _isCompleted = false;

  bool _showPreview = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final n = widget.note;
    if (n != null && n.id.isNotEmpty) {
      _noteId = n.id;
      _titleController = TextEditingController(text: n.title);
      _contentController = TextEditingController(text: n.content);
      _colorIndex = n.colorIndex;
      _isPinned = n.isPinned;
      _isArchived = n.isArchived;
      _isLocked = n.isLocked;
      _pinCode = n.pinCode;
      _selectedFolderId = n.folderId;
      _selectedFolderName = n.folderName;
      _tags = List.from(n.tags);
      _checklist = n.checklist.map((e) => ChecklistItem(id: e.id, text: e.text, isDone: e.isDone)).toList();
      _createdAt = n.createdAt;
      _reminderDateTime = n.reminderDateTime;
      _isCompleted = n.isCompleted;
    } else {
      _noteId = const Uuid().v4();
      _titleController = TextEditingController(text: n?.title ?? '');
      _contentController = TextEditingController(text: n?.content ?? '');
      _colorIndex = n?.colorIndex ?? 0;
      _isPinned = n?.isPinned ?? false;
      _isArchived = false;
      _isLocked = false;
      _pinCode = null;
      _selectedFolderId = n?.folderId;
      _selectedFolderName = n?.folderName;
      _tags = n != null ? List.from(n.tags) : [];
      _checklist = n != null
          ? n.checklist.map((e) => ChecklistItem(id: e.id, text: e.text, isDone: e.isDone)).toList()
          : [];
      _createdAt = DateTime.now();
      _reminderDateTime = n?.reminderDateTime;
      _isCompleted = false;
    }

    _tagInputController = TextEditingController();
    _checklistInputController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    _checklistInputController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _checklist.isEmpty && _tags.isEmpty) {
      // Empty note, no need to save
      return;
    }

    final note = NoteModel(
      id: _noteId,
      title: title,
      content: content,
      colorIndex: _colorIndex,
      isPinned: _isPinned,
      isArchived: _isArchived,
      isLocked: _isLocked,
      pinCode: _pinCode,
      folderId: _selectedFolderId,
      folderName: _selectedFolderName,
      tags: _tags,
      checklist: _checklist,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      reminderDateTime: _reminderDateTime,
      isCompleted: _isCompleted,
    );

    final provider = Provider.of<NotesProvider>(context, listen: false);
    if (widget.note != null && widget.note!.id.isNotEmpty) {
      provider.updateNote(note);
    } else {
      provider.addNote(note);
    }
  }

  void _insertMarkdown(String prefix, [String suffix = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start < 0) {
      _contentController.text = '$text$prefix$suffix';
      return;
    }

    final selectedText = selection.textInside(text);
    final replacement = '$prefix$selectedText$suffix';
    final newText = selection.textBefore(text) + replacement + selection.textAfter(text);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length,
      ),
    );
  }

  void _addTag(String rawTag) {
    var tag = rawTag.replaceAll('#', '').replaceAll(' ', '').trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputController.clear();
      });
    }
  }

  void _addChecklistItem() {
    final text = _checklistInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklist.add(ChecklistItem(
          id: const Uuid().v4(),
          text: text,
          isDone: false,
        ));
        _checklistInputController.clear();
      });
    }
  }

  void _toggleLockDialog() {
    if (_isLocked) {
      setState(() {
        _isLocked = false;
        _pinCode = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bỏ khóa ghi chú')),
      );
      return;
    }

    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 8),
            Text('Đặt mã PIN khóa ghi chú'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ghi chú này sẽ yêu cầu mã PIN để mở xem.'),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Mã PIN bảo vệ (4 - 6 số)',
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
              if (pinCtrl.text.trim().length >= 4) {
                setState(() {
                  _isLocked = true;
                  _pinCode = pinCtrl.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã khóa ghi chú thành công')),
                );
              }
            },
            child: const Text('Khóa thẻ'),
          ),
        ],
      ),
    );
  }

  void _pickDeadlineDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _reminderDateTime ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Chọn ngày hết hạn (Deadline)',
      confirmText: 'Tiếp tục chọn giờ',
      cancelText: 'Hủy',
    );

    if (pickedDate == null || !mounted) return;

    final initialTime = _reminderDateTime != null
        ? TimeOfDay(hour: _reminderDateTime!.hour, minute: _reminderDateTime!.minute)
        : const TimeOfDay(hour: 17, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Chọn giờ đến hạn',
      confirmText: 'Lưu hạn chót',
      cancelText: 'Hủy',
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _reminderDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _isCompleted = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã đặt hạn chót: ${pickedTime.format(context)} ngày ${pickedDate.day}/${pickedDate.month}/${pickedDate.year}',
        ),
        action: SnackBarAction(
          label: 'Xóa hạn',
          onPressed: () => setState(() => _reminderDateTime = null),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = CardPalette.getColor(_colorIndex);
    final cardBg = palette.getBackground(isDark);
    final cardBorder = palette.getBorder(isDark);
    final textColor = palette.getText(isDark);

    final notesProvider = Provider.of<NotesProvider>(context);
    final folders = notesProvider.folders;

    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveNote();
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
            _saveNote();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã lưu ghi chú!'), duration: Duration(seconds: 1)),
            );
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: cardBg,
            appBar: AppBar(
              backgroundColor: cardBg,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () {
                  _saveNote();
                  Navigator.pop(context);
                },
              ),
              actions: [
                // Pin button
                IconButton(
                  icon: Icon(
                    _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: _isPinned ? Theme.of(context).colorScheme.primary : textColor,
                  ),
                  tooltip: _isPinned ? 'Bỏ ghim' : 'Ghim thẻ',
                  onPressed: () => setState(() => _isPinned = !_isPinned),
                ),
                // Lock button
                IconButton(
                  icon: Icon(
                    _isLocked ? Icons.lock : Icons.lock_open_outlined,
                    color: _isLocked ? Colors.amber : textColor,
                  ),
                  tooltip: _isLocked ? 'Đã khóa (Bấm để mở)' : 'Khóa bảo mật',
                  onPressed: _toggleLockDialog,
                ),
                // Deadline / Reminder Button
                IconButton(
                  icon: Icon(
                    _reminderDateTime != null ? Icons.alarm_on_rounded : Icons.alarm_add_rounded,
                    color: _reminderDateTime != null
                        ? (_isCompleted ? Colors.green : Colors.amber.shade700)
                        : textColor,
                  ),
                  tooltip: _reminderDateTime != null
                      ? 'Hạn chót: ${_reminderDateTime!.hour}:${_reminderDateTime!.minute.toString().padLeft(2, '0')} ngày ${_reminderDateTime!.day}/${_reminderDateTime!.month}'
                      : 'Đặt hạn chót (Deadline)',
                  onPressed: () => _pickDeadlineDateTime(context),
                ),
                // Color Picker Menu
                PopupMenuButton<int>(
                  icon: Icon(Icons.palette_outlined, color: textColor),
                  tooltip: 'Màu thẻ',
                  onSelected: (idx) => setState(() => _colorIndex = idx),
                  itemBuilder: (ctx) => CardPalette.colors.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    return PopupMenuItem<int>(
                      value: idx,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: p.previewColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(p.name),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                // Export Button
                IconButton(
                  icon: Icon(Icons.file_download_outlined, color: textColor),
                  tooltip: 'Xuất ra Markdown',
                  onPressed: () async {
                    _saveNote();
                    final currentNote = NoteModel(
                      id: _noteId,
                      title: _titleController.text,
                      content: _contentController.text,
                      folderName: _selectedFolderName,
                      tags: _tags,
                      checklist: _checklist,
                      createdAt: _createdAt,
                    );
                    final path = await FileHelper.exportNoteToMarkdown(currentNote);
                    if (path != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã xuất: $path')),
                      );
                    }
                  },
                ),
                // Delete note button (if existing note)
                if (widget.note != null && widget.note!.id.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    tooltip: 'Xóa ghi chú này',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xóa ghi chú?'),
                          content: const Text('Bạn có chắc muốn chuyển thẻ ghi chú này vào Thùng rác không?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Hủy'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () {
                                final provider = Provider.of<NotesProvider>(context, listen: false);
                                provider.moveToTrash(widget.note!);
                                Navigator.pop(ctx); // Close dialog
                                Navigator.pop(context); // Close editor
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã chuyển ghi chú vào Thùng rác')),
                                );
                              },
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                // Save button
                FilledButton.icon(
                  onPressed: () {
                    _saveNote();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Lưu'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Folder & Tags metadata line
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            // Folder Selector Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: _selectedFolderId,
                                  hint: Text('Chọn danh mục', style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
                                  icon: Icon(Icons.arrow_drop_down, color: textColor),
                                  style: TextStyle(color: textColor, fontSize: 13),
                                  items: [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Row(
                                        children: [
                                          Icon(Icons.folder_open, size: 16, color: textColor.withOpacity(0.7)),
                                          const SizedBox(width: 6),
                                          const Text('Chung'),
                                        ],
                                      ),
                                    ),
                                    ...folders.map((f) => DropdownMenuItem<String?>(
                                          value: f.id,
                                          child: Row(
                                            children: [
                                              Icon(Icons.folder, size: 16, color: Color(f.colorValue)),
                                              const SizedBox(width: 6),
                                              Text(f.name),
                                            ],
                                          ),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedFolderId = val;
                                      if (val == null) {
                                        _selectedFolderName = null;
                                      } else {
                                        _selectedFolderName = folders.firstWhere((f) => f.id == val).name;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Tags display & Add Tag Input
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ..._tags.map((tag) => Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Chip(
                                            label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                                            deleteIcon: const Icon(Icons.close, size: 14),
                                            onDeleted: () => setState(() => _tags.remove(tag)),
                                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                          ),
                                        )),
                                    SizedBox(
                                      width: 130,
                                      height: 32,
                                      child: TextField(
                                        controller: _tagInputController,
                                        onSubmitted: _addTag,
                                        style: TextStyle(fontSize: 12, color: textColor),
                                        decoration: InputDecoration(
                                          hintText: '+ Gắn #tag',
                                          hintStyle: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: cardBorder),
                                          ),
                                          filled: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Deadline banner if set
                      if (_reminderDateTime != null)
                        Container(
                          margin: const EdgeInsets.only(top: 6, bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isCompleted
                                ? Colors.green.withOpacity(0.12)
                                : Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isCompleted
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.amber.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isCompleted ? Icons.check_circle_rounded : Icons.alarm_rounded,
                                size: 18,
                                color: _isCompleted ? Colors.green : Colors.amber.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isCompleted
                                      ? 'Đã hoàn thành hạn chót: ${_reminderDateTime!.hour}:${_reminderDateTime!.minute.toString().padLeft(2, '0')} ngày ${_reminderDateTime!.day}/${_reminderDateTime!.month}/${_reminderDateTime!.year}'
                                      : 'Hạn chót: ${_reminderDateTime!.hour}:${_reminderDateTime!.minute.toString().padLeft(2, '0')} ngày ${_reminderDateTime!.day}/${_reminderDateTime!.month}/${_reminderDateTime!.year}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _isCompleted ? Colors.green.shade800 : Colors.amber.shade900,
                                    decoration: _isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              // Toggle Done button
                              InkWell(
                                onTap: () => setState(() => _isCompleted = !_isCompleted),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    _isCompleted ? 'Chưa xong' : 'Xong',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _isCompleted ? Colors.grey : Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Edit date
                              IconButton(
                                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Đổi ngày giờ',
                                onPressed: () => _pickDeadlineDateTime(context),
                              ),
                              const SizedBox(width: 6),
                              // Clear deadline
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Xóa hạn chót',
                                onPressed: () => setState(() => _reminderDateTime = null),
                              ),
                            ],
                          ),
                        ),

                      // Title input
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tiêu đề ghi chú...',
                          hintStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),

                      // Markdown Formatting Toolbar
                      _MarkdownToolbar(
                        onInsert: _insertMarkdown,
                        textColor: textColor,
                        showPreview: _showPreview,
                        onTogglePreview: () => setState(() => _showPreview = !_showPreview),
                      ),

                      const SizedBox(height: 8),

                      // Editor & Checklist Body
                      Expanded(
                        child: isWideScreen && _showPreview
                            // Desktop Split View
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildEditorAndChecklist(textColor, cardBorder)),
                                  VerticalDivider(color: cardBorder, width: 24),
                                  Expanded(child: _buildMarkdownPreview(textColor)),
                                ],
                              )
                            // Mobile / Single Tab View
                            : _showPreview
                                ? _buildMarkdownPreview(textColor)
                                : _buildEditorAndChecklist(textColor, cardBorder),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorAndChecklist(Color textColor, Color cardBorder) {
    return ListView(
      children: [
        // Interactive Checklist Section
        if (_checklist.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'VIỆC CẦN LÀM (CHECKLIST):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.6),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          ..._checklist.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isDone,
                    activeColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => item.isDone = val ?? false),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.text,
                      onChanged: (val) => item.text = val,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.isDone ? textColor.withOpacity(0.5) : textColor,
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () => setState(() => _checklist.removeAt(idx)),
                  ),
                ],
              ),
            );
          }),
        ],

        // Add Checklist Item Input Bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(Icons.add_task, size: 18, color: textColor.withOpacity(0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _checklistInputController,
                  onSubmitted: (_) => _addChecklistItem(),
                  style: TextStyle(fontSize: 13.5, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Thêm mục cần làm (Enter để thêm)...',
                    hintStyle: TextStyle(fontSize: 13.5, color: textColor.withOpacity(0.5)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              if (_checklistInputController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.indigo),
                  onPressed: _addChecklistItem,
                ),
            ],
          ),
        ),

        const Divider(height: 16),

        // Main Markdown Text Content Editor
        TextField(
          controller: _contentController,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            height: 1.6,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập nội dung ghi chú (Hỗ trợ định dạng Markdown đầy đủ: # Tiêu đề, **in đậm**, *nghiêng*, - danh sách, > trích dẫn, ```code...)...',
            hintStyle: TextStyle(
              fontSize: 15,
              color: textColor.withOpacity(0.4),
              height: 1.6,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownPreview(Color textColor) {
    final text = _contentController.text.trim();
    if (text.isEmpty && _checklist.isEmpty) {
      return Center(
        child: Text(
          'Chưa có nội dung để xem trước',
          style: TextStyle(color: textColor.withOpacity(0.5)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Markdown(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: TextStyle(fontSize: 15, color: textColor, height: 1.6),
          h1: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          h3: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          code: TextStyle(
            backgroundColor: Colors.black.withOpacity(0.08),
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _MarkdownToolbar extends StatelessWidget {
  final Function(String prefix, [String suffix]) onInsert;
  final Color textColor;
  final bool showPreview;
  final VoidCallback onTogglePreview;

  const _MarkdownToolbar({
    required this.onInsert,
    required this.textColor,
    required this.showPreview,
    required this.onTogglePreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolBtn(icon: Icons.title, tooltip: 'Tiêu đề H1', onTap: () => onInsert('# ')),
            _ToolBtn(icon: Icons.format_size, tooltip: 'Tiêu đề H2', onTap: () => onInsert('## ')),
            _ToolBtn(icon: Icons.format_bold, tooltip: 'In đậm (**text**)', onTap: () => onInsert('**', '**')),
            _ToolBtn(icon: Icons.format_italic, tooltip: 'In nghiêng (*text*)', onTap: () => onInsert('*', '*')),
            _ToolBtn(icon: Icons.format_strikethrough, tooltip: 'Gạch ngang (~~text~~)', onTap: () => onInsert('~~', '~~')),
            _ToolBtn(icon: Icons.format_list_bulleted, tooltip: 'Danh sách (- mục)', onTap: () => onInsert('- ')),
            _ToolBtn(icon: Icons.format_list_numbered, tooltip: 'Danh sách số (1. mục)', onTap: () => onInsert('1. ')),
            _ToolBtn(icon: Icons.format_quote, tooltip: 'Trích dẫn (> quote)', onTap: () => onInsert('> ')),
            _ToolBtn(icon: Icons.code, tooltip: 'Khối mã (```code```)', onTap: () => onInsert('```\n', '\n```')),
            _ToolBtn(icon: Icons.horizontal_rule, tooltip: 'Đường kẻ ngang (---)', onTap: () => onInsert('\n---\n')),
            _ToolBtn(icon: Icons.link, tooltip: 'Chèn liên kết [link](url)', onTap: () => onInsert('[Tên liên kết](', ')')),
            const VerticalDivider(width: 16),
            InkWell(
              onTap: onTogglePreview,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: showPreview ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      showPreview ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: showPreview ? Colors.white : textColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      showPreview ? 'Đóng xem trước' : 'Xem trước Markdown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: showPreview ? Colors.white : textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
