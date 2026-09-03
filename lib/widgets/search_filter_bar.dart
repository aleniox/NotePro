import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/card_colors.dart';
import '../providers/notes_provider.dart';
import '../screens/note_editor_screen.dart';

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
      child: Column(
        children: [
          Row(
            children: [
              // Left: Section Title & Filter Indicator
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      currentIcon,
                      size: 20,
                      color: iconColor ?? (isDark ? Colors.grey.shade300 : const Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentTitle,
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
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          _controller.clear();
                          notesProvider.resetFilters();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 12, color: Colors.redAccent),
                              SizedBox(width: 4),
                              Text(
                                'Bỏ lọc',
                                style: TextStyle(
                                  fontSize: 11,
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
              ),

              // Right: Compact Search Box
              Container(
                width: isDesktop ? 260 : 180,
                height: 36,
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
              ),

              const SizedBox(width: 10),

              // View Mode Switcher (Grid / List / Kanban)
              Container(
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
                  ],
                ),
              ),

              // Desktop Quick "+ Ghi chú mới" Button
              if (isDesktop) ...[
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
        ],
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
