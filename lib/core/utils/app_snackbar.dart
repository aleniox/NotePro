import 'package:flutter/material.dart';
import '../../widgets/pet_notification_overlay.dart';

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    IconData? icon,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    PetMood mood = PetMood.happy,
    Duration duration = const Duration(milliseconds: 3800),
  }) {
    PetNotificationService.instance.show(
      message: message,
      title: title,
      icon: icon,
      iconColor: iconColor,
      actionLabel: actionLabel,
      onAction: onAction,
      mood: mood,
      duration: duration,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      title: '🎉 Hoan hô!',
      mood: PetMood.celebrate,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF10B981),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showTrash(
    BuildContext context,
    String message, {
    String? undoLabel,
    VoidCallback? onUndo,
  }) {
    show(
      context,
      message: message,
      title: '🗑️ Bé Pet đã dọn dẹp!',
      mood: PetMood.trash,
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      actionLabel: undoLabel,
      onAction: onUndo,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      title: '✨ Bé Pet ghi nhận!',
      mood: PetMood.info,
      icon: Icons.info_outline_rounded,
      iconColor: const Color(0xFF6366F1),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      title: '⚠️ Bé Pet nhắc nhở!',
      mood: PetMood.warning,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFF59E0B),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
