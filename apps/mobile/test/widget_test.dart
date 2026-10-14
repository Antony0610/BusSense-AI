import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_mobile/app/app.dart';
import 'package:bussense_mobile/core/storage/secure_token_storage.dart';
import 'package:bussense_mobile/features/auth/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('BusSenseApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        ],
        child: const BusSenseApp(),
      ),
    );
    expect(find.byType(BusSenseApp), findsOneWidget);
  });
}
