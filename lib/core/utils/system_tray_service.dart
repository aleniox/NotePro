import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'desktop_pet_service.dart';

class SystemTrayService with TrayListener, WindowListener {
  static final SystemTrayService instance = SystemTrayService._();
  SystemTrayService._();

  VoidCallback? onTogglePet;

  Future<void> init({VoidCallback? onTogglePetCallback}) async {
    if (!Platform.isWindows) return;

    onTogglePet = onTogglePetCallback;

    // Window Manager setup
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);

    // Tray Manager setup
    trayManager.addListener(this);
    await trayManager.setIcon('assets/app_icon.ico');
    await trayManager.setToolTip('NoteCards Pro - Ghi chú & Hạn chót');

    await _updateContextMenu();
  }

  Future<void> _updateContextMenu() async {
    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Mở NoteCards Pro',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'toggle_pet',
          label: 'Bật / Tắt Bé Pet màn hình 🐾',
        ),
        MenuItem.submenu(
          label: 'Chọn Bé Pet 🐾',
          submenu: Menu(
            items: [
              MenuItem(key: 'set_pet_dog', label: '🐶 Chú Cún Shiba (Puppy)'),
              MenuItem(key: 'set_pet_cat', label: '🐱 Bé Mèo Kawaii (Kitten)'),
              MenuItem(key: 'set_pet_anime', label: '🌸 Cô Bé Anime (Waifu)'),
              MenuItem(key: 'set_pet_cyber', label: '⚡ Bé Cyber Neko (Mecha Anime)'),
              MenuItem(key: 'set_pet_reaper', label: '💀 Thần Chết (Grim Reaper)'),
            ],
          ),
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Thoát hoàn toàn ✕',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  // WindowListener implementation
  @override
  void onWindowClose() async {
    // When user clicks the 'X' button on top-right of window:
    // Do NOT exit! Hide to system tray and keep running in background!
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  // TrayListener implementation
  @override
  void onTrayIconMouseDown() async {
    // Left click on tray icon restores window
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() async {
    // Right click opens context menu
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'toggle_pet':
        if (onTogglePet != null) {
          onTogglePet!();
        }
        break;
      case 'set_pet_dog':
        await DesktopPetService.instance.setPetType('dog');
        break;
      case 'set_pet_cat':
        await DesktopPetService.instance.setPetType('cat');
        break;
      case 'set_pet_anime':
        await DesktopPetService.instance.setPetType('anime');
        break;
      case 'set_pet_cyber':
        await DesktopPetService.instance.setPetType('cyber');
        break;
      case 'set_pet_reaper':
        await DesktopPetService.instance.setPetType('reaper');
        break;
      case 'exit_app':
        // Kill DesktopPet if running
        try {
          Process.runSync('taskkill', ['/F', '/IM', 'DesktopPet.exe']);
        } catch (_) {}

        // Destroy window and exit application completely
        await windowManager.destroy();
        exit(0);
    }
  }

  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
  }
}
