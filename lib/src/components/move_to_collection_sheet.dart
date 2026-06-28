import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_category.dart';
import '../services/i_category_service.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';

/// A Moonleaf-themed bottom sheet for moving a PDF to a different collection.
/// Returns the selected collection name, or `null` if cancelled.
Future<String?> showMoveToCollectionSheet(
  BuildContext context, {
  required String currentCategory,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MoveToCollectionSheet(
      currentCategory: currentCategory,
      categoryService: context.read<ICategoryService>(),
    ),
  );
}

class _MoveToCollectionSheet extends StatefulWidget {
  const _MoveToCollectionSheet({
    required this.currentCategory,
    required this.categoryService,
  });

  final String currentCategory;
  final ICategoryService categoryService;

  @override
  State<_MoveToCollectionSheet> createState() => _MoveToCollectionSheetState();
}

class _MoveToCollectionSheetState extends State<_MoveToCollectionSheet> {
  final _nameCtrl = TextEditingController();
  String? _selectedName;
  bool _showNewField = false;
  late List<UserCategory> _cats;

  @override
  void initState() {
    super.initState();
    _cats = widget.categoryService.getAll();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAndSelect() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await widget.categoryService.create(name);
    setState(() {
      _cats = widget.categoryService.getAll();
      _selectedName = name;
      _showNewField = false;
      _nameCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cats = _cats;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.colors;

    final surfaceColor = isDark ? const Color(0xFF1A1A32) : scheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title ──
                Row(
                  children: [
                    Icon(
                      Icons.drive_file_move_rounded,
                      color: isDark ? AppColors.gold : scheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Move to collection',
                      style: TextStyle(
                        fontFamily: AppConstants.fontReading,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: context.text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'Currently in '),
                      TextSpan(
                        text: widget.currentCategory,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.gold : scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Collection list ──
                ...cats
                    .where((c) => c.name != widget.currentCategory)
                    .map((cat) => _CollectionTile(
                          name: cat.name,
                          bookCount: cat.bookIds.length,
                          isSelected: _selectedName == cat.name,
                          onTap: () => setState(() {
                            _selectedName =
                                _selectedName == cat.name ? null : cat.name;
                          }),
                        )),

                // "Imported" option (go back to default).
                if (widget.currentCategory != 'Imported')
                  _CollectionTile(
                    name: 'Imported',
                    bookCount: null,
                    isSelected: _selectedName == 'Imported',
                    onTap: () => setState(() {
                      _selectedName =
                          _selectedName == 'Imported' ? null : 'Imported';
                    }),
                  ),

                const SizedBox(height: 8),

                // ── New collection ──
                if (_showNewField)
                  _NewCollectionField(
                    controller: _nameCtrl,
                    onSubmit: () => _createAndSelect(),
                    onCancel: () => setState(() {
                      _showNewField = false;
                      _nameCtrl.clear();
                    }),
                  )
                else
                  _CreateButton(
                    onTap: () => setState(() => _showNewField = true),
                  ),

                const SizedBox(height: 24),

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: AppConstants.fontUi,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _MoveButton(
                        enabled: _selectedName != null,
                        onTap: _selectedName != null
                            ? () => Navigator.pop(context, _selectedName)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.name,
    required this.bookCount,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final int? bookCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSelected
                  ? (isDark
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : scheme.primary.withValues(alpha: 0.08))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : scheme.surfaceContainerHighest
                          .withValues(alpha: 0.5)),
              border: Border.all(
                color: isSelected
                    ? (isDark
                        ? AppColors.gold.withValues(alpha: 0.5)
                        : scheme.primary.withValues(alpha: 0.4))
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppColors.gold.withValues(alpha: 0.2)
                            : scheme.primary.withValues(alpha: 0.12))
                        : scheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.folder_rounded
                        : Icons.folder_outlined,
                    size: 18,
                    color: isSelected
                        ? (isDark ? AppColors.gold : scheme.primary)
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: AppConstants.fontUi,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (bookCount != null)
                  Text(
                    '$bookCount ${bookCount == 1 ? 'book' : 'books'}',
                    style: TextStyle(
                      fontFamily: AppConstants.fontUi,
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                    color: isDark ? AppColors.gold : scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.gold.withValues(alpha: 0.1)
                      : scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: isDark ? AppColors.gold : scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'New collection',
                style: TextStyle(
                  fontFamily: AppConstants.fontUi,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: isDark ? AppColors.gold : scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewCollectionField extends StatelessWidget {
  const _NewCollectionField({
    required this.controller,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.gold.withValues(alpha: 0.25)
              : scheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontFamily: AppConstants.fontUi,
              fontSize: 15,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Collection name',
              hintStyle: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontFamily: AppConstants.fontUi,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? AppColors.gold : scheme.primary,
                  foregroundColor: isDark ? AppColors.night : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF3A3A6A), const Color(0xFF1E1E3F)]
                      : [scheme.primary, scheme.primary.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: isDark
                        ? AppColors.gold.withValues(alpha: 0.12)
                        : scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.drive_file_move_rounded,
              size: 18,
              color: enabled
                  ? (isDark ? AppColors.gold : Colors.white)
                  : scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Move',
              style: TextStyle(
                fontFamily: AppConstants.fontUi,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: enabled
                    ? (isDark ? AppColors.cream : Colors.white)
                    : scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
