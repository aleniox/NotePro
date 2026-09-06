import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/card_colors.dart';
import '../core/utils/app_snackbar.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../screens/note_editor_screen.dart';

class CalendarView extends StatefulWidget {
  final List<NoteModel> notes;

  const CalendarView({super.key, required this.notes});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getVietnameseWeekday(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
      default:
        return 'Chủ Nhật';
    }
  }

  List<NoteModel> _getNotesForDay(DateTime day) {
    return widget.notes.where((note) {
      if (note.reminderDateTime != null) {
        return _isSameDay(note.reminderDateTime!, day);
      }
      return _isSameDay(note.createdAt, day);
    }).toList();
  }

  Future<void> _addNewTaskForDay() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: NoteModel(
            id: '',
            title: '',
            reminderDateTime: DateTime(
              _selectedDay.year,
              _selectedDay.month,
              _selectedDay.day,
              17,
              0,
            ),
          ),
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final notesProvider = Provider.of<NotesProvider>(context);

    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7; // Sunday is 0

    final now = DateTime.now();
    final selectedDayNotes = _getNotesForDay(_selectedDay);

    final completedCount = selectedDayNotes.where((n) => n.isCompleted).length;
    final totalCount = selectedDayNotes.length;

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;
    final isCompact = screenWidth < 500;

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // ==========================================
    // 1. CALENDAR CARD (LEFT PANEL)
    // ==========================================
    final calendarCard = Container(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation header (Wrapped for narrow responsiveness)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.calendar_month_rounded, size: 18, color: primaryColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tháng ${_focusedMonth.month}, ${_focusedMonth.year}',
                      style: TextStyle(
                        fontSize: isCompact ? 15 : 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.tonal(
                      onPressed: _goToday,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Hôm nay',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      onPressed: _prevMonth,
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      tooltip: 'Tháng trước',
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: const EdgeInsets.all(4),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                      tooltip: 'Tháng sau',
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Day of week headers pill bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildWeekdayHeader('CN', isSunday: true),
                _buildWeekdayHeader('T2'),
                _buildWeekdayHeader('T3'),
                _buildWeekdayHeader('T4'),
                _buildWeekdayHeader('T5'),
                _buildWeekdayHeader('T6'),
                _buildWeekdayHeader('T7', isSaturday: true),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: firstDayOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink();
              }

              final dayNum = index - firstDayOffset + 1;
              final currentDay = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
              final isToday = _isSameDay(currentDay, now);
              final isSelected = _isSameDay(currentDay, _selectedDay);
              final isSunday = currentDay.weekday == DateTime.sunday;
              final dayNotes = _getNotesForDay(currentDay);
              final hasPendingDeadline = dayNotes.any((n) => n.reminderDateTime != null && !n.isCompleted);
              final hasCompletedDeadline = dayNotes.any((n) => n.reminderDateTime != null && n.isCompleted);

              return InkWell(
                onTap: () => setState(() => _selectedDay = currentDay),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isToday
                            ? (isDark ? const Color(0xFF334155) : const Color(0xFFDBEAFE))
                            : (isDark ? const Color(0xFF131D2D) : const Color(0xFFF8FAFC))),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isToday
                              ? primaryColor.withValues(alpha: 0.6)
                              : cardBorderColor.withValues(alpha: 0.5)),
                      width: isSelected || isToday ? 1.6 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Day Number
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isToday
                                        ? primaryColor
                                        : (isSunday
                                            ? const Color(0xFFEF4444)
                                            : (isDark ? Colors.white70 : const Color(0xFF334155)))),
                              ),
                            ),
                            if (isToday && !isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 3.5,
                                height: 3.5,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Task indicators at bottom
                      if (dayNotes.isNotEmpty)
                        Positioned(
                          bottom: 3,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasPendingDeadline)
                                Container(
                                  width: 4.5,
                                  height: 4.5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasCompletedDeadline)
                                Container(
                                  width: 4.5,
                                  height: 4.5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (!hasPendingDeadline && !hasCompletedDeadline)
                                Container(
                                  width: 4.5,
                                  height: 4.5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : const Color(0xFF6366F1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    // ==========================================
    // 2. DAY DETAILS & AGENDA (RIGHT PANEL)
    // ==========================================
    final dayDetails = Container(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Selected Date & Add button (Right aligned)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_getVietnameseWeekday(_selectedDay)}, ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                        style: TextStyle(
                          fontSize: isCompact ? 14.5 : 16.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (totalCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: (completedCount == totalCount ? const Color(0xFF10B981) : primaryColor)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          completedCount == totalCount
                              ? '✨ Đã xong $completedCount/$totalCount việc!'
                              : '📌 Có $totalCount việc ($completedCount đã xong)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: completedCount == totalCount ? const Color(0xFF10B981) : primaryColor,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Chưa có lịch trình hay ghi chú',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: FilledButton.icon(
                  onPressed: _addNewTaskForDay,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Thêm việc',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Content List
          if (selectedDayNotes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      size: 38,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ngày này chưa có công việc nào',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Lên lịch hoặc ghi chú ngay để không bỏ lỡ hạn chót.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: FilledButton.tonalIcon(
                      onPressed: _addNewTaskForDay,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text(
                        'Tạo công việc cho ngày này',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedDayNotes.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final note = selectedDayNotes[idx];
                final palette = CardPalette.getColor(note.colorIndex);
                final hasDeadline = note.reminderDateTime != null;
                final isDone = note.isCompleted;

                return InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteEditorScreen(note: note),
                      ),
                    );
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.getBackground(isDark),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasDeadline && !isDone
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.8)
                            : palette.getBorder(isDark),
                        width: hasDeadline && !isDone ? 1.6 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Checkbox + Title + Edit/Delete Buttons
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Complete Circle Pill
                            Tooltip(
                              message: isDone ? 'Đánh dấu chưa xong' : 'Đánh dấu hoàn thành',
                              child: InkWell(
                                onTap: () => notesProvider.toggleDeadlineCompleted(note),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10, top: 2),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? const Color(0xFF10B981)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDone
                                            ? const Color(0xFF10B981)
                                            : palette.getText(isDark).withValues(alpha: 0.35),
                                        width: 1.8,
                                      ),
                                    ),
                                    child: isDone
                                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                        : null,
                                  ),
                                ),
                              ),
                            ),

                            // Note Title
                            Expanded(
                              child: Text(
                                note.title.isEmpty ? 'Ghi chú không tiêu đề' : note.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDone
                                      ? palette.getText(isDark).withValues(alpha: 0.5)
                                      : palette.getText(isDark),
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Action buttons group (Edit & Delete)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NoteEditorScreen(note: note),
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 15,
                                      color: palette.getText(isDark).withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Xóa ghi chú?'),
                                        content: Text(
                                          'Chuyển "${note.title.isEmpty ? 'Ghi chú không tiêu đề' : note.title}" vào Thùng rác?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Hủy'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                            onPressed: () {
                                              notesProvider.moveToTrash(note);
                                              Navigator.pop(ctx);
                                              if (mounted) setState(() {});
                                              AppSnackBar.showTrash(context, 'Đã chuyển ghi chú vào Thùng rác');
                                            },
                                            child: const Text('Xóa'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 15,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Row 2: Badges (Time, Folder, Checklist)
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (hasDeadline)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: (isDone ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: (isDone ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                          .withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 11.5,
                                        color: isDone ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${note.reminderDateTime!.hour.toString().padLeft(2, '0')}:${note.reminderDateTime!.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDone ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (note.folderName != null && note.folderName!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : Colors.black.withValues(alpha: 0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.folder_outlined,
                                        size: 11.5,
                                        color: palette.getText(isDark).withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        note.folderName!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: palette.getText(isDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (note.checklist.isNotEmpty)
                                Builder(
                                  builder: (context) {
                                    final doneCount = note.checklist.where((c) => c.isDone).length;
                                    final allDone = doneCount == note.checklist.length;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: (allDone ? const Color(0xFF10B981) : const Color(0xFF6366F1))
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: (allDone ? const Color(0xFF10B981) : const Color(0xFF6366F1))
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            allDone ? Icons.task_alt_rounded : Icons.checklist_rounded,
                                            size: 12,
                                            color: allDone ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$doneCount/${note.checklist.length}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: allDone ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 10 : 20),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: calendarCard),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: dayDetails),
              ],
            )
          : Column(
              children: [
                calendarCard,
                SizedBox(height: isCompact ? 12 : 20),
                dayDetails,
              ],
            ),
    );
  }

  Widget _buildWeekdayHeader(String name, {bool isSunday = false, bool isSaturday = false}) {
    return Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSunday
                  ? const Color(0xFFEF4444)
                  : (isSaturday ? const Color(0xFF6366F1) : const Color(0xFF94A3B8)),
            ),
          ),
        ),
      ),
    );
  }
}
