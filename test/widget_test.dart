import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moonleaf/src/app.dart';
import 'package:moonleaf/src/services/service_locator.dart';

void main() {
  testWidgets('Moonleaf boots through the splash to the library',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final services = await ServiceLocator.initialize();

    await tester.pumpWidget(MoonleafApp(services: services));
    await tester.pump(); // first frame: splash

    // Brand wordmark is shown on the splash.
    expect(find.text('Moonleaf'), findsOneWidget);

    // Let the splash timer fire and the entrance animations play.
    // Use pump() instead of pumpAndSettle() because the library has an
    // infinite floating-logo animation that never settles.
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 2000));

    // Library has loaded — check for the book count text.
    expect(find.textContaining('books in your library'), findsOneWidget);
  });
}
