// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:plantcare/main.dart';

void main() {
  testWidgets('PlantCare app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlantCareApp());

    // Verify that the app starts (Firebase initialization may fail in test)
    expect(find.byType(PlantCareApp), findsOneWidget);
  });
}
