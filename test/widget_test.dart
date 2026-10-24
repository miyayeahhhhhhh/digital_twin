import 'package:flutter_test/flutter_test.dart';
import 'package:heart_twin/main.dart';

void main() {
  testWidgets('HEART//TWIN app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const HeartTwinApp());

    expect(find.textContaining('HEART'), findsWidgets);
  });
}
