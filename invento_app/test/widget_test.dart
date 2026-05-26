import 'package:flutter_test/flutter_test.dart';
import 'package:invento_app/main.dart';
import 'package:invento_app/services/firebase_service.dart';

void main() {
  testWidgets('shows firebase setup guidance when config is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        initialization: Future.value(
          const FirebaseBootstrapResult.unconfigured(
            'Firebase setup is still missing.',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Zeppo'), findsOneWidget);
    expect(find.text('Firebase setup required'), findsOneWidget);
    expect(find.text('View data model'), findsOneWidget);
  });
}
