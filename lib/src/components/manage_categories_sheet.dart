import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/extensions.dart';
import '../viewmodels/library_viewmodel.dart';

/// Bottom sheet for creating, renaming, and deleting user categories.
void showManageCategoriesSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<LibraryViewModel>(),
      child: const _ManageCategoriesSheet(),
    ),
  );
}

class _ManageCategoriesSheet extends StatefulWidget {
  const _ManageCategoriesSheet();

  @override
  State<_ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends State<_ManageCategoriesSheet> {
  final _nameCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _create(LibraryViewModel vm) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await vm.createCategory(name);
    _nameCtrl.clear();
    _focusNode.requestFocus();
  }

  Future<void> _rename(LibraryViewModel vm, String id, String current) async {
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Collection name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.trim().isNotEmpty) {
      await vm.renameCategory(id, newName);
    }
  }

  Future<void> _delete(LibraryViewModel vm, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text(
          'Are you sure you want to delete "$name"? '
          'This won\'t delete any books.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await vm.deleteCategory(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LibraryViewModel>();
    final cats = vm.userCategories;

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
              Text('Your collections', style: context.text.titleLarge),
              const SizedBox(height: 16),

              // Existing categories.
              if (cats.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'No collections yet. Create one below!',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...cats.map((cat) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            context.colors.secondaryContainer,
                        child: Icon(
                          Icons.folder_outlined,
                          size: 18,
                          color: context.colors.onSecondaryContainer,
                        ),
                      ),
                      title: Text(cat.name),
                      subtitle: Text(
                        '${cat.bookIds.length} '
                        '${cat.bookIds.length == 1 ? 'book' : 'books'}',
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Rename',
                            onPressed: () => _rename(vm, cat.id, cat.name),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: context.colors.error,
                            ),
                            tooltip: 'Delete',
                            onPressed: () =>
                                _delete(vm, cat.id, cat.name),
                          ),
                        ],
                      ),
                    )),

              const Divider(),
              const SizedBox(height: 8),

              // Create new.
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      focusNode: _focusNode,
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
                      onSubmitted: (_) => _create(vm),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => _create(vm),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add'),
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
