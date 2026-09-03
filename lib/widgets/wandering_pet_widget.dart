import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../screens/note_editor_screen.dart';

class WanderingPetWidget extends StatefulWidget {
  const WanderingPetWidget({super.key});

  @override
  State<WanderingPetWidget> createState() => _WanderingPetWidgetState();
}

class _WanderingPetWidgetState extends State<WanderingPetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _walkAnimController;
  Timer? _wanderTimer;
  Timer? _speechTimer;

  // Position on screen: xFraction ranges from 0.05 to 0.85
  double _xRatio = 0.5;
  double _targetXRatio = 0.5;
  bool _facingRight = true;
  bool _isWalking = false;
  bool _isCelebrating = false;

  // Speech bubble state
  bool _showBubble = true;
  int _speechIndex = 0;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Walking leg/ear oscillation animation
    _walkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    // Wandering loop: every 4-7 seconds, choose a random spot to walk to
    _wanderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _isCelebrating) return;
      _pickNewDestination();
    });

    // Speech cycler
    _speechTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) return;
      setState(() {
        _speechIndex = (_speechIndex + 1) % 4;
        _showBubble = true;
      });
    });
  }

  @override
  void dispose() {
    _wanderTimer?.cancel();
    _speechTimer?.cancel();
    _walkAnimController.dispose();
    super.dispose();
  }

  void _pickNewDestination() {
    final newTarget = 0.1 + _random.nextDouble() * 0.75;
    setState(() {
      _targetXRatio = newTarget;
      _facingRight = _targetXRatio > _xRatio;
      _isWalking = true;
      _xRatio = newTarget;
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isWalking = false;
        });
      }
    });
  }

  void _onCompleteDeadline(NoteModel note) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    setState(() {
      _isCelebrating = true;
      _showBubble = true;
    });

    await notesProvider.toggleDeadlineCompleted(note);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Tuyệt vời! Đã hoàn thành "${note.title.isEmpty ? 'ghi chú' : note.title}"'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }

    // Celebration dance for 2 seconds, then if no more urgent deadlines, pet will gracefully leave
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isCelebrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = Provider.of<NotesProvider>(context);

    if (!notesProvider.isPetEnabled) {
      return const SizedBox.shrink();
    }

    final deadlines = notesProvider.pendingDeadlines;

    // THE USER'S CORE RULE:
    // "con pet sẽ chạy đi chạy lại trên màn hình chỉ khi tôi hoàn thành nó thì nó mới biến mất"
    // If there are no pending deadlines, the pet disappears!
    if (deadlines.isEmpty && !_isCelebrating) {
      return const SizedBox.shrink();
    }

    final currentDeadline = deadlines.isNotEmpty ? deadlines.first : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final currentPixelX = (_xRatio * (screenWidth - 220)).clamp(20.0, screenWidth - 220.0);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOutCubic,
      left: currentPixelX,
      bottom: 24,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              _facingRight ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            // Speech Bubble Reminder
            if (_showBubble && currentDeadline != null)
              _buildSpeechBubble(context, currentDeadline, isDark)
            else if (_isCelebrating)
              _buildCelebrationBubble(),

            const SizedBox(height: 6),

            // Animated Pet Body
            InkWell(
              onTap: () {
                setState(() {
                  _showBubble = !_showBubble;
                });
              },
              borderRadius: BorderRadius.circular(30),
              child: AnimatedBuilder(
                animation: _walkAnimController,
                builder: (context, child) {
                  final walkBounce = _isWalking
                      ? sin(_walkAnimController.value * pi) * 6.0
                      : (_isCelebrating ? -sin(_walkAnimController.value * pi * 2) * 12.0 : 0.0);

                  final wiggle = _isWalking
                      ? (_walkAnimController.value - 0.5) * 0.15
                      : (_isCelebrating ? (_walkAnimController.value - 0.5) * 0.35 : 0.0);

                  return Transform.translate(
                    offset: Offset(0, walkBounce),
                    child: Transform.rotate(
                      angle: wiggle,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(_facingRight ? 1.0 : -1.0, 1.0, 1.0),
                        child: _buildCutePetGraphic(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎉 ', style: TextStyle(fontSize: 18)),
          Text(
            'Giỏi quá! Đã xong việc rồi nha~',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(' ✨', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble(BuildContext context, NoteModel note, bool isDark) {
    final deadline = note.reminderDateTime!;
    final now = DateTime.now();
    final isOverdue = deadline.isBefore(now);

    final speechTexts = [
      'Chủ nhân ơi! Bạn có việc sắp đến hạn nè! ⏰',
      'Đừng quên việc này nha, cố lên nè! 🐾',
      'Mình sẽ lon ton ở đây cho tới khi bạn hoàn thành mới thôi đó! 😺',
      'Mau bấm [Xong việc] để mình đi nghỉ ngơi nhé! 💖',
    ];
    final petMessage = speechTexts[_speechIndex % speechTexts.length];

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? Colors.redAccent : const Color(0xFF6366F1),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Pet title & status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isOverdue ? Icons.warning_amber_rounded : Icons.pets_rounded,
                    size: 16,
                    color: isOverdue ? Colors.redAccent : const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOverdue ? 'DEADLINE QUÁ HẠN!' : 'BÉ PET NHẮC VIỆC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isOverdue ? Colors.redAccent : const Color(0xFF6366F1),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Thu nhỏ lời nhắc',
                onPressed: () => setState(() => _showBubble = false),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Pet message
          Text(
            petMessage,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),

          // Note Title Card inside bubble
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_rounded, size: 14, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Ghi chú không tiêu đề' : note.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Action Buttons: Complete Now!
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _onCompleteDeadline(note),
                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                  label: const Text('Xong việc!', style: TextStyle(fontSize: 11.5)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 30),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('Mở xem', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Pure Flutter custom-drawn cute pet graphic (Cat/Puppy with expressive eyes, ears, bell)
  Widget _buildCutePetGraphic() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF0), // Creamy fur
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4A3728), width: 2.2), // Dark outline
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left Ear
          Positioned(
            top: -2,
            left: 8,
            child: _buildEar(isLeft: true),
          ),
          // Right Ear
          Positioned(
            top: -2,
            right: 8,
            child: _buildEar(isLeft: false),
          ),

          // Face container
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // Eyes and Cheeks Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left Cheek Blush
                  Container(
                    width: 7,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Left Eye
                  _buildEye(),
                  const SizedBox(width: 14),
                  // Right Eye
                  _buildEye(),
                  const SizedBox(width: 4),
                  // Right Cheek Blush
                  Container(
                    width: 7,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Nose & Smile
              Column(
                children: [
                  // Little nose
                  Container(
                    width: 5,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3728),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Happy 'w' mouth
                  const Text(
                    'w',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4A3728),
                      height: 0.9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Collar with bell
              Container(
                width: 24,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(3),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          // Foot steps when walking
          if (_isWalking)
            Positioned(
              bottom: 2,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3728),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 7,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3728),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEar({required bool isLeft}) {
    return Transform.rotate(
      angle: isLeft ? -0.3 : 0.3,
      child: Container(
        width: 15,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFFFF9E80), // Orange/Pink inner ear
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isLeft ? 12 : 3),
            topRight: Radius.circular(isLeft ? 3 : 12),
            bottomLeft: const Radius.circular(4),
            bottomRight: const Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFF4A3728), width: 2),
        ),
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: 7,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 2.5,
          height: 2.5,
          margin: const EdgeInsets.only(left: 1, top: 1),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
