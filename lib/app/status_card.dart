import 'package:flutter/material.dart';

/// The four possible states for a bridge operation.
enum StatusType { idle, loading, success, failure }

/// A lightweight status indicator card shared across all sections.
///
/// Performance-optimized for mobile WebView:
///   • No AnimatedContainer — uses plain Container (avoids repaint per frame).
///   • No AnimatedDefaultTextStyle — static TextStyle (avoids layout pass).
///   • Keeps AnimatedSwitcher ONLY on the icon (tiny region, fast swap).
///   • All color lookups use const constructors (no runtime allocation).
class StatusCard extends StatelessWidget {
  final StatusType type;
  final String title;
  final String message;

  const StatusCard({
    super.key,
    required this.type,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(type);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: colors.accent, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only animate the icon (tiny 18×18 region — minimal GPU cost).
          _buildIcon(type, colors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: colors.text,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(StatusType type, Color color) {
    return switch (type) {
      StatusType.idle => Icon(Icons.radio_button_unchecked, size: 18, color: color),
      StatusType.loading => SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      StatusType.success => Icon(Icons.check_circle_outline, size: 18, color: color),
      StatusType.failure => Icon(Icons.error_outline, size: 18, color: color),
    };
  }
}

class _StatusColors {
  final Color accent;
  final Color background;
  final Color text;

  const _StatusColors({
    required this.accent,
    required this.background,
    required this.text,
  });
}

_StatusColors _colorsFor(StatusType type) {
  return switch (type) {
    StatusType.idle => const _StatusColors(
        accent: Color(0xFF94A3B8),
        background: Color(0xFF161B22),
        text: Color(0xFF94A3B8),
      ),
    StatusType.loading => const _StatusColors(
        accent: Color(0xFFFBBF24),
        background: Color(0x1AFBBF24),
        text: Color(0xFFE2E8F0),
      ),
    StatusType.success => const _StatusColors(
        accent: Color(0xFF34D399),
        background: Color(0x1A34D399),
        text: Color(0xFFE2E8F0),
      ),
    StatusType.failure => const _StatusColors(
        accent: Color(0xFFF87171),
        background: Color(0x1AF87171),
        text: Color(0xFFE2E8F0),
      ),
  };
}
