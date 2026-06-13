import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_monitor/main.dart';

void main() {
  testWidgets('Smart Home App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartHomeApp());

    // Verify that the app title is present.
    expect(find.textContaining('Smart Home Monitor'), findsOneWidget);
  });
}
