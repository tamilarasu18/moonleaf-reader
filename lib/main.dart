import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/services/service_locator.dart';

/// Composition root: build the dependency graph once, then run the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await ServiceLocator.initialize();
  runApp(MoonleafApp(services: services));
}
