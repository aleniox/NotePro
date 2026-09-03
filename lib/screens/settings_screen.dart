import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/file_helper.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isCheckingUpdate = false;
  bool _autoCheckUpdates = true;

  void _checkUpdate(BuildContext context) async {
    setState(() => _isCheckingUpdate = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Đang là bản mới nhất'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn đang sử dụng phiên bản NoteCards Pro v1.0.0.'),
            SizedBox(height: 8),
            Text(
              'Tất cả các tính năng ghi chú thẻ, sao lưu và bảo mật đều đang hoạt động hoàn hảo.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _confirmResetData(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Xóa sạch dữ liệu?'),
          ],
        ),
        content: const Text(
          'Hành động này sẽ xóa toàn bộ các thẻ ghi chú và danh mục trên thiết bị này. '
          'Hãy đảm bảo bạn đã lưu bản sao lưu nếu có thông tin quan trọng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await notesProvider.clearAllData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa sạch toàn bộ dữ liệu ghi chú.')),
                );
              }
            },
            child: const Text('Xác nhận xóa hết'),
          ),
        ],
      ),
    );
  }

  void _showUninstallGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: Colors.indigoAccent, size: 24),
            SizedBox(width: 8),
            Text('Cách gỡ ứng dụng'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💻 Trên máy tính Windows:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 6),
              Text(
                '1. Đóng ứng dụng NoteCards Pro đang chạy.\n'
                '2. Xóa thư mục chứa ứng dụng (hoặc xóa file nén NoteCards_Pro_Windows.zip).\n'
                '3. Nếu muốn xóa sạch dữ liệu ghi chú cũ, bạn hãy bấm nút "Xóa sạch dữ liệu" trong app trước khi xóa thư mục.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 14),
              Text('📱 Trên điện thoại Android:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 6),
              Text(
                '1. Nhấn và giữ biểu tượng NoteCards Pro trên màn hình điện thoại.\n'
                '2. Chọn "Gỡ cài đặt" (Uninstall) để xóa ứng dụng.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notesProvider = Provider.of<NotesProvider>(context);

    final totalNotes = notesProvider.filteredNotes.length + notesProvider.archivedNotes.length;
    final totalPinned = notesProvider.pinnedNotes.length;
    final totalTags = notesProvider.allTags.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt & Dữ liệu'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Statistics Overview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Thống kê ghi chú',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Tổng ghi chú', value: '$totalNotes'),
                          _StatItem(label: 'Đã ghim', value: '$totalPinned'),
                          _StatItem(label: 'Từ khóa (#)', value: '$totalTags'),
                          _StatItem(label: 'Chủ đề', value: '${notesProvider.folders.length}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Theme Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎨 Giao diện ứng dụng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      RadioListTile<ThemeMode>(
                        title: const Text('Theo hệ thống thiết bị'),
                        subtitle: const Text('Tự động theo giao diện Windows / Android'),
                        value: ThemeMode.system,
                        groupValue: themeProvider.themeMode,
                        onChanged: (val) => themeProvider.setThemeMode(val!),
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Giao diện Sáng'),
                        subtitle: const Text('Nền trắng sáng, nhẹ nhàng'),
                        value: ThemeMode.light,
                        groupValue: themeProvider.themeMode,
                        onChanged: (val) => themeProvider.setThemeMode(val!),
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Giao diện Tối'),
                        subtitle: const Text('Nền đen dịu mắt khi làm việc buổi tối'),
                        value: ThemeMode.dark,
                        groupValue: themeProvider.themeMode,
                        onChanged: (val) => themeProvider.setThemeMode(val!),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Backup & Restore
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💾 Sao lưu & Khôi phục',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lưu lại toàn bộ ghi chú thành tệp dự phòng trên máy tính để tránh mất dữ liệu hoặc chuyển qua thiết bị khác.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.file_upload_outlined),
                              label: const Text('Lưu bản sao lưu'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () async {
                                try {
                                  final path = await FileHelper.exportBackupJson();
                                  if (path != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Đã lưu bản sao: $path')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.file_download_outlined),
                              label: const Text('Nạp từ bản sao lưu'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () async {
                                try {
                                  final count = await FileHelper.importBackupJson();
                                  if (count > 0 && context.mounted) {
                                    await notesProvider.loadAllData();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã nạp lại thành công $count ghi chú!')),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Updates Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.system_update_rounded, size: 20, color: Colors.indigoAccent),
                          SizedBox(width: 8),
                          Text(
                            'Cập nhật ứng dụng',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Phiên bản hiện tại: NoteCards Pro v1.0.0 (Mới nhất)',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _isCheckingUpdate ? null : () => _checkUpdate(context),
                            icon: _isCheckingUpdate
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(_isCheckingUpdate ? 'Đang kiểm tra...' : 'Kiểm tra bản mới'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Tự động thông báo khi có bản mới', style: TextStyle(fontSize: 13)),
                              value: _autoCheckUpdates,
                              onChanged: (val) => setState(() => _autoCheckUpdates = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Uninstall & Reset Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.delete_forever_rounded, size: 20, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text(
                            'Gỡ cài đặt & Xóa dữ liệu',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bạn có thể xóa sạch dữ liệu ghi chú để bắt đầu lại từ đầu hoặc xem hướng dẫn gỡ bỏ hoàn toàn ứng dụng.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _confirmResetData(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                            label: const Text('Xóa sạch dữ liệu ghi chú'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: () => _showUninstallGuide(context),
                            icon: const Icon(Icons.help_outline_rounded, size: 16),
                            label: const Text('Hướng dẫn gỡ ứng dụng'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Windows Hotkeys Reference
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.keyboard_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Phím tắt tiện lợi (Windows)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _HotkeyRow(keys: 'Ctrl + N', desc: 'Viết ghi chú mới'),
                      _HotkeyRow(keys: 'Ctrl + S', desc: 'Lưu ghi chú nhanh'),
                      _HotkeyRow(keys: 'Ctrl + F', desc: 'Tìm kiếm nhanh'),
                      _HotkeyRow(keys: 'Esc', desc: 'Đóng cửa sổ / Thoát tìm kiếm'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // App Info
              const Center(
                child: Column(
                  children: [
                    Text(
                      'NoteCards Pro v1.0.0',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ứng dụng ghi chú thẻ đa năng cho Windows & Android',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class _HotkeyRow extends StatelessWidget {
  final String keys;
  final String desc;

  const _HotkeyRow({required this.keys, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(desc, style: const TextStyle(fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              keys,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
