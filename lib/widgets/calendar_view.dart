import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/card_colors.dart';
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
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  List<NoteModel> _getNotesForDay(DateTime day) {
    return widget.notes.where((note) {
      if (note.isTrash || note.isArchived) return false;
      if (note.reminderDateTime != null) {
        return _isSameDay(note.reminderDateTime!, day);
      }
      return _isSameDay(note.createdAt, day);
    }).toList();
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

    final isWide = MediaQuery.of(context).size.width >= 900;

    final calendarCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Tháng ${_focusedMonth.month}, ${_focusedMonth.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _goToday,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text('Hôm nay', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Tháng trước',
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Tháng sau',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day of week headers
          Row(
            children: ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'].map((weekday) {
              return Expanded(
                child: Center(
                  child: Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: weekday == 'CN' ? Colors.redAccent : Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
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
              final dayNotes = _getNotesForDay(currentDay);
              final hasPendingDeadline = dayNotes.any((n) => n.reminderDateTime != null && !n.isCompleted);
              final hasCompletedDeadline = dayNotes.any((n) => n.reminderDateTime != null && n.isCompleted);

              return InkWell(
                onTap: () => setState(() => _selectedDay = currentDay),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withOpacity(0.18)
                        : (isToday ? (isDark ? Colors.white10 : Colors.blue.shade50) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isToday ? primaryColor.withOpacity(0.5) : Colors.transparent),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? primaryColor
                              : (isToday
                                  ? primaryColor
                                  : (isDark ? Colors.white : Colors.black87)),
                        ),
                      ),
                      if (dayNotes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasPendingDeadline)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (hasCompletedDeadline)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (!hasPendingDeadline && !hasCompletedDeadline)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.6),
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

    // Selected Day Tasks & Notes List
    final dayDetails = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _getVietnameseWeekday(_selectedDay),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () async {
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
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Thêm việc ngày này', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          if (selectedDayNotes.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Không có ghi chú hay deadline nào trong ngày này.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedDayNotes.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.getBackground(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasDeadline && !isDone
                            ? Colors.amber.shade700
                            : palette.getBorder(isDark),
                        width: hasDeadline && !isDone ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (hasDeadline)
                          IconButton(
                            icon: Icon(
                              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isDone ? Colors.green : Colors.amber.shade800,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => notesProvider.toggleDeadlineCompleted(note),
                          )
                        else
                          Icon(Icons.sticky_note_2_rounded, size: 18, color: palette.getText(isDark).withOpacity(0.7)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title.isEmpty ? 'Ghi chú không tiêu đề' : note.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: palette.getText(isDark),
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasDeadline) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Hạn chót: ${note.reminderDateTime!.hour}:${note.reminderDateTime!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDone ? Colors.green.shade700 : Colors.amber.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (note.folderName != null && note.folderName!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              note.folderName!,
                              style: TextStyle(fontSize: 11, color: palette.getText(isDark)),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          color: Colors.redAccent.withOpacity(0.8),
                          tooltip: 'Xóa ghi chú này',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Xóa ghi chú?'),
                                content: Text('Chuyển "${note.title.isEmpty ? 'Ghi chú không tiêu đề' : note.title}" vào Thùng rác?'),
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
      padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 20),
                dayDetails,
              ],
            ),
    );
  }
}
