import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/card_colors.dart';
import '../models/folder_model.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/archive_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/trash_screen.dart';

class AdaptiveSidebar extends StatelessWidget {
  final bool isDrawer;

  const AdaptiveSidebar({super.key, this.isDrawer = false});

  void _showAddFolderDialog(BuildContext context) {
    final textController = TextEditingController();
    int selectedColor = 0xFF3B82F6;

    final folderColors = [
      0xFF3B82F6, // Blue
      0xFF10B981, // Green
      0xFFF59E0B, // Amber
      0xFFEF4444, // Red
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm danh mục mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục',
                  hintText: 'Ví dụ: Dự án A, Nhật ký...',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Chọn màu đại diện:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: folderColors.map((c) {
                  final isSelected = selectedColor == c;
                  return InkWell(
                    onTap: () => setState(() => selectedColor = c),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black87 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
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
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  Provider.of<NotesProvider>(context, listen: false).addFolder(name, selectedColor, 'folder');
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Tạo mới'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFolderDialog(BuildContext context, NoteFolder folder) {
    final textController = TextEditingController(text: folder.name);
    int selectedColor = folder.colorValue;

    final folderColors = [
      0xFF3B82F6, // Blue
      0xFF10B981, // Green
      0xFFF59E0B, // Amber
      0xFFEF4444, // Red
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa danh mục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Chọn màu đại diện:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: folderColors.map((c) {
                  final isSelected = selectedColor == c;
                  return InkWell(
                    onTap: () => setState(() => selectedColor = c),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black87 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
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
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  final updated = NoteFolder(
                    id: folder.id,
                    name: name,
                    colorValue: selectedColor,
                    iconName: folder.iconName,
                  );
                  Provider.of<NotesProvider>(context, listen: false).updateFolder(updated);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật danh mục "$name"')),
                  );
                }
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, NoteFolder folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Xóa danh mục "${folder.name}"?'),
          ],
        ),
        content: const Text(
          'Danh mục này sẽ bị xóa. Các ghi chú thuộc danh mục sẽ được chuyển về mục "Chung" và không bị mất dữ liệu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Provider.of<NotesProvider>(context, listen: false).deleteFolder(folder.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa danh mục "${folder.name}"')),
              );
            },
            child: const Text('Xóa danh mục'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final content = Column(
      children: [
        // App Header
        Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/app_logo.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NoteCards Pro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Ghi chú chuyên nghiệp',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),

        Divider(
          height: 1,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),

        // Navigation Items Scrollable List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            children: [
              // All Notes
              _SidebarItem(
                icon: Icons.grid_view_rounded,
                title: 'Tất cả ghi chú',
                count: notesProvider.filteredNotes.length,
                isSelected: notesProvider.viewMode != NoteViewMode.calendar &&
                    notesProvider.selectedFolderId == null &&
                    notesProvider.selectedTag == null &&
                    notesProvider.selectedColorIndex == null,
                onTap: () {
                  notesProvider.resetFilters();
                  if (notesProvider.viewMode == NoteViewMode.calendar) {
                    notesProvider.setViewMode(NoteViewMode.masonry);
                  }
                  if (isDrawer) Navigator.pop(context);
                },
              ),

              // Calendar & Deadlines
              _SidebarItem(
                icon: Icons.calendar_month_rounded,
                title: 'Lịch & Hạn chót',
                count: notesProvider.pendingDeadlines.length,
                isSelected: notesProvider.viewMode == NoteViewMode.calendar,
                onTap: () {
                  notesProvider.resetFilters();
                  notesProvider.setViewMode(NoteViewMode.calendar);
                  if (isDrawer) Navigator.pop(context);
                },
              ),

              // Archive
              _SidebarItem(
                icon: Icons.archive_outlined,
                title: 'Lưu trữ',
                count: notesProvider.archivedNotes.length,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ArchiveScreen()),
                  );
                },
              ),

              // Trash
              _SidebarItem(
                icon: Icons.delete_outline_rounded,
                title: 'Thùng rác',
                count: notesProvider.trashNotes.length,
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TrashScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Folders Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chủ đề',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showAddFolderDialog(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              ...notesProvider.folders.map((folder) {
                final isSelected = notesProvider.selectedFolderId == folder.id;
                return _FolderSidebarItem(
                  folder: folder,
                  isSelected: isSelected,
                  onTap: () {
                    if (isSelected) {
                      notesProvider.setSelectedFolder(null);
                    } else {
                      notesProvider.setSelectedFolder(folder.id);
                    }
                    if (isDrawer) Navigator.pop(context);
                  },
                  onEdit: () => _showEditFolderDialog(context, folder),
                  onDelete: () => _confirmDeleteFolder(context, folder),
                );
              }),

              const SizedBox(height: 16),

              // Tags Section
              if (notesProvider.allTags.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Thẻ (#)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: notesProvider.allTags.map((tag) {
                      final isSelected = notesProvider.selectedTag == tag;
                      return InkWell(
                        onTap: () {
                          notesProvider.setSelectedTag(isSelected ? null : tag);
                          if (isDrawer) Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Color filter dots
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Màu sắc',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(CardPalette.colors.length, (index) {
                    final isSelected = notesProvider.selectedColorIndex == index;
                    final palette = CardPalette.getColor(index);
                    return InkWell(
                      onTap: () {
                        if (isSelected) {
                          notesProvider.setSelectedColor(null);
                        } else {
                          notesProvider.setSelectedColor(index);
                        }
                        if (isDrawer) Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: palette.previewColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? primaryColor : (isDark ? Colors.white24 : Colors.black12),
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Modern Clean Bottom Bar
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Theme Mode Toggle Bar
              Container(
                height: 36,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !themeProvider.isDarkMode ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.light_mode_rounded,
                                size: 14,
                                color: !themeProvider.isDarkMode ? Colors.white : Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Sáng',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: !themeProvider.isDarkMode ? Colors.white : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dark_mode_rounded,
                                size: 14,
                                color: themeProvider.isDarkMode ? Colors.white : Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Tối',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Settings & Backup Button
              InkWell(
                onTap: () {
                  if (isDrawer) Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.settings_outlined, size: 16, color: primaryColor),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cài đặt & Sao lưu',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Đồng bộ, phím tắt',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isDrawer) {
      return Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: SafeArea(child: content),
      );
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(child: content),
    );
  }
}

class _FolderSidebarItem extends StatefulWidget {
  final NoteFolder folder;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FolderSidebarItem({
    required this.folder,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_FolderSidebarItem> createState() => _FolderSidebarItemState();
}

class _FolderSidebarItemState extends State<_FolderSidebarItem> {
  bool _isHovered = false;

  void _showMenuOptions(BuildContext context, Offset globalPos) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        globalPos.dx + 1,
        globalPos.dy + 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      items: [
        const PopupMenuItem(
          value: 'edit',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 16),
              SizedBox(width: 8),
              Text('Đổi tên & Màu', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
              SizedBox(width: 8),
              Text('Xóa danh mục', style: TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );

    if (selected == 'edit') {
      widget.onEdit();
    } else if (selected == 'delete') {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onSecondaryTapDown: (details) => _showMenuOptions(context, details.globalPosition),
        onLongPressStart: (details) => _showMenuOptions(context, details.globalPosition),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: widget.isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_rounded,
                      size: 18,
                      color: Color(widget.folder.colorValue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.folder.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: widget.isSelected ? activeColor : (isDark ? Colors.grey.shade200 : const Color(0xFF1E293B)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 3-Dots Action Button ONLY visible on Hover
                    if (_isHovered)
                      GestureDetector(
                        onTapDown: (details) => _showMenuOptions(context, details.globalPosition),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 24, height: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.count,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? activeColor : (iconColor ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeColor : (isDark ? Colors.grey.shade200 : const Color(0xFF1E293B)),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count != null && count! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
