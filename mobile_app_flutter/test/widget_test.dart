import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_ai_app/main.dart';

void main() {
  testWidgets('BusSense AI App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BusSenseAIApp());
    expect(find.byType(BusSenseAIApp), findsOneWidget);
  });
}
