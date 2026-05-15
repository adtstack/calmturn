import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('custom rules are confirmed before the timer starts', (
    tester,
  ) async {
    await tester.pumpWidget(const CalmTurnApp());

    await tester.enterText(find.byType(CupertinoTextField).at(0), 'A');
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'B');
    await _tapText(tester, 'Different');
    await _tapText(tester, 'A 3 min');
    await _tapText(tester, 'B 7 min');
    await _tapText(tester, 'Overtime 30 sec');
    await _tapText(tester, 'Sound');
    await _tapText(tester, 'Review rules');

    expect(find.text('서로 동의한 시간 배분'), findsOneWidget);
    expect(find.text('A total: 3:00'), findsOneWidget);
    expect(find.text('B total: 7:00'), findsOneWidget);
    expect(find.text('Overtime mark: 0:30'), findsOneWidget);
    expect(find.text('Alerts: Screen + Sound + Vibration'), findsOneWidget);

    var startButton = await _startButton(tester);
    expect(startButton.onPressed, isNull);

    await _tapText(tester, 'A agrees');
    await _tapText(tester, 'B agrees');
    startButton = await _startButton(tester);
    expect(startButton.onPressed, isNotNull);

    await _tapText(tester, 'Start Timer');

    expect(find.text('A'), findsWidgets);
    expect(find.text('B'), findsWidgets);
    expect(find.text('3:00'), findsWidgets);
    expect(find.text('7:00'), findsWidgets);
  });
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<CupertinoButton> _startButton(WidgetTester tester) async {
  final finder = find.byKey(const ValueKey('start-timer-button'));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 240);
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
  return tester.widget<CupertinoButton>(finder);
}
