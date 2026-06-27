import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/i_book_repository.dart';
import 'services/i_category_service.dart';
import 'services/i_highlight_service.dart';
import 'services/i_pdf_service.dart';
import 'services/i_preferences_service.dart';
import 'services/i_progress_service.dart';
import 'services/service_locator.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'viewmodels/app_viewmodel.dart';
import 'views/splash/splash_view.dart';

/// Root widget. Exposes the (abstract) services and the global [AppViewModel]
/// to the whole tree via `provider`, and binds the theme to the view model.
class MoonleafApp extends StatelessWidget {
  const MoonleafApp({super.key, required this.services});

  final ServiceLocator services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<IPreferencesService>.value(value: services.preferences),
        Provider<IBookRepository>.value(value: services.books),
        Provider<IProgressService>.value(value: services.progress),
        Provider<ICategoryService>.value(value: services.categories),
        Provider<IPdfService>.value(value: services.pdf),
        Provider<IHighlightService>.value(value: services.highlights),
        ChangeNotifierProvider<AppViewModel>(
          create: (_) => AppViewModel(services.preferences),
        ),
      ],
      child: Consumer<AppViewModel>(
        builder: (context, app, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: app.themeMode,
          home: const SplashView(),
        ),
      ),
    );
  }
}
