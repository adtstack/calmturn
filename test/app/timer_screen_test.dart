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

SessionConfig _config({AlertConfig alertConfig = const AlertConfig()}) {
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
    overtimeConfig: const OvertimeConfig(),
    penaltyConfig: const PenaltyConfig(),
    alertConfig: alertConfig,
  );
}
