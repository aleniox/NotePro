import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../widgets/adaptive_sidebar.dart';
import '../widgets/calendar_view.dart';
import '../widgets/kanban_view.dart';
import '../widgets/note_card_widget.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/wandering_pet_widget.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openNewNote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _openNewNote(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              Row(
                children: [
                  // Persistent Sidebar on Desktop
                  if (isDesktop) const AdaptiveSidebar(isDrawer: false),

                  // Main Area
                  Expanded(
                    child: Column(
                      children: [
                        // Top App Bar for Mobile or Search Bar for Desktop
                        if (!isDesktop)
                          AppBar(
                            title: const Row(
                              children: [
                                Icon(Icons.sticky_note_2_rounded, color: Color(0xFF6366F1), size: 22),
                                SizedBox(width: 8),
                                Text('NoteCards Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                          ),

                        // Search & View Mode Bar
                        const SearchFilterBar(),

                        // Notes Content (Masonry / List / Kanban / Calendar)
                        Expanded(
                          child: Consumer<NotesProvider>(
                            builder: (context, provider, child) {
                              if (provider.isLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final filtered = provider.filteredNotes;
                              final pinned = provider.pinnedNotes;
                              final others = provider.otherNotes;

                              // Calendar View Mode
                              if (provider.viewMode == NoteViewMode.calendar) {
                                return CalendarView(notes: filtered);
                              }

                              if (filtered.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.note_alt_outlined, size: 72, color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text(
                                        provider.searchQuery.isNotEmpty || provider.selectedFolderId != null || provider.selectedTag != null
                                            ? 'Không tìm thấy thẻ ghi chú phù hợp'
                                            : 'Chưa có thẻ ghi chú nào',
                                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        onPressed: () => _openNewNote(context),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Tạo thẻ ghi chú mới'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Kanban View Mode
                              if (provider.viewMode == NoteViewMode.kanban) {
                                return KanbanView(notes: filtered);
                              }

                              // List View Mode
                              if (provider.viewMode == NoteViewMode.list) {
                                return ListView(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  children: [
                                    if (pinned.isNotEmpty) ...[
                                      _SectionTitle(title: 'ĐÃ GHIM (${pinned.length})'),
                                      ...pinned.map((n) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: NoteCardWidget(note: n),
                                          )),
                                      const SizedBox(height: 12),
                                    ],
                                    if (others.isNotEmpty) ...[
                                      if (pinned.isNotEmpty) const _SectionTitle(title: 'KHÁC'),
                                      ...others.map((n) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: NoteCardWidget(note: n),
                                          )),
                                    ],
                                  ],
                                );
                              }

                              // Default: Masonry Grid View
                              final availableWidth = isDesktop ? screenWidth - 260 : screenWidth;
                              int columns = (availableWidth / 260).floor().clamp(1, 6);

                              return CustomScrollView(
                                slivers: [
                                  if (pinned.isNotEmpty) ...[
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                        child: _SectionTitle(title: 'ĐÃ GHIM (${pinned.length})'),
                                      ),
                                    ),
                                    SliverPadding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      sliver: SliverMasonryGrid.count(
                                        crossAxisCount: columns,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        itemBuilder: (context, index) {
                                          return NoteCardWidget(note: pinned[index]);
                                        },
                                        childCount: pinned.length,
                                      ),
                                    ),
                                  ],
                                  if (others.isNotEmpty) ...[
                                    if (pinned.isNotEmpty)
                                      const SliverToBoxAdapter(
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                                          child: _SectionTitle(title: 'KHÁC'),
                                        ),
                                      ),
                                    SliverPadding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      sliver: SliverMasonryGrid.count(
                                        crossAxisCount: columns,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        itemBuilder: (context, index) {
                                          return NoteCardWidget(note: others[index]);
                                        },
                                        childCount: others.length,
                                      ),
                                    ),
                                  ],
                                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openNewNote(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thẻ mới', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }
}
