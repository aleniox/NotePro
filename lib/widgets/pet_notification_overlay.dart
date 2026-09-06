import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/desktop_pet_service.dart';
import '../providers/notes_provider.dart';

enum PetMood {
  happy,
  celebrate,
  trash,
  info,
  warning,
}

class PetNotificationItem {
  final String id;
  final String? title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final PetMood mood;
  final Duration duration;
  final DateTime createdAt;

  PetNotificationItem({
    required this.id,
    this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.mood = PetMood.happy,
    this.duration = const Duration(milliseconds: 3800),
  }) : createdAt = DateTime.now();
}

class PetNotificationService {
  static final PetNotificationService instance = PetNotificationService._();
  PetNotificationService._();

  final ValueNotifier<PetNotificationItem?> notificationNotifier = ValueNotifier(null);
  Timer? _dismissTimer;

  void show({
    required String message,
    String? title,
    IconData? icon,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    PetMood mood = PetMood.happy,
    Duration duration = const Duration(milliseconds: 3800),
  }) {
    _dismissTimer?.cancel();

    final item = PetNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      icon: icon ?? _getDefaultIcon(mood),
      iconColor: iconColor ?? _getDefaultColor(mood),
      actionLabel: actionLabel,
      onAction: onAction,
      mood: mood,
      duration: duration,
    );

    notificationNotifier.value = item;

    _dismissTimer = Timer(duration, () {
      if (notificationNotifier.value?.id == item.id) {
        dismiss();
      }
    });
  }

  void dismiss() {
    _dismissTimer?.cancel();
    notificationNotifier.value = null;
  }

  static String getPetTitle(String petType, PetMood mood) {
    switch (petType) {
      case 'anime':
        switch (mood) {
          case PetMood.celebrate:
            return '🌸 Em Khen Senpai!';
          case PetMood.trash:
            return '🗑️ Em Đã Dọn Giúp Senpai!';
          case PetMood.warning:
            return '⚠️ Senpai Ơi Chú Ý!';
          case PetMood.info:
            return '🌸 Em Đã Ghi Nhớ Cho Senpai!';
          case PetMood.happy:
          default:
            return '🌸 Trợ Lý Anime (Waifu)';
        }
      case 'reaper':
        switch (mood) {
          case PetMood.celebrate:
            return '💀 Thần Chết Thán Phục!';
          case PetMood.trash:
            return '🗑️ Đã Tiễn Vào Thùng Rác!';
          case PetMood.warning:
            return '⚠️ Cảnh Báo Thần Chết!';
          case PetMood.info:
            return '🔮 Đã Khắc Vào Sổ Sinh Tử!';
          case PetMood.happy:
          default:
            return '💀 Thần Chết Chibi';
        }
      case 'cat':
        switch (mood) {
          case PetMood.celebrate:
            return '🎉 Bé Mèo Khen Bạn!';
          case PetMood.trash:
            return '🗑️ Bé Mèo Đã Dọn Dẹp!';
          case PetMood.warning:
            return '⚠️ Bé Mèo Nhắc Bạn!';
          case PetMood.info:
            return '✨ Bé Mèo Đã Ghi Nhớ!';
          case PetMood.happy:
          default:
            return '🐱 Bé Mèo Kawaii';
        }
      case 'dog':
      default:
        switch (mood) {
          case PetMood.celebrate:
            return '🐶 Cún Shiba Cổ Vũ!';
          case PetMood.trash:
            return '🗑️ Cún Shiba Đã Thu Dọn!';
          case PetMood.warning:
            return '⚠️ Cún Shiba Nhắc Nhở!';
          case PetMood.info:
            return '✨ Cún Shiba Ghi Nhận!';
          case PetMood.happy:
          default:
            return '🐶 Chú Cún Shiba';
        }
    }
  }

  static IconData _getDefaultIcon(PetMood mood) {
    switch (mood) {
      case PetMood.celebrate:
        return Icons.celebration_rounded;
      case PetMood.trash:
        return Icons.delete_sweep_rounded;
      case PetMood.warning:
        return Icons.warning_amber_rounded;
      case PetMood.info:
        return Icons.info_outline_rounded;
      case PetMood.happy:
      default:
        return Icons.pets_rounded;
    }
  }

  static Color _getDefaultColor(PetMood mood) {
    switch (mood) {
      case PetMood.celebrate:
        return const Color(0xFF10B981);
      case PetMood.trash:
        return const Color(0xFFEF4444);
      case PetMood.warning:
        return const Color(0xFFF59E0B);
      case PetMood.info:
        return const Color(0xFF6366F1);
      case PetMood.happy:
      default:
        return const Color(0xFF3B82F6);
    }
  }
}

