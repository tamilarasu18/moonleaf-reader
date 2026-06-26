import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/page_turner.dart';
import '../theme/reader_theme.dart';
import '../utils/constants.dart';
import '../viewmodels/app_viewmodel.dart';

/// Opens the reading-display settings sheet. Reads/writes [AppViewModel],
/// which is provided above [MaterialApp], so it is available here.
Future<void> showReaderSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _ReaderSettingsSheet(),
  );
}

class _ReaderSettingsSheet extends StatelessWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final settings = vm.reader;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('Reading display', style: text.titleLarge),
            const SizedBox(height: 20),

            // Theme / palette.
            Text('Theme', style: text.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ReaderPalette>(
              segments: [
                for (final p in ReaderPalette.values)
                  ButtonSegment(
                    value: p,
                    label: Text(p.label),
                    icon: Icon(p.icon),
                  ),
              ],
              selected: {settings.palette},
              showSelectedIcon: false,
              onSelectionChanged: (s) => context.read<AppViewModel>().setPalette(s.first),
            ),
            const SizedBox(height: 22),

            // Background warmth.
            Row(
              children: [
                Text('Warmth', style: text.labelLarge),
                const Spacer(),
                Text('${(settings.warmth * 100).round()} %',
                    style: text.bodySmall),
              ],
            ),
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined,
                    size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                Expanded(
                  child: Slider(
                    value: settings.warmth,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: (v) => context.read<AppViewModel>().setWarmth(v),
                  ),
                ),
                Icon(Icons.wb_sunny,
                    size: 22, color: const Color(0xFFE6A817)),
              ],
            ),
            const SizedBox(height: 8),

            // Text size.
            Row(
              children: [
                Text('Text size', style: text.labelLarge),
                const Spacer(),
                Text('${settings.fontSize.round()} pt', style: text.bodySmall),
              ],
            ),
            Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Slider(
                    value: settings.fontSize,
                    min: AppConstants.minFontSize,
                    max: AppConstants.maxFontSize,
                    divisions:
                        (AppConstants.maxFontSize - AppConstants.minFontSize).round(),
                    onChanged: (v) => context.read<AppViewModel>().setFontSize(v),
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 8),

            // Line spacing.
            Row(
              children: [
                Text('Line spacing', style: text.labelLarge),
                const Spacer(),
                Text(settings.lineHeight.toStringAsFixed(1), style: text.bodySmall),
              ],
            ),
            Slider(
              value: settings.lineHeight,
              min: AppConstants.minLineHeight,
              max: AppConstants.maxLineHeight,
              divisions:
                  ((AppConstants.maxLineHeight - AppConstants.minLineHeight) * 10)
                      .round(),
              onChanged: (v) => context.read<AppViewModel>().setLineHeight(v),
            ),
            const SizedBox(height: 16),

            // Typeface.
            Text('Typeface', style: text.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeChoice(
                    label: 'Serif',
                    sample: 'Lora',
                    fontFamily: AppConstants.fontReading,
                    selected: settings.serif,
                    onTap: () => context.read<AppViewModel>().setSerif(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeChoice(
                    label: 'Sans',
                    sample: 'Inter',
                    fontFamily: AppConstants.fontUi,
                    selected: !settings.serif,
                    onTap: () => context.read<AppViewModel>().setSerif(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Page turn animation.
            Text('Page turn', style: text.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final style in PageFlipStyle.values)
                  _FlipStyleChip(
                    style: style,
                    selected: settings.flipStyle == style,
                    onTap: () =>
                        context.read<AppViewModel>().setFlipStyle(style),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            // Page layout (portrait only).
            Text('Page layout', style: text.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FlipStyleChip(
                    style: null,
                    icon: Icons.article_outlined,
                    label: 'Single',
                    selected: settings.pageColumns == 1,
                    onTap: () =>
                        context.read<AppViewModel>().setPageColumns(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FlipStyleChip(
                    style: null,
                    icon: Icons.menu_book_outlined,
                    label: 'Dual',
                    selected: settings.pageColumns == 2,
                    onTap: () =>
                        context.read<AppViewModel>().setPageColumns(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Works in portrait and landscape',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _TypeChoice extends StatelessWidget {
  const _TypeChoice({
    required this.label,
    required this.sample,
    required this.fontFamily,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String sample;
  final String fontFamily;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? scheme.primary.withValues(alpha: 0.10) : null,
        ),
        child: Column(
          children: [
            Text(
              'Ag',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text('$label · $sample',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FlipStyleChip extends StatelessWidget {
  const _FlipStyleChip({
    this.style,
    this.icon,
    this.label,
    required this.selected,
    required this.onTap,
  });

  final PageFlipStyle? style;
  final IconData? icon;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayIcon = icon ?? style?.icon ?? Icons.help_outline;
    final displayLabel = label ?? style?.label ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? scheme.primary.withValues(alpha: 0.10) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(displayIcon, size: 18,
                color: selected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
