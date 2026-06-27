import 'package:flutter/material.dart';

import '../models/highlight.dart';

/// Paints semi-transparent coloured rectangles over highlighted text regions.
///
/// The [highlights] list contains rects in **normalised coordinates** (0 → 1).
/// This widget scales them to the actual render size so they align perfectly
/// with the PDF page content underneath.
///
/// Because this is placed inside the `pageBuilder` of `CurlPageView`, the
/// highlights get baked into the snapshot image during page-curl animations.
class HighlightOverlay extends StatelessWidget {
  const HighlightOverlay({
    super.key,
    required this.highlights,
  });

  final List<Highlight> highlights;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _HighlightPainter(highlights),
      child: const SizedBox.expand(),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter(this.highlights);

  final List<Highlight> highlights;

  @override
  void paint(Canvas canvas, Size size) {
    for (final highlight in highlights) {
      final paint = Paint()
        ..color = highlight.color.value
        ..style = PaintingStyle.fill;

      for (final normRect in highlight.rects) {
        // Convert normalised (0..1) coordinates to pixel coordinates.
        final rect = Rect.fromLTRB(
          normRect.left * size.width,
          normRect.top * size.height,
          normRect.right * size.width,
          normRect.bottom * size.height,
        );
        // Rounded corners for a softer look.
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) {
    if (highlights.length != old.highlights.length) return true;
    for (var i = 0; i < highlights.length; i++) {
      if (highlights[i].id != old.highlights[i].id) return true;
      if (highlights[i].color != old.highlights[i].color) return true;
    }
    return false;
  }
}
