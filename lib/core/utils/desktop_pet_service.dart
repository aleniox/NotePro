import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/note_model.dart';

class DesktopPetService {
  static final DesktopPetService instance = DesktopPetService._();
  DesktopPetService._();

  Timer? _actionWatchTimer;
  Process? _petProcess;
  Function(String noteId)? _onCompleteCallback;
  Function(String petType)? onPetTypeChanged;

  String _petType = 'dog';
  String get petType => _petType;

  Future<void> init(Function(String noteId) onComplete) async {
    _onCompleteCallback = onComplete;
    await _loadSavedPetType();
    if (Platform.isWindows) {
      _startWatchingActions();
    }
  }

  Future<void> _loadSavedPetType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _petType = prefs.getString('selected_desktop_pet_type') ?? 'dog';
    } catch (_) {}
  }

  Future<void> setPetType(String type) async {
    if (type != 'dog' && type != 'cat' && type != 'anime' && type != 'reaper') return;
    _petType = type;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_desktop_pet_type', type);
      
      // Update state file immediately
      final stateFile = await _getStateFile();
      if (stateFile != null && await stateFile.exists()) {
        final content = await stateFile.readAsString();
        if (content.isNotEmpty) {
          final data = json.decode(content);
          if (data is Map<String, dynamic>) {
            data['petType'] = _petType;
            await stateFile.writeAsString(json.encode(data));
          }
        }
      }
    } catch (_) {}
    if (onPetTypeChanged != null) {
      onPetTypeChanged!(_petType);
    }
  }

  void _startWatchingActions() {
    _actionWatchTimer?.cancel();
    _actionWatchTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      try {
        final actionFile = await _getActionFile();
        if (actionFile != null && await actionFile.exists()) {
          final content = await actionFile.readAsString();
          if (content.isNotEmpty) {
            final data = json.decode(content);
            if (data is Map) {
              final action = data['action'];
              if (action == 'complete' && data['noteId'] != null) {
                final noteId = data['noteId'].toString();
                await actionFile.delete();
                if (_onCompleteCallback != null && noteId.isNotEmpty) {
                  _onCompleteCallback!(noteId);
                }
              } else if (action == 'switch_pet' && data['petType'] != null) {
                final newType = data['petType'].toString();
                await actionFile.delete();
                await setPetType(newType);
              }
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<File?> _getStateFile() async {
    try {
      final appDocDir = await getApplicationSupportDirectory().timeout(const Duration(milliseconds: 500));
      final dir = Directory(p.join(appDocDir.path, 'NoteProData'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return File(p.join(dir.path, 'pet_state.json'));
    } catch (_) {
      return null;
    }
  }

  Future<File?> _getActionFile() async {
    try {
      final appDocDir = await getApplicationSupportDirectory().timeout(const Duration(milliseconds: 500));
      final dir = Directory(p.join(appDocDir.path, 'NoteProData'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return File(p.join(dir.path, 'pet_action.json'));
    } catch (_) {
      return null;
    }
  }

  Future<void> syncDeadlines({
    required List<NoteModel> pendingDeadlines,
    required bool isPetEnabled,
  }) async {
    if (!Platform.isWindows) return;

    try {
      final stateFile = await _getStateFile();
      if (stateFile == null) return;
      final now = DateTime.now();

      final listData = pendingDeadlines.map((n) {
        final d = n.reminderDateTime ?? now;
        return {
          'id': n.id,
          'title': n.title.isEmpty ? 'Ghi chú không tiêu đề' : n.title,
          'dueTime': '${d.hour}:${d.minute.toString().padLeft(2, '0')} ngày ${d.day}/${d.month}',
          'isOverdue': d.isBefore(now),
        };
      }).toList();

      final stateMap = {
        'hasPending': isPetEnabled && pendingDeadlines.isNotEmpty,
        'isPetEnabled': isPetEnabled,
        'petType': _petType,
        'deadlines': listData,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await stateFile.writeAsString(json.encode(stateMap));

      // If enabled, launch desktop pet process if not already running
      if (isPetEnabled) {
        await _ensurePetRunning();
      } else {
        try {
          Process.run('taskkill', ['/F', '/IM', 'DesktopPet.exe']);
        } catch (_) {}
      }
    } catch (_) {}
  }

  bool _isLaunching = false;

  Future<void> _ensurePetRunning() async {
    if (_isLaunching) return;
    _isLaunching = true;
    try {
      final result = await Process.run('tasklist', ['/FI', 'IMAGENAME eq DesktopPet.exe', '/NH']);
      if (result.stdout.toString().contains('DesktopPet.exe')) {
        return; // Already active on desktop!
      }

      final resolvedDir = File(Platform.resolvedExecutable).parent;
      final candidatePaths = <String>[];

      // Walk up directory tree from resolvedExecutable (up to 7 levels)
      Directory curr = resolvedDir;
      for (int i = 0; i < 7; i++) {
        candidatePaths.add(p.join(curr.path, 'desktop_pet', 'DesktopPet.exe'));
        candidatePaths.add(p.join(curr.path, 'DesktopPet.exe'));
        if (curr.parent.path == curr.path) break;
        curr = curr.parent;
      }
      candidatePaths.add(p.join(Directory.current.path, 'desktop_pet', 'DesktopPet.exe'));
      candidatePaths.add(p.join(Directory.current.path, 'DesktopPet.exe'));

      String? petExePath;
      for (final candidate in candidatePaths) {
        if (await File(candidate).exists()) {
          petExePath = candidate;
          break;
        }
      }

      if (petExePath != null) {
        _petProcess = await Process.start(
          petExePath,
          [],
          mode: ProcessStartMode.detached,
        );
      }
    } catch (_) {
    } finally {
      _isLaunching = false;
    }
  }

  void dispose() {
    _actionWatchTimer?.cancel();
  }
}
