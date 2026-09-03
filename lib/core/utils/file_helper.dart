import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../models/folder_model.dart';
import '../../models/note_model.dart';
import '../database/db_helper.dart';

class FileHelper {
  static Future<String?> exportBackupJson() async {
    try {
      final notes = await DatabaseHelper.instance.getAllRawNotes();
      final folders = await DatabaseHelper.instance.getFolders();

      final data = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'folders': folders.map((f) => f.toMap()).toList(),
        'notes': notes.map((n) => n.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName = 'NoteCards_Backup_$dateStr.json';

      final result = await FilePicker.saveFile(
        dialogTitle: 'Lưu tệp sao lưu ghi chú',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString, encoding: utf8);
        return result;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  static Future<int> importBackupJson() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString(encoding: utf8);
        final Map<String, dynamic> data = json.decode(content);

        final List<NoteModel> notes = [];
        if (data['notes'] != null && data['notes'] is List) {
          for (final item in data['notes']) {
            notes.add(NoteModel.fromMap(Map<String, dynamic>.from(item)));
          }
        }

        final List<NoteFolder> folders = [];
        if (data['folders'] != null && data['folders'] is List) {
          for (final item in data['folders']) {
            folders.add(NoteFolder.fromMap(Map<String, dynamic>.from(item)));
          }
        }

        if (notes.isNotEmpty || folders.isNotEmpty) {
          await DatabaseHelper.instance.restoreBackup(notes, folders);
          return notes.length;
        }
      }
      return -1;
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> exportNoteToMarkdown(NoteModel note) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('# ${note.title.isEmpty ? 'Ghi chú không tiêu đề' : note.title}');
      buffer.writeln();
      buffer.writeln('> Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt)}');
      if (note.folderName != null && note.folderName!.isNotEmpty) {
        buffer.writeln('> Danh mục: ${note.folderName}');
      }
      if (note.tags.isNotEmpty) {
        buffer.writeln('> Thẻ tags: ${note.tags.map((t) => '#$t').join(' ')}');
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();

      if (note.checklist.isNotEmpty) {
        buffer.writeln('### Danh sách việc cần làm (Checklist):');
        for (final item in note.checklist) {
          buffer.writeln('- [${item.isDone ? 'x' : ' '}] ${item.text}');
        }
        buffer.writeln();
      }

      if (note.content.isNotEmpty) {
        buffer.writeln(note.content);
      }

      final cleanTitle = note.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
      final defaultFileName = '${cleanTitle.isEmpty ? "GhiChu" : cleanTitle}.md';

      final result = await FilePicker.saveFile(
        dialogTitle: 'Xuất ghi chú ra Markdown',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['md', 'txt'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(buffer.toString(), encoding: utf8);
        return result;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
