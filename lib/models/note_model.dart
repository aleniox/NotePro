import 'dart:convert';
import 'checklist_item.dart';

class NoteModel {
  final String id;
  String title;
  String content;
  int colorIndex; // Index in CardPalette
  bool isPinned;
  bool isArchived;
  bool isTrash;
  bool isLocked;
  String? pinCode;
  String? folderId;
  String? folderName;
  List<String> tags;
  List<ChecklistItem> checklist;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? reminderDateTime;

  NoteModel({
    required this.id,
    this.title = '',
    this.content = '',
    this.colorIndex = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.isTrash = false,
    this.isLocked = false,
    this.pinCode,
    this.folderId,
    this.folderName,
    List<String>? tags,
    List<ChecklistItem>? checklist,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.reminderDateTime,
  })  : tags = tags ?? [],
        checklist = checklist ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    int? colorIndex,
    bool? isPinned,
    bool? isArchived,
    bool? isTrash,
    bool? isLocked,
    String? pinCode,
    String? folderId,
    String? folderName,
    List<String>? tags,
    List<ChecklistItem>? checklist,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reminderDateTime,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorIndex: colorIndex ?? this.colorIndex,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isTrash: isTrash ?? this.isTrash,
      isLocked: isLocked ?? this.isLocked,
      pinCode: pinCode ?? this.pinCode,
      folderId: folderId ?? this.folderId,
      folderName: folderName ?? this.folderName,
      tags: tags ?? List.from(this.tags),
      checklist: checklist ?? this.checklist.map((e) => ChecklistItem(id: e.id, text: e.text, isDone: e.isDone)).toList(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'colorIndex': colorIndex,
      'isPinned': isPinned ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'isTrash': isTrash ? 1 : 0,
      'isLocked': isLocked ? 1 : 0,
      'pinCode': pinCode,
      'folderId': folderId,
      'folderName': folderName,
      'tags': json.encode(tags),
      'checklist': json.encode(checklist.map((item) => item.toMap()).toList()),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reminderDateTime': reminderDateTime?.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null && map['tags'] is String && (map['tags'] as String).isNotEmpty) {
      try {
        final decoded = json.decode(map['tags'] as String);
        if (decoded is List) {
          parsedTags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    List<ChecklistItem> parsedChecklist = [];
    if (map['checklist'] != null && map['checklist'] is String && (map['checklist'] as String).isNotEmpty) {
      try {
        final decoded = json.decode(map['checklist'] as String);
        if (decoded is List) {
          parsedChecklist = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => ChecklistItem.fromMap(e))
              .toList();
        }
      } catch (_) {}
    }

    return NoteModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      colorIndex: map['colorIndex'] is int ? map['colorIndex'] : 0,
      isPinned: map['isPinned'] == 1 || map['isPinned'] == true,
      isArchived: map['isArchived'] == 1 || map['isArchived'] == true,
      isTrash: map['isTrash'] == 1 || map['isTrash'] == true,
      isLocked: map['isLocked'] == 1 || map['isLocked'] == true,
      pinCode: map['pinCode']?.toString(),
      folderId: map['folderId']?.toString(),
      folderName: map['folderName']?.toString(),
      tags: parsedTags,
      checklist: parsedChecklist,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
      reminderDateTime: map['reminderDateTime'] != null ? DateTime.tryParse(map['reminderDateTime'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel.fromMap(json);

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (title.toLowerCase().contains(q)) return true;
    if (content.toLowerCase().contains(q)) return true;
    if (tags.any((t) => t.toLowerCase().contains(q))) return true;
    if (folderName != null && folderName!.toLowerCase().contains(q)) return true;
    if (checklist.any((item) => item.text.toLowerCase().contains(q))) return true;
    return false;
  }
}
