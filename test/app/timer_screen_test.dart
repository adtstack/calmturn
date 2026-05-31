import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('timer screen starts ready for a live conversation', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    expect(find.text('Now speaking'), findsOneWidget);
    expect(find.text('A is speaking'), findsOneWidget);
    expect(find.text('Turn remaining'), findsOneWidget);
    expect(find.text('Total remaining'), findsWidgets);
    expect(find.text('Pass turn'), findsOneWidget);
    expect(find.text('Take break'), findsOneWidget);
    expect(find.text('End session'), findsOneWidget);

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pass turn, break, resume, and end controls update the session', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    await _tapText(tester, 'Pass turn');
    expect(find.text('B is speaking'), findsOneWidget);

    await _tapText(tester, 'Take break');
    expect(find.text('Taking a break'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('5:00'), findsWidgets);

    await _tapText(tester, 'Resume');
    expect(find.text('B is speaking'), findsOneWidget);

    await _tapText(tester, 'End session');
    expect(find.text('Session finished'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('face timer uses mirrored zones as large touch targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final topZone = find.byKey(const ValueKey('face-timer-top-zone'));
    final bottomZone = find.byKey(const ValueKey('face-timer-bottom-zone'));
    expect(topZone, findsOneWidget);
    expect(bottomZone, findsOneWidget);
    expect(tester.getSize(topZone).height, greaterThan(300));
    expect(tester.getSize(bottomZone).height, greaterThan(300));

    final topRotation = tester.widget<Transform>(
      find.byKey(const ValueKey('face-timer-top-rotation')),
    );
    expect(topRotation.transform.storage[0], closeTo(-1, 0.001));
    expect(topRotation.transform.storage[5], closeTo(-1, 0.001));

    await tester.tap(find.text('A is speaking'));
    await tester.pump();

    expect(find.text('B is speaking'), findsOneWidget);

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('center controls keep labels readable on colored buttons', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    expect(
      tester.widget<Text>(find.text('Pass turn')).style?.color,
      CupertinoColors.white,
    );
    expect(
      tester.widget<Text>(find.text('Take break')).style?.color,
      CupertinoColors.white,
    );
    expect(
      tester.widget<Text>(find.text('End session')).style?.color,
      CupertinoColors.white,
    );

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('warning feedback uses visual alerts and screen fallback', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(
        alertConfig: const AlertConfig(
          warningBeforeSeconds: 10,
          visualEnabled: true,
          soundEnabled: false,
          hapticEnabled: false,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 50));
    await tester.pump();

    expect(find.text('10 seconds left in this turn.'), findsOneWidget);

    await _tapText(tester, 'End session');
    await _pumpTimer(
      tester,
      _config(
        alertConfig: const AlertConfig(
          warningBeforeSeconds: 10,
          visualEnabled: false,
          soundEnabled: true,
          hapticEnabled: false,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 50));
    await tester.pump();

    expect(find.text('10 seconds left in this turn.'), findsOneWidget);

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('visible overtime shows counters and penalty marks', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(penaltyConfig: const PenaltyConfig(thresholdSeconds: 5)),
    );

    await tester.pump(const Duration(seconds: 65));
    await tester.pump();

    expect(find.text('+0:05'), findsOneWidget);
    expect(find.text('Overtime +0:05'), findsOneWidget);
    expect(find.text('Overtime total'), findsWidgets);
    expect(find.textContaining('Mark 1 recorded.'), findsOneWidget);

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hidden overtime setting suppresses explicit overtime counters', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(
        overtimeConfig: const OvertimeConfig(showOvertime: false),
        penaltyConfig: const PenaltyConfig(thresholdSeconds: 5),
      ),
    );

    await tester.pump(const Duration(seconds: 65));
    await tester.pump();

    expect(find.text('Time is up'), findsOneWidget);
    expect(find.text('+0:05'), findsNothing);
    expect(find.text('Overtime +0:05'), findsNothing);
    expect(find.text('Overtime total'), findsNothing);
    expect(find.textContaining('Overtime'), findsNothing);

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('auto pause directs the user to pass turn instead of resume', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(
        overtimeConfig: const OvertimeConfig(
          enabled: false,
          showOvertime: false,
          behavior: TurnLimitBehavior.autoPause,
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 60));
    await tester.pump();

    expect(find.text('Turn limit reached'), findsOneWidget);
    expect(find.text('Pass turn to continue.'), findsOneWidget);
    expect(find.text('Turn ended'), findsOneWidget);
    expect(find.text('Resume'), findsNothing);

    await _tapText(tester, 'Pass turn');
    expect(find.text('B is speaking'), findsOneWidget);

    await _tapText(tester, 'End session');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pumpTimer(WidgetTester tester, SessionConfig config) async {
  await tester.pumpWidget(
    CupertinoApp(
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF2D6A64),
        scaffoldBackgroundColor: Color(0xFFF6F4EF),
      ),
      home: TimerHomePage(config: config),
    ),
  );
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 180);
    await tester.pump();
  }
  await tester.tap(finder);
  await tester.pump();
}

SessionConfig _config({
  AlertConfig alertConfig = const AlertConfig(),
  OvertimeConfig overtimeConfig = const OvertimeConfig(),
  PenaltyConfig penaltyConfig = const PenaltyConfig(),
}) {
  return SessionConfig(
    participantA: const ParticipantConfig(
      id: 'a',
      name: 'A',
      totalAllocatedSeconds: 300,
    ),
    participantB: const ParticipantConfig(
      id: 'b',
      name: 'B',
      totalAllocatedSeconds: 300,
    ),
    turnLimitSeconds: 60,
    firstSpeakerId: 'a',
    overtimeConfig: overtimeConfig,
    penaltyConfig: penaltyConfig,
    alertConfig: alertConfig,
  );
}