/// Overlay container that displays the floating Pet + Speech bubble notification
class PetNotificationOverlay extends StatefulWidget {
  final Widget child;

  const PetNotificationOverlay({super.key, required this.child});

  @override
  State<PetNotificationOverlay> createState() => _PetNotificationOverlayState();
}

class _PetNotificationOverlayState extends State<PetNotificationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _appearController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _floatController;
  late AnimationController _progressController;

  PetNotificationItem? _activeItem;

  @override
  void initState() {
    super.initState();

    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _appearController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.15, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    PetNotificationService.instance.notificationNotifier.addListener(_onNotificationChanged);
  }

  @override
  void dispose() {
    PetNotificationService.instance.notificationNotifier.removeListener(_onNotificationChanged);
    _appearController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _onNotificationChanged() {
    final newItem = PetNotificationService.instance.notificationNotifier.value;
    if (newItem != null) {
      setState(() {
        _activeItem = newItem;
      });
      _floatController.repeat(reverse: true);
      _progressController.duration = newItem.duration;
      _progressController.forward(from: 0.0);
      _appearController.forward(from: 0.0);
    } else {
      _floatController.stop();
      _appearController.reverse().then((_) {
        if (mounted && PetNotificationService.instance.notificationNotifier.value == null) {
          setState(() {
            _activeItem = null;
          });
        }
      });
    }
  }

  String _resolvePetType(BuildContext context) {
    return DesktopPetService.instance.petType;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_activeItem != null)
          Positioned(
            right: 20,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.bottomRight,
                    child: _buildPetToastCard(context, _activeItem!),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPetToastCard(BuildContext context, PetNotificationItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxBubbleWidth = min(screenWidth - 48, 360.0);
    final petType = _resolvePetType(context);
    final cardTitle = item.title ?? PetNotificationService.getPetTitle(petType, item.mood);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Speech Bubble
        Container(
          width: maxBubbleWidth,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.iconColor?.withValues(alpha: 0.5) ??
                  (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (item.iconColor ?? Colors.black).withValues(alpha: isDark ? 0.32 : 0.12),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
                  child: Row(
                    children: [
                      // Icon Badge
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: (item.iconColor ?? const Color(0xFF6366F1)).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.icon ?? Icons.pets_rounded,
                          size: 15,
                          color: item.iconColor ?? const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Title
                      Expanded(
                        child: Text(
                          cardTitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Close button
                      InkWell(
                        onTap: () => PetNotificationService.instance.dismiss(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Message Text
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                  child: Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Action Button (if any)
                if (item.actionLabel != null && item.onAction != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () {
                            item.onAction!();
                            PetNotificationService.instance.dismiss();
                          },
                          icon: const Icon(Icons.undo_rounded, size: 14),
                          label: Text(
                            item.actionLabel!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Auto-dismiss linear progress indicator bar
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, _) {
                    return LinearProgressIndicator(
                      value: 1.0 - _progressController.value,
                      minHeight: 2.5,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (item.iconColor ?? const Color(0xFF6366F1)).withValues(alpha: 0.6),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Speech Bubble Tail pointing down to Pet
        Padding(
          padding: const EdgeInsets.only(right: 32),
          child: CustomPaint(
            size: const Size(16, 8),
            painter: _SpeechBubbleTailPainter(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderColor: item.iconColor?.withValues(alpha: 0.5) ??
                  (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
        ),

        // Cute Animated Selected Pet Avatar
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final dy = sin(_floatController.value * pi) * 3;
            return Transform.translate(
              offset: Offset(0, dy),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 12, top: 2),
            child: _buildSelectedPetAvatar(petType, item.mood),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPetAvatar(String petType, PetMood mood) {
    switch (petType) {
      case 'anime':
        return _buildAnimeGirlAvatar(mood);
      case 'reaper':
        return _buildReaperAvatar(mood);
      case 'cat':
        return _buildCatAvatar(mood);
      case 'dog':
      default:
        return _buildShibaAvatar(mood);
    }
  }

  // 🐶 1. Chú Cún Shiba (Puppy)
  Widget _buildShibaAvatar(PetMood mood) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B), // Shiba golden orange
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF78350F), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shiba Floppy Ears
          Positioned(
            top: -2,
            left: 5,
            child: _buildShibaEar(isLeft: true),
          ),
          Positioned(
            top: -2,
            right: 5,
            child: _buildShibaEar(isLeft: false),
          ),

          // Creamy Muzzle / Cheeks
          Positioned(
            bottom: 4,
            child: Container(
              width: 38,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          // Face Elements
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Eyes Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPupil(mood),
                  const SizedBox(width: 14),
                  _buildPupil(mood),
                ],
              ),
              const SizedBox(height: 2),
              // Little Black Nose & Tongue
              Column(
                children: [
                  Container(
                    width: 6,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 1),
                  if (mood == PetMood.celebrate || mood == PetMood.happy)
                    Container(
                      width: 5,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF43F5E),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
                      ),
                    )
                  else
                    const Text(
                      'w',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78350F),
                        height: 0.8,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Little Blue Collar
          Positioned(
            bottom: 0,
            child: Container(
              width: 22,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShibaEar({required bool isLeft}) {
    return Transform.rotate(
      angle: isLeft ? -0.32 : 0.32,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: const Color(0xFFD97706),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF78350F), width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // 🐱 2. Bé Mèo Kawaii (Kitten)
  Widget _buildCatAvatar(PetMood mood) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF0), // Creamy fur
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4A3728), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: -2, left: 6, child: _buildCatEar(isLeft: true)),
          Positioned(top: -2, right: 6, child: _buildCatEar(isLeft: false)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 5,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 3),
                  _buildPupil(mood),
                  const SizedBox(width: 10),
                  _buildPupil(mood),
                  const SizedBox(width: 3),
                  Container(
                    width: 5,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'w',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4A3728),
                  height: 0.8,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 1,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatEar({required bool isLeft}) {
    return Transform.rotate(
      angle: isLeft ? -0.28 : 0.28,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAF0),
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(8) : const Radius.circular(3),
            topRight: isLeft ? const Radius.circular(3) : const Radius.circular(8),
          ),
          border: Border.all(color: const Color(0xFF4A3728), width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB6C1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // 🌸 3. Cô Bé Anime (Waifu Chibi)
  Widget _buildAnimeGirlAvatar(PetMood mood) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2), // Soft pink skin
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFB7185), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFB7185).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anime Pink Hair Fringe / Bangs
          Positioned(
            top: 0,
            child: Container(
              width: 46,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFF472B6), // Cute pink hair
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                  bottom: Radius.circular(8),
                ),
              ),
            ),
          ),

          // Sakura Hair Clip 🌸
          Positioned(
            top: 4,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E6),
                shape: BoxShape.circle,
              ),
              child: const Text('🌸', style: TextStyle(fontSize: 9)),
            ),
          ),

          // Face
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Sparkle Anime Eyes & Rosy Cheeks
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 5,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB7185),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 3),
                  _buildAnimeEye(mood),
                  const SizedBox(width: 10),
                  _buildAnimeEye(mood),
                  const SizedBox(width: 3),
                  Container(
                    width: 5,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB7185),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Cute smile
              Container(
                width: 4,
                height: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFFE11D48),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
                ),
              ),
            ],
          ),

          // Pink Ribbon at Bottom
          Positioned(
            bottom: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('🎀', style: TextStyle(fontSize: 8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeEye(PetMood mood) {
    if (mood == PetMood.celebrate || mood == PetMood.happy) {
      return const Text(
        '★',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color(0xFFDB2777),
          height: 0.9,
        ),
      );
    }
    // Large Sparkly Anime Pupil with Highlights
    return Container(
      width: 7,
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFF831843),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 1,
            right: 1,
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💀 4. Thần Chết Chibi (Grim Reaper)
  Widget _buildReaperAvatar(PetMood mood) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark robe cowl
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6366F1), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner Shadow Hood
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1B4B),
              shape: BoxShape.circle,
            ),
          ),

          // Glowing Mystical Cyan Eyes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildReaperEye(mood),
              const SizedBox(width: 10),
              _buildReaperEye(mood),
            ],
          ),

          // Tiny Silver Skull Emblem at Bottom
          Positioned(
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('💀', style: TextStyle(fontSize: 8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaperEye(PetMood mood) {
    final glowColor = mood == PetMood.trash ? const Color(0xFFEF4444) : const Color(0xFF22D3EE);
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: glowColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.8),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildPupil(PetMood mood) {
    if (mood == PetMood.celebrate || mood == PetMood.happy) {
      return const Text(
        '^',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A3728),
          height: 0.9,
        ),
      );
    }
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFF4A3728),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SpeechBubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _SpeechBubbleTailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(0, 0), Offset(size.width / 2, size.height), borderPaint);
    canvas.drawLine(Offset(size.width / 2, size.height), Offset(size.width, 0), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}
