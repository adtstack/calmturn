import 'package:calmturn/features/settings/app_settings.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('turn limit longer than total time shows validation message', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await _tapText(tester, '각자 3분');
    await _tapText(tester, '턴 5분');
    await _tapText(tester, '규칙 확인');

    expect(find.text('턴 제한은 전체 시간보다 길 수 없어요.'), findsOneWidget);
    expect(find.text('두 사람이 같은 규칙을 보고 시작해요'), findsNothing);

    await _tapText(tester, '각자 10분');
    await _tapText(tester, '규칙 확인');

    expect(find.text('두 사람이 같은 규칙을 보고 시작해요'), findsOneWidget);
    expect(find.text('턴 제한은 전체 시간보다 길 수 없어요.'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('minute presets support 30 minute totals and long turns', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(CupertinoTextField).at(0), 'A');
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'B');
    await _tapText(tester, '각자 30분');
    await _tapText(tester, '턴 5분');
    await _tapText(tester, '규칙 확인');

    expect(find.text('A 전체 시간: 30:00'), findsOneWidget);
    expect(find.text('B 전체 시간: 30:00'), findsOneWidget);
    expect(find.text('턴 제한: 5:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('custom minute inputs apply minutes and keep only digits', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(CupertinoTextField).at(0), 'A');
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'B');

    await tester.enterText(
      find.byKey(const ValueKey('shared-total-minutes-field')),
      '25abc',
    );
    await tester.enterText(
      find.byKey(const ValueKey('turn-limit-minutes-field')),
      '8분',
    );

    expect(
      _editableTextValue(tester, 'shared-total-minutes-field'),
      equals('25'),
    );
    expect(_editableTextValue(tester, 'turn-limit-minutes-field'), equals('8'));
    expect(
      _fieldInsideOption(tester, 'shared-total-minutes-option'),
      findsOneWidget,
    );
    expect(
      _fieldInsideOption(tester, 'turn-limit-minutes-option'),
      findsOneWidget,
    );

    await _tapText(tester, '규칙 확인');

    expect(find.text('A 전체 시간: 25:00'), findsOneWidget);
    expect(find.text('B 전체 시간: 25:00'), findsOneWidget);
    expect(find.text('턴 제한: 8:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('custom minute inputs reject impossible ranges', (tester) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('shared-total-minutes-field')),
      '241',
    );
    await tester.pump();
    await _ensureTextVisible(tester, '전체 시간은 1분부터 240분까지 입력할 수 있어요.');

    expect(find.text('전체 시간은 1분부터 240분까지 입력할 수 있어요.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('turn-limit-minutes-field')),
      '61',
    );
    await tester.pump();
    await _ensureTextVisible(tester, '턴 제한은 1분부터 60분까지 입력할 수 있어요.');

    expect(find.text('턴 제한은 1분부터 60분까지 입력할 수 있어요.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unreachable penalty threshold shows validation message', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await _tapText(tester, '각자 3분');
    await _tapText(tester, '고급 설정');
    await _tapText(tester, '주의 표시 3분');
    await _tapText(tester, '규칙 확인');

    expect(find.text('주의 표시 기준은 가능한 오버타임보다 길 수 없어요.'), findsOneWidget);
    expect(find.text('두 사람이 같은 규칙을 보고 시작해요'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('alert targets require at least one delivery method', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await _tapText(tester, '고급 설정');
    await _tapText(tester, '화면');
    await _tapText(tester, '진동');
    await _tapText(tester, '규칙 확인');

    expect(find.text('알림 방식이 모두 꺼져 있어요.'), findsOneWidget);
    expect(find.text('두 사람이 같은 규칙을 보고 시작해요'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('alert delivery methods require at least one target', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await _tapText(tester, '고급 설정');
    await _tapText(tester, '턴 시간');
    await _tapText(tester, '전체 시간');
    await _tapText(tester, '오버타임 시작');
    await _tapText(tester, '주의 표시');
    await _tapText(tester, '규칙 확인');

    expect(find.text('알림 대상이 모두 꺼져 있어요.'), findsOneWidget);
    expect(find.text('두 사람이 같은 규칙을 보고 시작해요'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('overtime only controls are hidden when overtime is off', (
    tester,
  ) async {
    final store = JsonAppSettingsStore(storage: InMemoryAppSettingsStorage());

    await tester.pumpWidget(CalmTurnApp(settingsStore: store));
    await tester.pump();
    await tester.pump();

    await _tapText(tester, '고급 설정');
    await _ensureTextVisible(tester, '오버타임 표시');
    expect(find.text('오버타임 표시'), findsOneWidget);
    await _ensureTextVisible(tester, '주의 표시 30초');
    expect(find.text('주의 표시 30초'), findsOneWidget);

    await _tapText(tester, '오버타임');

    expect(find.text('오버타임 표시'), findsNothing);
    expect(find.text('주의 표시 30초'), findsNothing);
    expect(find.text('오버타임 시작'), findsNothing);
    expect(find.text('주의 표시'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

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

Future<void> _ensureTextVisible(WidgetTester tester, String text) async {
  final textFinder = find.text(text);
  if (textFinder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      textFinder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(textFinder.last);
  await tester.pumpAndSettle();
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

String _editableTextValue(WidgetTester tester, String key) {
  final editable = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).controller.text;
}

Finder _fieldInsideOption(WidgetTester tester, String key) {
  return find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(CupertinoTextField),
  );
}
