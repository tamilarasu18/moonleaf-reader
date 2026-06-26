import 'package:flutter/material.dart';

import '../models/user_category.dart';
import '../utils/extensions.dart';

/// Bottom sheet for adding/removing a book from user categories.
/// Shows checkboxes for all existing categories and a "create new" row.
void showAddToCategorySheet({
  required BuildContext context,
  required String bookId,
  required List<UserCategory> allCategories,
  required List<UserCategory> memberCategories,
  required Future<void> Function(String categoryId) onAdd,
  required Future<void> Function(String categoryId) onRemove,
  required Future<void> Function(String name) onCreate,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddToCategorySheet(
      bookId: bookId,
      allCategories: allCategories,
      memberCategories: memberCategories,
      onAdd: onAdd,
      onRemove: onRemove,
      onCreate: onCreate,
    ),
  );
}

class _AddToCategorySheet extends StatefulWidget {
  const _AddToCategorySheet({
    required this.bookId,
    required this.allCategories,
    required this.memberCategories,
    required this.onAdd,
    required this.onRemove,
    required this.onCreate,
  });

  final String bookId;
  final List<UserCategory> allCategories;
  final List<UserCategory> memberCategories;
  final Future<void> Function(String categoryId) onAdd;
  final Future<void> Function(String categoryId) onRemove;
  final Future<void> Function(String name) onCreate;

  @override
  State<_AddToCategorySheet> createState() => _AddToCategorySheetState();
}

class _AddToCategorySheetState extends State<_AddToCategorySheet> {
  late final Set<String> _checked;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checked = widget.memberCategories.map((c) => c.id).toSet();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle(String categoryId, bool value) async {
    setState(() {
      if (value) {
        _checked.add(categoryId);
      } else {
        _checked.remove(categoryId);
      }
    });
    if (value) {
      await widget.onAdd(categoryId);
    } else {
      await widget.onRemove(categoryId);
    }
  }

  Future<void> _createAndAdd() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await widget.onCreate(name);
    _nameCtrl.clear();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    color: context.colors.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add to collection', style: context.text.titleLarge),
              const SizedBox(height: 12),

              if (widget.allCategories.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No collections yet. Create one below!',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...widget.allCategories.map((cat) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(cat.name),
                      subtitle: Text(
                        '${cat.bookIds.length} '
                        '${cat.bookIds.length == 1 ? 'book' : 'books'}',
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      value: _checked.contains(cat.id),
                      onChanged: (v) => _toggle(cat.id, v ?? false),
                    )),

              const Divider(),
              const SizedBox(height: 8),

              // Create new inline.
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'New collection name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _createAndAdd(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _createAndAdd,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
