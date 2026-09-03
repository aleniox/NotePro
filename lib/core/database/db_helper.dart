import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../models/checklist_item.dart';
import '../../models/folder_model.dart';
import '../../models/note_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notepro_v1.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Check if running on desktop (Windows / Linux / macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _getDatabaseDirectory();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN isCompleted INTEGER DEFAULT 0');
      } catch (_) {}
    }
  }

  Future<String> _getDatabaseDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final appDocDir = await getApplicationSupportDirectory();
      final dir = Directory(p.join(appDocDir.path, 'NoteProData'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } else {
      return await getDatabasesPath();
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        iconName TEXT NOT NULL
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        colorIndex INTEGER DEFAULT 0,
        isPinned INTEGER DEFAULT 0,
        isArchived INTEGER DEFAULT 0,
        isTrash INTEGER DEFAULT 0,
        isLocked INTEGER DEFAULT 0,
        pinCode TEXT,
        folderId TEXT,
        folderName TEXT,
        tags TEXT,
        checklist TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        reminderDateTime TEXT,
        isCompleted INTEGER DEFAULT 0
      )
    ''');

    // Insert default folders
    final defaultFolders = [
      NoteFolder(id: 'work', name: 'Công việc', colorValue: 0xFF3B82F6, iconName: 'work'),
      NoteFolder(id: 'personal', name: 'Cá nhân', colorValue: 0xFF10B981, iconName: 'person'),
      NoteFolder(id: 'ideas', name: 'Ý tưởng', colorValue: 0xFFF59E0B, iconName: 'lightbulb'),
      NoteFolder(id: 'study', name: 'Học tập', colorValue: 0xFF8B5CF6, iconName: 'school'),
    ];

    for (final folder in defaultFolders) {
      await db.insert('folders', folder.toMap());
    }

    // Insert welcome sample notes
    final welcomeNote1 = NoteModel(
      id: const Uuid().v4(),
      title: '👋 Chào mừng bạn đến với NoteCards Pro!',
      content: '''# Ứng dụng Ghi chú Thẻ Chuyên Nghiệp

NoteCards Pro được thiết kế tối ưu cho cả **Windows** và **Android** theo phong cách thẻ note trực quan, sinh động.

### ✨ Các tính năng nổi bật:
- 📌 **Ghim thẻ quan trọng** lên đầu bảng
- 🎨 **Đổi màu sắc thẻ** linh hoạt theo chủ đề
- 🏷️ **Gắn thẻ tag (#tag)** và phân loại theo thư mục
- 📋 **Checklist công việc** tích chọn trực tiếp trên thẻ
- 🔒 **Khóa bảo mật** bằng mã PIN
- ⌨️ **Hỗ trợ phím tắt Windows** (Ctrl+N, Ctrl+F, Ctrl+S)
- 💾 **Sao lưu & Phục hồi JSON**, xuất file Markdown (.md)
''',
      colorIndex: 5, // Sky Blue
      isPinned: true,
      folderId: 'ideas',
      folderName: 'Ý tưởng',
      tags: ['HuongDan', 'NotePro', 'MeoHay'],
      checklist: [
        ChecklistItem(id: '1', text: 'Tạo thẻ ghi chú mới đầu tiên', isDone: true),
        ChecklistItem(id: '2', text: 'Thử đổi màu sắc thẻ yêu thích', isDone: false),
        ChecklistItem(id: '3', text: 'Thử nghiệm tìm kiếm và gắn thẻ #tag', isDone: false),
      ],
    );

    final welcomeNote2 = NoteModel(
      id: const Uuid().v4(),
      title: '🎯 Kế hoạch & Checklist công việc hôm nay',
      content: 'Theo dõi tiến độ các đầu việc quan trọng trong tuần.',
      colorIndex: 2, // Mint Teal
      isPinned: true,
      folderId: 'work',
      folderName: 'Công việc',
      tags: ['CongViec', 'KeHoach'],
      checklist: [
        ChecklistItem(id: 'c1', text: 'Xem lại các mục tiêu quý này', isDone: true),
        ChecklistItem(id: 'c2', text: 'Gặp gỡ khách hàng lúc 10h sáng', isDone: true),
        ChecklistItem(id: 'c3', text: 'Hoàn thiện tài liệu dự án', isDone: false),
        ChecklistItem(id: 'c4', text: 'Kiểm tra hòm thư điện tử', isDone: false),
      ],
    );

    await db.insert('notes', welcomeNote1.toMap());
    await db.insert('notes', welcomeNote2.toMap());
  }

  // --- CRUD Note operations ---
  Future<List<NoteModel>> getAllNotes({bool includeTrash = false, bool includeArchived = false}) async {
    final db = await instance.database;
    String whereClause = 'isTrash = 0 AND isArchived = 0';
    if (includeTrash) {
      whereClause = 'isTrash = 1';
    } else if (includeArchived) {
      whereClause = 'isArchived = 1 AND isTrash = 0';
    }

    final maps = await db.query(
      'notes',
      where: whereClause,
      orderBy: 'isPinned DESC, updatedAt DESC',
    );

    return maps.map((map) => NoteModel.fromMap(map)).toList();
  }

  Future<int> insertNote(NoteModel note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateNote(NoteModel note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNoteToTrash(String id) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'isTrash': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreNoteFromTrash(String id) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'isTrash': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotePermanently(String id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> emptyTrash() async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'isTrash = 1',
    );
  }

  // --- CRUD Folders ---
  Future<List<NoteFolder>> getFolders() async {
    final db = await instance.database;
    final maps = await db.query('folders', orderBy: 'name ASC');
    return maps.map((m) => NoteFolder.fromMap(m)).toList();
  }

  Future<int> insertFolder(NoteFolder folder) async {
    final db = await instance.database;
    return await db.insert('folders', folder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateFolder(NoteFolder folder) async {
    final db = await instance.database;
    await db.update(
      'notes',
      {'folderName': folder.name},
      where: 'folderId = ?',
      whereArgs: [folder.id],
    );
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(String id) async {
    final db = await instance.database;
    // Reset folderId in notes
    await db.update(
      'notes',
      {'folderId': null, 'folderName': null},
      where: 'folderId = ?',
      whereArgs: [id],
    );
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  // Raw notes for backup
  Future<List<NoteModel>> getAllRawNotes() async {
    final db = await instance.database;
    final maps = await db.query('notes');
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  Future<void> restoreBackup(List<NoteModel> notes, List<NoteFolder> folders) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('notes');
      for (final note in notes) {
        await txn.insert('notes', note.toMap());
      }
      if (folders.isNotEmpty) {
        await txn.delete('folders');
        for (final folder in folders) {
          await txn.insert('folders', folder.toMap());
        }
      }
    });
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('notes');
      await txn.delete('folders');
    });
  }
}
