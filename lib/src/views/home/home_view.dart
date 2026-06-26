import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/i_book_repository.dart';
import '../../services/i_category_service.dart';
import '../../services/i_pdf_service.dart';
import '../../services/i_progress_service.dart';
import '../../viewmodels/library_viewmodel.dart';
import '../library/library_view.dart';
import '../settings/settings_view.dart';

/// The app shell: a bottom navigation bar switching between the Library and
/// Settings tabs. Each tab owns its ViewModel.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ChangeNotifierProvider<LibraryViewModel>(
            create: (ctx) => LibraryViewModel(
              books: ctx.read<IBookRepository>(),
              progress: ctx.read<IProgressService>(),
              categories: ctx.read<ICategoryService>(),
              pdf: ctx.read<IPdfService>(),
            ),
            child: const LibraryView(),
          ),
          const SettingsView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
