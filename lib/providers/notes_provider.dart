import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/database/db_helper.dart';
import '../core/utils/desktop_pet_service.dart';
import '../models/checklist_item.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';

enum NoteViewMode {
  masonry,
  list,
  kanban,
  calendar,
}

enum NoteSortOption {
  smartTask, // Hợp lý theo công việc: Ghim -> Việc gấp & Deadline -> Chưa xong -> Đã xong
  deadlineAsc, // Hạn chót gần nhất
  completedLast, // Chưa hoàn thành lên trước
  updatedDesc, // Mới cập nhật gần đây
  createdDesc, // Mới tạo gần nhất
  titleAsc, // Tên A -> Z
}

class NotesProvider extends ChangeNotifier {
  List<NoteModel> _notes = [];
  List<NoteModel> _archivedNotes = [];
  List<NoteModel> _trashNotes = [];
  List<NoteFolder> _folders = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedFolderId;
  String? _selectedTag;
  int? _selectedColorIndex;
  NoteViewMode _viewMode = NoteViewMode.masonry;
  NoteSortOption _sortOption = NoteSortOption.smartTask;
  bool _isPetEnabled = true;
  bool _isSidebarVisible = true;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedFolderId => _selectedFolderId;
  String? get selectedTag => _selectedTag;
  int? get selectedColorIndex => _selectedColorIndex;
  NoteViewMode get viewMode => _viewMode;
  NoteSortOption get sortOption => _sortOption;
  bool get isPetEnabled => _isPetEnabled;
  bool get isSidebarVisible => _isSidebarVisible;
  String get petType => DesktopPetService.instance.petType;

  List<NoteFolder> get folders => _folders;
  List<NoteModel> get archivedNotes => _archivedNotes;
  List<NoteModel> get trashNotes => _trashNotes;

  void toggleSidebar([bool? val]) {
    _isSidebarVisible = val ?? !_isSidebarVisible;
    notifyListeners();
    _saveSidebarPreference();
  }

