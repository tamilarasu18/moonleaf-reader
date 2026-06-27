import 'package:flutter/material.dart';

import '../models/highlight.dart';

/// A floating horizontal bar showing the available highlight colours.
///
/// Appears when highlight mode is active. The selected colour shows a check
/// mark. Tapping a circle fires [onColorSelected].
class HighlightColorPicker extends StatelessWidget {
  const HighlightColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    required this.onClose,
  });

  final HighlightColor selectedColor;
  final ValueChanged<HighlightColor> onColorSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Highlight icon.
          Icon(
            Icons.edit_rounded,
            color: Colors.white.withValues(alpha: 0.8),
            size: 18,
          ),
          const SizedBox(width: 10),

          // Colour circles.
          for (final color in HighlightColor.values) ...[
            _ColorCircle(
              color: color,
              isSelected: color == selectedColor,
              onTap: () => onColorSelected(color),
            ),
            if (color != HighlightColor.values.last) const SizedBox(width: 6),
          ],

          const SizedBox(width: 10),

          // Close button.
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final HighlightColor color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Use a more opaque version for the circle preview.
    final displayColor = color.value.withValues(alpha: 0.85);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isSelected ? 30 : 26,
        height: isSelected ? 30 : 26,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
