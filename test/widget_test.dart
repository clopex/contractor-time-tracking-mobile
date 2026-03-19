import 'package:contractor_mobile/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders configuration helper when dart defines are missing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ContractorApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Missing app configuration'), findsOneWidget);
    expect(find.textContaining('--dart-define-from-file=.env'), findsOneWidget);
  });
}
