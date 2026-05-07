import 'package:flutter_test/flutter_test.dart';
import 'package:autofix_ai_simulator/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoFixSimulatorApp());
    expect(find.text('AutoFix AI'), findsOneWidget);
  });
}
