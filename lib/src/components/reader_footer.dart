import 'package:flutter/material.dart';

import '../theme/reader_theme.dart';

/// The reading footer shared by the text and PDF readers.
///
/// Two modes:
/// - **Classic** (default): previous / next chevron buttons with a centred
///   status label. Used by the text reader.
/// - **Slider** (when [totalPages] is set): a draggable page scrubber with
///   progress percentage. Used by the PDF reader for quick page navigation.
///
/// Both modes show a thin progress bar at the top and are painted in the
/// active [ReaderColors] palette.
class ReaderFooter extends StatelessWidget {
  const ReaderFooter({
    super.key,
    required this.colors,
    required this.progress,
    required this.label,
    required this.canPrevious,
    required this.canNext,
    required this.onPrevious,
    required this.onNext,
    this.totalPages,
    this.currentPage,
    this.onPageScrub,
  });

  final ReaderColors colors;
  final double progress;
  final String label;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// When set, the footer renders a slider instead of chevron buttons.
  final int? totalPages;

  /// 0-based current page index (required when [totalPages] is set).
  final int? currentPage;

  /// Called when the user scrubs the slider to a new page.
  final ValueChanged<int>? onPageScrub;

  bool get _useSlider => totalPages != null && totalPages! > 1;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin progress bar.
            LinearProgressIndicator(
              value: progress,
              minHeight: 2.5,
              backgroundColor: colors.surface,
              color: const Color(0xFFE6BE72),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: _useSlider ? _buildSlider() : _buildClassic(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Classic mode (text reader) ───────────────────────────────────────────

  Widget _buildClassic() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: colors.text,
          disabledColor: colors.faint.withValues(alpha: 0.4),
          onPressed: canPrevious ? onPrevious : null,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.faint, fontSize: 13),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: colors.text,
          disabledColor: colors.faint.withValues(alpha: 0.4),
          onPressed: canNext ? onNext : null,
        ),
      ],
    );
  }

  // ── Slider mode (PDF reader) ─────────────────────────────────────────────

  Widget _buildSlider() {
    final page = (currentPage ?? 0).clamp(0, (totalPages ?? 1) - 1);
    final total = totalPages ?? 1;
    final pct = ((page + 1) / total * 100).round();

    return Row(
      children: [
        // Page counter.
        SizedBox(
          width: 60,
          child: Text(
            '${page + 1}/$total',
            style: TextStyle(
              color: colors.faint,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Slider.
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFE6BE72),
              inactiveTrackColor: colors.faint.withValues(alpha: 0.18),
              thumbColor: const Color(0xFFE6BE72),
              overlayColor: const Color(0xFFE6BE72).withValues(alpha: 0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 7,
                elevation: 2,
              ),
            ),
            child: Slider(
              value: page.toDouble(),
              min: 0,
              max: (total - 1).toDouble().clamp(0, double.maxFinite),
              onChanged: (v) => onPageScrub?.call(v.round()),
            ),
          ),
        ),
        // Progress percentage.
        SizedBox(
          width: 40,
          child: Text(
            '$pct%',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: colors.faint,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