  Future<void> _loadSidebarPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSidebarVisible = prefs.getBool('is_sidebar_visible') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveSidebarPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_sidebar_visible', _isSidebarVisible);
    } catch (_) {}
  }


  void togglePetEnabled(bool val) {
    _isPetEnabled = val;
    notifyListeners();
    _syncWithDesktopPet();
  }

  Future<void> setPetType(String type) async {
    await DesktopPetService.instance.setPetType(type);
    notifyListeners();
    _syncWithDesktopPet();
  }

  void _syncWithDesktopPet() {
    DesktopPetService.instance.syncDeadlines(
      pendingDeadlines: pendingDeadlines,
      isPetEnabled: _isPetEnabled,
    );
  }

  // Get active pending deadlines (notes with reminder/deadline that are not in trash/archive and not completed)
  List<NoteModel> get pendingDeadlines {
    return _notes.where((note) {
      if (note.isTrash || note.isArchived) return false;
      if (note.isCompleted) return false;
      if (note.reminderDateTime == null) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.reminderDateTime!.compareTo(b.reminderDateTime!));
  }

  // Urgent deadlines: due today or overdue
  List<NoteModel> get urgentDeadlines {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return pendingDeadlines.where((note) {
      return note.reminderDateTime!.isBefore(endOfToday);
    }).toList();
  }

  List<NoteModel> get filteredNotes {
    final list = _notes.where((note) {
      if (_searchQuery.isNotEmpty && !note.matchesSearch(_searchQuery)) {
        return false;
      }
      if (_selectedFolderId != null && note.folderId != _selectedFolderId) {
        return false;
      }
      if (_selectedTag != null && !note.tags.contains(_selectedTag)) {
        return false;
      }
      if (_selectedColorIndex != null && note.colorIndex != _selectedColorIndex) {
        return false;
      }
      return true;
    }).toList();

    _applySorting(list);
    return list;
  }

  void _applySorting(List<NoteModel> list) {
    list.sort((a, b) {
      switch (_sortOption) {
        case NoteSortOption.smartTask:
          // 1. Pinned first
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          // 2. Uncompleted before completed
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          // 3. For uncompleted notes: notes with deadline first, sorted chronologically
          if (!a.isCompleted) {
            if (a.reminderDateTime != null && b.reminderDateTime != null) {
              return a.reminderDateTime!.compareTo(b.reminderDateTime!);
            }
            if (a.reminderDateTime != null && b.reminderDateTime == null) {
              return -1;
            }
            if (a.reminderDateTime == null && b.reminderDateTime != null) {
              return 1;
            }
          }
          // 4. Default to most recently updated
          return b.updatedAt.compareTo(a.updatedAt);

        case NoteSortOption.deadlineAsc:
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          if (a.reminderDateTime != null && b.reminderDateTime != null) {
            return a.reminderDateTime!.compareTo(b.reminderDateTime!);
          }
          if (a.reminderDateTime != null) return -1;
          if (b.reminderDateTime != null) return 1;
          return b.updatedAt.compareTo(a.updatedAt);

        case NoteSortOption.completedLast:
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return b.updatedAt.compareTo(a.updatedAt);

        case NoteSortOption.updatedDesc:
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          return b.updatedAt.compareTo(a.updatedAt);

        case NoteSortOption.createdDesc:
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          return b.createdAt.compareTo(a.createdAt);

        case NoteSortOption.titleAsc:
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });
  }

  List<NoteModel> get pinnedNotes => filteredNotes.where((n) => n.isPinned).toList();
  List<NoteModel> get otherNotes => filteredNotes.where((n) => !n.isPinned).toList();

  List<String> get allTags {
    final Set<String> tagsSet = {};
    for (final note in _notes) {
      tagsSet.addAll(note.tags);
    }
    return tagsSet.toList()..sort();
  }

  NotesProvider() {
    DesktopPetService.instance.init((completedNoteId) {
      final note = _notes.firstWhere(
        (n) => n.id == completedNoteId,
        orElse: () => NoteModel(id: ''),
      );
      if (note.id.isNotEmpty && !note.isCompleted) {
        toggleDeadlineCompleted(note);
      }
    });
    DesktopPetService.instance.onPetTypeChanged = (type) {
      notifyListeners();
    };
    _loadSidebarPreference();
    _loadSortPreference();
    loadAllData();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await DatabaseHelper.instance.getAllNotes();
      _archivedNotes = await DatabaseHelper.instance.getAllNotes(includeArchived: true);
      _trashNotes = await DatabaseHelper.instance.getAllNotes(includeTrash: true);
      _folders = await DatabaseHelper.instance.getFolders();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      _syncWithDesktopPet();
    }
  }

  void setViewMode(NoteViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  Future<void> _loadSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt('note_sort_option');
      if (index != null && index >= 0 && index < NoteSortOption.values.length) {
        _sortOption = NoteSortOption.values[index];
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setSortOption(NoteSortOption option) async {
    _sortOption = option;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('note_sort_option', option.index);
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setSelectedFolder(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void setSelectedColor(int? colorIndex) {
    _selectedColorIndex = colorIndex;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedFolderId = null;
    _selectedTag = null;
    _selectedColorIndex = null;
    notifyListeners();
  }

  Future<void> addNote(NoteModel note) async {
    await DatabaseHelper.instance.insertNote(note);
    await loadAllData();
  }

  Future<void> updateNote(NoteModel note) async {
    note.updatedAt = DateTime.now();
    await DatabaseHelper.instance.updateNote(note);
    await loadAllData();
  }

  Future<void> togglePin(NoteModel note) async {
    final updated = note.copyWith(isPinned: !note.isPinned, updatedAt: DateTime.now());
    await DatabaseHelper.instance.updateNote(updated);
    await loadAllData();
  }

  Future<void> toggleArchive(NoteModel note) async {
    final updated = note.copyWith(
      isArchived: !note.isArchived,
      isPinned: false, // Unpin when archiving
      updatedAt: DateTime.now(),
    );
    await DatabaseHelper.instance.updateNote(updated);
    await loadAllData();
  }

  Future<void> moveToTrash(NoteModel note) async {
    await DatabaseHelper.instance.deleteNoteToTrash(note.id);
    await loadAllData();
  }

  Future<void> restoreFromTrash(NoteModel note) async {
    await DatabaseHelper.instance.restoreNoteFromTrash(note.id);
    await loadAllData();
  }

  Future<void> deletePermanently(String noteId) async {
    await DatabaseHelper.instance.deleteNotePermanently(noteId);
    await loadAllData();
  }

  Future<void> emptyTrash() async {
    await DatabaseHelper.instance.emptyTrash();
    await loadAllData();
  }

  Future<void> changeNoteColor(NoteModel note, int colorIndex) async {
    final updated = note.copyWith(colorIndex: colorIndex, updatedAt: DateTime.now());
    await DatabaseHelper.instance.updateNote(updated);
    await loadAllData();
  }

  Future<void> toggleDeadlineCompleted(NoteModel note) async {
    final updated = note.copyWith(
      isCompleted: !note.isCompleted,
      updatedAt: DateTime.now(),
    );
    await DatabaseHelper.instance.updateNote(updated);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      notifyListeners();
    } else {
      await loadAllData();
    }
  }

  Future<void> toggleChecklistItem(NoteModel note, String itemId) async {
    final updatedChecklist = note.checklist.map((item) {
      if (item.id == itemId) {
        return ChecklistItem(id: item.id, text: item.text, isDone: !item.isDone);
      }
      return item;
    }).toList();

    // Auto-complete note when all checklist items are done!
    final bool allDone = updatedChecklist.isNotEmpty && updatedChecklist.every((i) => i.isDone);
    final bool isCompleted = allDone ? true : (note.isCompleted && !allDone ? false : note.isCompleted);

    final updated = note.copyWith(
      checklist: updatedChecklist,
      isCompleted: isCompleted,
      updatedAt: DateTime.now(),
    );
    await DatabaseHelper.instance.updateNote(updated);
    // Instant update in-memory list for snappy UI
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      notifyListeners();
    }
  }

  Future<void> duplicateNote(NoteModel note) async {
    final newNote = note.copyWith(
      id: const Uuid().v4(),
      title: '${note.title} (Bản sao)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertNote(newNote);
    await loadAllData();
  }

  // Folder management
  Future<void> addFolder(String name, int colorValue, String iconName) async {
    final folder = NoteFolder(
      id: const Uuid().v4(),
      name: name,
      colorValue: colorValue,
      iconName: iconName,
    );
    await DatabaseHelper.instance.insertFolder(folder);
    await loadAllData();
  }

  Future<void> updateFolder(NoteFolder folder) async {
    await DatabaseHelper.instance.updateFolder(folder);
    await loadAllData();
  }

  Future<void> deleteFolder(String folderId) async {
    await DatabaseHelper.instance.deleteFolder(folderId);
    if (_selectedFolderId == folderId) {
      _selectedFolderId = null;
    }
    await loadAllData();
  }

  Future<void> clearAllData() async {
    await DatabaseHelper.instance.clearAllData();
    _selectedFolderId = null;
    _selectedTag = null;
    _selectedColorIndex = null;
    _searchQuery = '';
    await loadAllData();
  }
}
