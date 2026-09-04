import 'package:flutter/material.dart';

/// A modern, polished squircle toggle button for expanding/collapsing the sidebar
/// or closing the drawer on mobile/tablet.
class SidebarToggleButton extends StatefulWidget {
  final bool isCollapsed;
  final bool isDrawer;
  final VoidCallback onTap;
  final String? tooltip;
  final IconData? icon;

  const SidebarToggleButton({
    super.key,
    this.isCollapsed = false,
    this.isDrawer = false,
    required this.onTap,
    this.tooltip,
    this.icon,
  });

  @override
  State<SidebarToggleButton> createState() => _SidebarToggleButtonState();
}

class _SidebarToggleButtonState extends State<SidebarToggleButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final tooltipText = widget.tooltip ??
        (widget.isDrawer
            ? 'Đóng menu'
            : widget.isCollapsed
                ? 'Mở rộng thanh bên (Ctrl+B)'
                : 'Thu gọn thanh bên (Ctrl+B)');

    final IconData displayIcon = widget.icon ??
        (widget.isDrawer
            ? Icons.close_rounded
            : Icons.view_sidebar_outlined);

    final Color backgroundColor;
    final Color borderColor;
    final Color iconColor;

    if (isDark) {
      if (_isHovered) {
        backgroundColor = primaryColor.withValues(alpha: 0.20);
        borderColor = primaryColor.withValues(alpha: 0.55);
        iconColor = Colors.white;
      } else {
        backgroundColor = const Color(0xFF1E293B).withValues(alpha: 0.65);
        borderColor = const Color(0xFF334155).withValues(alpha: 0.7);
        iconColor = Colors.grey.shade400;
      }
    } else {
      if (_isHovered) {
        backgroundColor = primaryColor.withValues(alpha: 0.12);
        borderColor = primaryColor.withValues(alpha: 0.45);
        iconColor = primaryColor;
      } else {
        backgroundColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFCBD5E1);
        iconColor = const Color(0xFF64748B);
      }
    }

    final scale = _isPressed ? 0.93 : (_isHovered ? 1.05 : 1.0);

    return Tooltip(
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: (isDark ? Colors.black : primaryColor).withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  displayIcon,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
