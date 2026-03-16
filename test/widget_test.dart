import 'package:contractor_mobile/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders contractor home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ContractorApp());

    expect(find.text('Good morning, Amar'), findsOneWidget);
    expect(find.text('Start timer'), findsOneWidget);
  });
}
