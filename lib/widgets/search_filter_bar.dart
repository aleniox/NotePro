import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/card_colors.dart';
import '../providers/notes_provider.dart';
import '../screens/note_editor_screen.dart';
import 'sidebar_toggle_button.dart';

class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({super.key});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openNewNote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // Determine current section title
    String currentTitle = 'Tất cả thẻ ghi chú';
    IconData currentIcon = Icons.grid_view_rounded;
    Color? iconColor;

    if (notesProvider.selectedFolderId != null) {
      final folder = notesProvider.folders.firstWhere(
        (f) => f.id == notesProvider.selectedFolderId,
        orElse: () => notesProvider.folders.first,
      );
      currentTitle = folder.name;
      currentIcon = Icons.folder_rounded;
      iconColor = Color(folder.colorValue);
    } else if (notesProvider.selectedTag != null) {
      currentTitle = '#${notesProvider.selectedTag}';
      currentIcon = Icons.tag_rounded;
      iconColor = primaryColor;
    } else if (notesProvider.selectedColorIndex != null) {
      currentTitle = CardPalette.getColor(notesProvider.selectedColorIndex!).name;
      currentIcon = Icons.palette_rounded;
      iconColor = CardPalette.getColor(notesProvider.selectedColorIndex!).previewColor;
    }

    final hasActiveFilter = notesProvider.selectedFolderId != null ||
        notesProvider.selectedTag != null ||
        notesProvider.selectedColorIndex != null ||
        notesProvider.searchQuery.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;

        Widget buildTitleSection() {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDesktop && !notesProvider.isSidebarVisible) ...[
                  SidebarToggleButton(
                    isCollapsed: true,
                    tooltip: 'Mở rộng thanh bên (Ctrl+B)',
                    onTap: () => notesProvider.toggleSidebar(true),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  currentIcon,
                  size: 20,
                  color: iconColor ?? (isDark ? Colors.grey.shade300 : const Color(0xFF1E293B)),
                ),
                const SizedBox(width: 8),
                Text(
                  currentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    notesProvider.filteredNotes.length.toString(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (hasActiveFilter && (notesProvider.selectedFolderId != null || notesProvider.selectedTag != null || notesProvider.selectedColorIndex != null)) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      _controller.clear();
                      notesProvider.resetFilters();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 12, color: Colors.redAccent),
                          SizedBox(width: 3),
                          Text(
                            'Bỏ lọc',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        Widget buildSearchBox({required bool isExpanded}) {
          final box = Container(
            height: 36,
            width: isExpanded ? null : (isDesktop ? 240 : 170),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? primaryColor
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: _isFocused ? primaryColor : Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (val) => notesProvider.setSearchQuery(val),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: isDesktop ? 'Tìm kiếm... (Ctrl+F)' : 'Tìm kiếm...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  InkWell(
                    onTap: () {
                      _controller.clear();
                      notesProvider.setSearchQuery('');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );

          return isExpanded ? Expanded(child: box) : box;
        }

        Widget buildViewModes() {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniViewModeButton(
                    icon: Icons.dashboard_rounded,
                    tooltip: 'Xem dạng thẻ lưới',
                    isSelected: notesProvider.viewMode == NoteViewMode.masonry,
                    onTap: () => notesProvider.setViewMode(NoteViewMode.masonry),
                  ),
                  _MiniViewModeButton(
                    icon: Icons.view_agenda_rounded,
                    tooltip: 'Xem dạng danh sách',
                    isSelected: notesProvider.viewMode == NoteViewMode.list,
                    onTap: () => notesProvider.setViewMode(NoteViewMode.list),
                  ),
                  _MiniViewModeButton(
                    icon: Icons.view_column_rounded,
                    tooltip: 'Xem theo nhóm danh mục',
                    isSelected: notesProvider.viewMode == NoteViewMode.kanban,
                    onTap: () => notesProvider.setViewMode(NoteViewMode.kanban),
                  ),
                  _MiniViewModeButton(
                    icon: Icons.calendar_month_rounded,
                    tooltip: 'Xem theo Lịch & Deadline',
                    isSelected: notesProvider.viewMode == NoteViewMode.calendar,
                    onTap: () => notesProvider.setViewMode(NoteViewMode.calendar),
                  ),
                ],
              ),
            ),
          );
        }

        Widget buildSortButton() {
          final sortOption = notesProvider.sortOption;

          String getSortTitle(NoteSortOption opt) {
            switch (opt) {
              case NoteSortOption.smartTask:
                return 'Hợp lý theo việc & hạn chót';
              case NoteSortOption.deadlineAsc:
                return 'Hạn chót gần nhất';
              case NoteSortOption.completedLast:
                return 'Việc chưa xong lên trước';
              case NoteSortOption.updatedDesc:
                return 'Mới cập nhật';
              case NoteSortOption.createdDesc:
                return 'Ngày tạo mới nhất';
              case NoteSortOption.titleAsc:
                return 'Tên A → Z';
            }
          }

          return PopupMenuButton<NoteSortOption>(
            tooltip: 'Sắp xếp công việc (Hiện tại: ${getSortTitle(sortOption)})',
            initialValue: sortOption,
            onSelected: (opt) => notesProvider.setSortOption(opt),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 4,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sortOption == NoteSortOption.smartTask
                      ? primaryColor.withValues(alpha: 0.5)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 16,
                    color: sortOption == NoteSortOption.smartTask
                        ? primaryColor
                        : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sortOption == NoteSortOption.smartTask ? 'Sắp xếp: Hợp lý' : 'Sắp xếp',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: sortOption == NoteSortOption.smartTask
                          ? primaryColor
                          : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: NoteSortOption.smartTask,
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF6366F1)),
                    SizedBox(width: 8),
                    Text('Hợp lý (Việc gấp & Deadline lên đầu)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: NoteSortOption.deadlineAsc,
                child: Row(
                  children: [
                    Icon(Icons.alarm_rounded, size: 16, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Text('Hạn chót gần nhất'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: NoteSortOption.completedLast,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text('Việc chưa xong lên trước'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: NoteSortOption.updatedDesc,
                child: Row(
                  children: [
                    Icon(Icons.update_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Mới cập nhật gần đây'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: NoteSortOption.createdDesc,
                child: Row(
                  children: [
                    Icon(Icons.date_range_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Mới tạo gần nhất'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: NoteSortOption.titleAsc,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Tên tiêu đề (A → Z)'),
                  ],
                ),
              ),
            ],
          );
        }

        Widget buildPetButton() {
          return IconButton(
            icon: Icon(
              notesProvider.isPetEnabled ? Icons.pets_rounded : Icons.pets_outlined,
              color: notesProvider.isPetEnabled ? const Color(0xFF6366F1) : Colors.grey,
              size: 20,
            ),
            tooltip: 'Thú cưng màn hình (Bấm để chọn Cún 🐶 / Mèo 🐱 / Anime 🌸)',
            onPressed: () => _showPetSelectionDialog(context, notesProvider),
          );
        }

        if (isCompact) {
          final isNarrow = constraints.maxWidth < 420;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNarrow) ...[
                  Row(
                    children: [
                      Expanded(child: buildTitleSection()),
                      if (isDesktop) ...[
                        const SizedBox(width: 4),
                        buildPetButton(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildViewModes(),
                        const SizedBox(width: 8),
                        buildSortButton(),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: buildTitleSection()),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildViewModes(),
                            const SizedBox(width: 8),
                            buildSortButton(),
                          ],
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 4),
                        buildPetButton(),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    buildSearchBox(isExpanded: true),
                    if (isDesktop) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _openNewNote(context),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: buildTitleSection()),
              const SizedBox(width: 12),
              buildSearchBox(isExpanded: false),
              const SizedBox(width: 10),
              buildViewModes(),
              const SizedBox(width: 8),
              buildSortButton(),
              if (isDesktop) ...[
                const SizedBox(width: 8),
                buildPetButton(),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _openNewNote(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Ghi chú mới', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showPetSelectionDialog(BuildContext context, NotesProvider notesProvider) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Text('🐾 ', style: TextStyle(fontSize: 22)),
              Text('Chọn Thú Cưng Màn Hình'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bật bé Pet trên Desktop', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Hiển thị người bạn đồng hành nhắc việc'),
                  value: notesProvider.isPetEnabled,
                  onChanged: (val) {
                    notesProvider.togglePetEnabled(val);
                    setDialogState(() {});
                  },
                ),
                const Divider(),
                const Text('Chọn nhân vật yêu thích:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Text('🐶 ', style: TextStyle(fontSize: 18)),
                      Text('Chú Cún Shiba (Puppy)', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  subtitle: const Text('Năng động, sủa gâu gâu cổ vũ'),
                  value: 'dog',
                  groupValue: notesProvider.petType,
                  onChanged: (val) {
                    notesProvider.setPetType(val!);
                    setDialogState(() {});
                  },
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Text('🐱 ', style: TextStyle(fontSize: 18)),
                      Text('Bé Mèo Kawaii (Kitten)', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  subtitle: const Text('Đáng yêu, khóe miệng :3 nũng nịu'),
                  value: 'cat',
                  groupValue: notesProvider.petType,
                  onChanged: (val) {
                    notesProvider.setPetType(val!);
                    setDialogState(() {});
                  },
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Text('🌸 ', style: TextStyle(fontSize: 18)),
                      Text('Cô Bé Anime (Waifu)', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  subtitle: const Text('Trợ lý ngọt ngào, gọi Senpai'),
                  value: 'anime',
                  groupValue: notesProvider.petType,
                  onChanged: (val) {
                    notesProvider.setPetType(val!);
                    setDialogState(() {});
                  },
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Text('💀 ', style: TextStyle(fontSize: 18)),
                      Text('Thần Chết Chibi (Grim Reaper)', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  subtitle: const Text('Áo choàng đen, vung lưỡi hái đòi deadline'),
                  value: 'reaper',
                  groupValue: notesProvider.petType,
                  onChanged: (val) {
                    notesProvider.setPetType(val!);
                    setDialogState(() {});
                  },
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Xong'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniViewModeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _MiniViewModeButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
