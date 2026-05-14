import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_alarm/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SleepAlarmApp());
    expect(find.byType(SleepAlarmApp), findsOneWidget);
  });
}
