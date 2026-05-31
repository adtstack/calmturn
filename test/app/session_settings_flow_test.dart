import 'package:calmturn/features/settings/app_settings.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('custom rules are confirmed before the timer starts', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(CupertinoTextField).at(0), 'A');
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'B');
    expect(find.text('오버타임'), findsNothing);
    await _tapText(tester, '고급 설정');
    await _tapText(tester, '각자 다르게');
    await _tapText(tester, 'A 3분');
    await _tapText(tester, 'B 7분');
    await _tapText(tester, '주의 표시 30초');
    await _tapText(tester, '소리');
    await _tapText(tester, '규칙 확인');

    expect(find.text('두 사람이 같은 규칙을 보고 시작해요'), findsOneWidget);
    expect(find.text('A 전체 시간: 3:00'), findsOneWidget);
    expect(find.text('B 전체 시간: 7:00'), findsOneWidget);
    expect(find.text('주의 표시 기준: 0:30'), findsOneWidget);
    expect(find.text('알림: 화면 + 소리 + 진동'), findsOneWidget);

    var startButton = await _startButton(tester);
    expect(startButton.onPressed, isNull);

    await _tapText(tester, 'A 동의');
    await _tapText(tester, 'B 동의');
    startButton = await _startButton(tester);
    expect(startButton.onPressed, isNotNull);

    await _tapText(tester, '타이머 시작', settle: false);
    await tester.pump();

    expect(find.text('A님 차례'), findsOneWidget);
    expect(find.text('3:00'), findsWidgets);
    expect(find.text('B님은 듣는 중'), findsOneWidget);
    expect(find.text('7:00'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _tapText(
  WidgetTester tester,
  String text, {
  bool settle = true,
}) async {
  final textFinder = find.text(text);
  if (textFinder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      textFinder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final finder = textFinder.last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
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
