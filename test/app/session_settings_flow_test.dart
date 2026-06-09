import 'package:calmturn/features/settings/app_settings.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('setup uses fair shared time controls and entry buttons', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    expect(find.text('시계'), findsOneWidget);
    expect(_textFieldValue(tester, 0), '');
    expect(_textFieldValue(tester, 1), '');
    expect(find.text('흰칸'), findsOneWidget);
    expect(find.text('검은칸'), findsOneWidget);
    expect(find.text('10분'), findsOneWidget);
    expect(find.text('20분'), findsOneWidget);
    expect(find.text('30분'), findsOneWidget);
    expect(find.text('60분'), findsOneWidget);
    expect(find.text('1분'), findsOneWidget);
    expect(find.text('2분'), findsOneWidget);
    expect(find.text('3분'), findsOneWidget);
    expect(find.text('5분'), findsOneWidget);
    expect(find.text('각자 다르게'), findsNothing);
    expect(find.text('A 10분'), findsNothing);
    expect(find.byKey(const ValueKey('history-button')), findsOneWidget);
    expect(find.text('오버타임'), findsNothing);
    expect(
      find.byKey(const ValueKey('advanced-settings-button')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('v4 setup starts the timer without a consent gate', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await _tapText(tester, '20분');
    await _tapText(tester, '5분');
    await _tapText(tester, '시작');

    expect(find.text('두 사람이 같은 규칙을 보고 시작해요'), findsNothing);
    expect(find.byKey(const ValueKey('clock-left-zone')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('흰칸.*말하는 중')), findsOneWidget);
    expect(find.text('20:00'), findsWidgets);
    expect(find.text('5:00'), findsOneWidget);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('first speaker selection uses the configured names', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(CupertinoTextField).at(0), '민준');
    await tester.enterText(find.byType(CupertinoTextField).at(1), '서연');
    await _tapText(tester, '서연');
    await _tapText(tester, '시작');

    expect(find.bySemanticsLabel(RegExp('서연.*말하는 중')), findsOneWidget);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'advanced settings keep overtime controls out of the simple setup',
    (tester) async {
      final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

      await tester.pumpWidget(CalmTurnApp(settingsStore: store));
      await tester.pump();
      await tester.pump();

      expect(find.text('오버타임'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('advanced-settings-button')));
      await tester.pumpAndSettle();

      expect(find.text('고급설정'), findsWidgets);
      expect(find.text('오버타임'), findsWidgets);
      expect(find.text('주의 표시 1분'), findsOneWidget);
    },
  );

  testWidgets(
    'advanced settings save the independent turn danger flash toggle',
    (tester) async {
      final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

      await tester.pumpWidget(CalmTurnApp(settingsStore: store));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('advanced-settings-button')));
      await tester.pumpAndSettle();

      await _tapText(tester, '턴 위기 점멸');
      await _tapText(tester, '시계로');

      final loaded = await store.loadSettings();
      expect(loaded.sessionDefaults.turnDangerFlashEnabled, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Future<void> _finishThroughDialog(WidgetTester tester) async {
  await _showControls(tester);
  await tester.tap(find.byKey(const ValueKey('finish-session-button')));
  await tester.pumpAndSettle();
  expect(find.text('종료할까요?'), findsOneWidget);
  await _tapText(tester, '종료');
}

Future<void> _showControls(WidgetTester tester) async {
  if (find
      .byKey(const ValueKey('finish-session-button'))
      .evaluate()
      .isNotEmpty) {
    return;
  }
  await tester.tap(find.byKey(const ValueKey('clock-controls-reveal-zone')));
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final textFinder = find.text(text);
  if (textFinder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      textFinder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final finder = textFinder.last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _textFieldValue(WidgetTester tester, int index) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: find.byType(CupertinoTextField).at(index),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}
