import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('timer screen uses horizontal v4 zones as large touch targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));
    expect(leftZone, findsOneWidget);
    expect(rightZone, findsOneWidget);
    expect(tester.getSize(leftZone).width, greaterThan(300));
    expect(tester.getSize(rightZone).width, greaterThan(300));
    expect(tester.getSize(leftZone).height, greaterThan(320));
    expect(find.text('차례 넘기기'), findsNothing);
    expect(find.text('일시정지'), findsNothing);
    expect(find.text('종료'), findsNothing);
    expect(find.byKey(const ValueKey('pause-session-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('finish-session-button')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp('B.*말하는 중')), findsOneWidget);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('fullscreen clock fills the surface beyond safe area padding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    tester.view.padding = const FakeViewPadding(
      left: 34,
      top: 18,
      right: 26,
      bottom: 12,
    );
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetPadding();
    });

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    expect(tester.getTopLeft(leftZone).dy, 0);
    expect(tester.getSize(leftZone).height, closeTo(390, 1));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('active speaker remaining time pulls the boundary inward', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));
    final initialLeftWidth = tester.getSize(leftZone).width;
    final initialRightWidth = tester.getSize(rightZone).width;
    expect(initialLeftWidth, closeTo(initialRightWidth, 1));

    await tester.pump(const Duration(seconds: 30));

    expect(tester.getSize(leftZone).width, closeTo(250, 2));
    expect(tester.getSize(rightZone).width, closeTo(750, 2));
    expect(tester.getSize(leftZone).width, lessThan(initialLeftWidth));
    expect(tester.getSize(rightZone).width, greaterThan(initialRightWidth));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('clock boundary moves linearly throughout the current turn', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final initialLeftWidth = tester.getSize(leftZone).width;
    expect(initialLeftWidth, closeTo(500, 1));

    await tester.pump(const Duration(seconds: 15));
    final fifteenSecondLeftWidth = tester.getSize(leftZone).width;
    expect(fifteenSecondLeftWidth, closeTo(375, 2));

    await tester.pump(const Duration(seconds: 15));
    final thirtySecondLeftWidth = tester.getSize(leftZone).width;
    expect(thirtySecondLeftWidth, closeTo(250, 2));

    final firstTravelDistance = initialLeftWidth - fifteenSecondLeftWidth;
    final secondTravelDistance = fifteenSecondLeftWidth - thirtySecondLeftWidth;
    expect(firstTravelDistance, closeTo(secondTravelDistance, 2));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'clock boundary keeps real-time speed when animations are disabled',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.binding.setSurfaceSize(const Size(1000, 400));
      addTearDown(() async {
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        await tester.binding.setSurfaceSize(null);
      });

      await _pumpTimer(tester, _config());

      final leftZone = find.byKey(const ValueKey('clock-left-zone'));
      expect(tester.getSize(leftZone).width, closeTo(500, 1));

      await tester.pump(const Duration(seconds: 2));

      expect(tester.getSize(leftZone).width, closeTo(483.33, 2));

      await _finishThroughDialog(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('clock background moves while the readout stays anchored', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final leftReadout = find.bySemanticsLabel(RegExp('A.*말하는 중'));
    final initialZoneWidth = tester.getSize(leftZone).width;
    final initialReadoutWidth = tester.getSize(leftReadout).width;

    await tester.pump(const Duration(seconds: 1));

    final tickedZoneWidth = tester.getSize(leftZone).width;
    final tickedReadoutWidth = tester.getSize(leftReadout).width;
    expect(initialZoneWidth - tickedZoneWidth, greaterThan(7));
    expect(tickedReadoutWidth, closeTo(initialReadoutWidth, 1));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('next speaker continues from the current boundary position', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    final leftZone = find.byKey(const ValueKey('clock-left-zone'));

    await tester.pump(const Duration(seconds: 30));
    final beforePassWidth = tester.getSize(leftZone).width;
    expect(beforePassWidth, closeTo(250, 2));

    await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp('B.*말하는 중')), findsOneWidget);
    expect(tester.getSize(leftZone).width, closeTo(beforePassWidth, 0.5));

    await tester.pump(const Duration(seconds: 30));

    expect(tester.getSize(leftZone).width, closeTo(625, 2));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'sub-second turn pass preserves the displayed boundary position',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpTimer(tester, _config());

      final leftZone = find.byKey(const ValueKey('clock-left-zone'));

      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 350));
      final beforePassWidth = tester.getSize(leftZone).width;

      await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
      await tester.pump();

      expect(find.bySemanticsLabel(RegExp('B.*말하는 중')), findsOneWidget);
      expect(tester.getSize(leftZone).width, closeTo(beforePassWidth, 0.5));

      await _finishThroughDialog(tester);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('sub-second manual pass gives the new turn a full boundary run', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());
    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));

    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
    await tester.pump();

    await tester.pump(const Duration(seconds: 59));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('오버타임 +0:00'), findsOneWidget);
    expect(tester.getSize(leftZone).width, closeTo(1000, 2));
    expect(rightZone, findsNothing);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('short turn ticker starts after boundary rebuild', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config(bTotalSeconds: 1));
    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));

    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
    await tester.pump(const Duration(milliseconds: 16));

    await tester.pump(const Duration(milliseconds: 984));
    final bWasRunningBeforeExpiry =
        find.bySemanticsLabel(RegExp('B.*말하는 중')).evaluate().length == 1;
    final turnTimeWasVisibleBeforeExpiry =
        find.text('0:01').evaluate().length == 1;
    final pauseBeforeExpiry = tester.widget<CupertinoButton>(
      find.byKey(const ValueKey('pause-session-button')),
    );
    final totalHadEndedBeforeExpiry = pauseBeforeExpiry.onPressed == null;

    await tester.pump(const Duration(milliseconds: 16));

    final pauseAfterExpiry = tester.widget<CupertinoButton>(
      find.byKey(const ValueKey('pause-session-button')),
    );
    expect(pauseAfterExpiry.onPressed, isNull);
    expect(tester.getSize(leftZone).width, closeTo(1000, 2));
    expect(rightZone, findsNothing);
    expect(bWasRunningBeforeExpiry, isTrue);
    expect(turnTimeWasVisibleBeforeExpiry, isTrue);
    expect(totalHadEndedBeforeExpiry, isFalse);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('two rapid passes resync the returning speaker motion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());
    final leftZone = find.byKey(const ValueKey('clock-left-zone'));

    await tester.pump(const Duration(seconds: 10));
    final widthBeforePasses = tester.getSize(leftZone).width;
    expect(widthBeforePasses, closeTo(416.67, 2));

    final activeSpeaker = find.bySemanticsLabel(RegExp('A.*말하는 중'));
    await tester.tap(activeSpeaker);
    await tester.tap(activeSpeaker);
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp('A.*말하는 중')), findsOneWidget);
    expect(tester.getSize(leftZone).width, closeTo(widthBeforePasses, 0.5));

    await tester.pump(const Duration(seconds: 10));
    expect(tester.getSize(leftZone).width, closeTo(347.22, 2));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pause freezes the boundary and resumes using remaining time', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());
    final leftZone = find.byKey(const ValueKey('clock-left-zone'));

    await tester.pump(const Duration(seconds: 15));
    final widthBeforePause = tester.getSize(leftZone).width;
    expect(widthBeforePause, closeTo(375, 2));

    await tester.tap(find.byKey(const ValueKey('pause-session-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getSize(leftZone).width, closeTo(widthBeforePause, 0.5));

    await tester.tap(find.byKey(const ValueKey('resume-session-button')));
    await tester.pump();
    expect(tester.getSize(leftZone).width, closeTo(widthBeforePause, 0.5));

    await tester.pump(const Duration(seconds: 10));
    expect(tester.getSize(leftZone).width, closeTo(291.67, 2));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('auto switch reverses from the reached edge', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(
      tester,
      _config(
        overtimeConfig: const OvertimeConfig(
          enabled: false,
          behavior: TurnLimitBehavior.autoSwitch,
        ),
      ),
    );
    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));

    await tester.pump(const Duration(seconds: 60));
    expect(find.bySemanticsLabel(RegExp('B.*말하는 중')), findsOneWidget);
    expect(tester.getSize(rightZone).width, closeTo(1000, 2));

    await tester.pump(const Duration(seconds: 30));
    expect(tester.getSize(leftZone).width, closeTo(500, 2));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('surface resize preserves the boundary fraction', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());
    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    await tester.pump(const Duration(seconds: 30));
    final originalFraction = tester.getSize(leftZone).width / 1000;

    await tester.binding.setSurfaceSize(const Size(500, 400));
    await tester.pump();
    final resizedFraction = tester.getSize(leftZone).width / 500;

    expect(resizedFraction, closeTo(originalFraction, 0.002));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('repeated early passes reverse without position resets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());
    final leftZone = find.byKey(const ValueKey('clock-left-zone'));

    await tester.pump(const Duration(seconds: 12));
    final firstPassWidth = tester.getSize(leftZone).width;
    await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
    await tester.pump();
    expect(tester.getSize(leftZone).width, closeTo(firstPassWidth, 0.5));

    await tester.pump(const Duration(seconds: 12));
    final secondPassWidth = tester.getSize(leftZone).width;
    expect(secondPassWidth, greaterThan(firstPassWidth));
    await tester.tap(find.bySemanticsLabel(RegExp('B.*말하는 중')));
    await tester.pump();
    expect(tester.getSize(leftZone).width, closeTo(secondPassWidth, 0.5));

    await tester.pump(const Duration(seconds: 12));
    expect(tester.getSize(leftZone).width, lessThan(secondPassWidth));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('auto pause holds the boundary at the reached edge', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(
      tester,
      _config(
        overtimeConfig: const OvertimeConfig(
          enabled: false,
          behavior: TurnLimitBehavior.autoPause,
        ),
      ),
    );
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));

    await tester.pump(const Duration(seconds: 60));
    expect(tester.getSize(rightZone).width, closeTo(1000, 2));
    await tester.pump(const Duration(seconds: 10));
    expect(tester.getSize(rightZone).width, closeTo(1000, 2));

    final pauseButton = tester.widget<CupertinoButton>(
      find.byKey(const ValueKey('pause-session-button')),
    );
    expect(pauseButton.onPressed, isNull);
    expect(find.textContaining('오버타임'), findsNothing);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('overtime holds the boundary at the reached edge', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));

    await tester.pump(const Duration(seconds: 65));
    expect(find.text('오버타임 +0:05'), findsOneWidget);
    expect(tester.getSize(rightZone).width, closeTo(1000, 2));

    await tester.pump(const Duration(seconds: 5));
    expect(tester.getSize(rightZone).width, closeTo(1000, 2));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('new session resets the boundary to center', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());
    final leftZone = find.byKey(const ValueKey('clock-left-zone'));
    await tester.pump(const Duration(seconds: 30));
    expect(tester.getSize(leftZone).width, closeTo(250, 2));

    await _pumpTimer(tester, _config(aTotalSeconds: 301));
    expect(tester.getSize(leftZone).width, closeTo(500, 1));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('active speaker zone shrinks away when total time reaches zero', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config(aTotalSeconds: 1, bTotalSeconds: 300));

    expect(find.byKey(const ValueKey('clock-left-zone')), findsOneWidget);
    expect(find.byKey(const ValueKey('clock-right-zone')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('clock-left-zone')), findsNothing);
    final rightZone = find.byKey(const ValueKey('clock-right-zone'));
    expect(rightZone, findsOneWidget);
    expect(tester.getSize(rightZone).width, greaterThan(950));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('feedback banner overlays without moving the clock readout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    await tester.pump(const Duration(seconds: 49));
    await tester.pump(const Duration(milliseconds: 800));

    final nameFinder = find.text('A');
    final nameTopBeforeWarning = tester.getTopLeft(nameFinder).dy;
    expect(find.text('10초 남았습니다.'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('10초 남았습니다.'), findsOneWidget);
    expect(tester.getTopLeft(nameFinder).dy, closeTo(nameTopBeforeWarning, 1));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('clock readouts do not scale down with shrinking zones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpTimer(tester, _config());

    expect(
      find.descendant(
        of: find.byType(TimerHomePage),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 48));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('0:12'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TimerHomePage),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('turn danger flash starts at twenty percent and intensifies', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    await tester.pump(const Duration(seconds: 47));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('turn-danger-flash-overlay')),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final weakOpacity = _dangerFlashOpacity(tester);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    final strongOpacity = _dangerFlashOpacity(tester);

    expect(weakOpacity, greaterThan(0));
    expect(strongOpacity, greaterThan(weakOpacity));

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('turn danger flash can be disabled independently', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(alertConfig: const AlertConfig(turnDangerFlashEnabled: false)),
    );

    await tester.pump(const Duration(seconds: 54));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('turn-danger-flash-overlay')),
      findsNothing,
    );

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('timer keeps the display awake and landscape while active', (
    tester,
  ) async {
    final screenAwakeCalls = <MethodCall>[];
    final platformCalls = <MethodCall>[];
    const screenAwakeChannel = MethodChannel('calmturn/screen_awake');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      screenAwakeChannel,
      (call) async {
        screenAwakeCalls.add(call);
        return null;
      },
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        screenAwakeChannel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await _pumpTimer(tester, _config());

    expect(_enabledCalls(screenAwakeCalls, 'setSensorLandscape'), [true]);
    expect(_enabledCalls(screenAwakeCalls, 'setKeepScreenOn'), [true]);
    expect(_orientationArguments(platformCalls).first, [
      'DeviceOrientation.landscapeLeft',
    ]);
    expect(
      _systemUiModeArguments(platformCalls).first,
      'SystemUiMode.immersiveSticky',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(_enabledCalls(screenAwakeCalls, 'setSensorLandscape'), [
      true,
      false,
    ]);
    expect(_enabledCalls(screenAwakeCalls, 'setKeepScreenOn'), [true, false]);
    expect(_orientationArguments(platformCalls).last, isEmpty);
    expect(
      _systemUiModeArguments(platformCalls).last,
      'SystemUiMode.edgeToEdge',
    );
  });

  testWidgets('pause resumes in place and finish requires confirmation', (
    tester,
  ) async {
    await _pumpTimer(tester, _config());

    await tester.tap(find.byKey(const ValueKey('pause-session-button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('resume-session-button')), findsOneWidget);
    expect(find.text('잠깐 멈춤'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('resume-session-button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('pause-session-button')), findsOneWidget);

    await _openFinishDialog(tester);
    await _tapText(tester, '취소', settle: false);
    expect(find.text('종료할까요?'), findsNothing);

    await _finishThroughDialog(tester);
    expect(find.text('대화를 마쳤어요.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('penalty marks stay hidden while overtime remains visible', (
    tester,
  ) async {
    await _pumpTimer(
      tester,
      _config(penaltyConfig: const PenaltyConfig(thresholdSeconds: 5)),
    );

    await tester.pump(const Duration(seconds: 65));
    await tester.pump();

    expect(find.text('오버타임 +0:05'), findsOneWidget);
    expect(find.textContaining('주의 표시'), findsNothing);
    expect(find.textContaining('패널티'), findsNothing);
    expect(tester.takeException(), isNull);

    await _finishThroughDialog(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pumpTimer(WidgetTester tester, SessionConfig config) async {
  await tester.pumpWidget(
    CupertinoApp(
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF111111),
        scaffoldBackgroundColor: Color(0xFFF7F7F4),
      ),
      home: TimerHomePage(config: config),
    ),
  );
  await tester.pump();
}

Future<void> _openFinishDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('finish-session-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('종료할까요?'), findsOneWidget);
}

Future<void> _finishThroughDialog(WidgetTester tester) async {
  await _openFinishDialog(tester);
  await _tapText(tester, '종료', settle: false);
  expect(find.byKey(const ValueKey('finish-session-button')), findsNothing);
}

Future<void> _tapText(
  WidgetTester tester,
  String text, {
  bool settle = true,
}) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var elapsedMilliseconds = 0; elapsedMilliseconds < 600;) {
      await tester.pump(const Duration(milliseconds: 100));
      elapsedMilliseconds += 100;
    }
  }
}

List<List<Object?>> _orientationArguments(List<MethodCall> calls) {
  return calls
      .where((call) => call.method == 'SystemChrome.setPreferredOrientations')
      .map((call) => List<Object?>.from(call.arguments as List))
      .toList(growable: false);
}

List<Object?> _systemUiModeArguments(List<MethodCall> calls) {
  return calls
      .where((call) => call.method == 'SystemChrome.setEnabledSystemUIMode')
      .map((call) => call.arguments)
      .toList(growable: false);
}

List<bool> _enabledCalls(List<MethodCall> calls, String method) {
  return calls
      .where((call) => call.method == method)
      .map((call) {
        final arguments = Map<Object?, Object?>.from(call.arguments as Map);
        return arguments['enabled']! as bool;
      })
      .toList(growable: false);
}

double _dangerFlashOpacity(WidgetTester tester) {
  final overlay = tester.widget<Opacity>(
    find.byKey(const ValueKey('turn-danger-flash-overlay')),
  );
  return overlay.opacity;
}

SessionConfig _config({
  int aTotalSeconds = 300,
  int bTotalSeconds = 300,
  OvertimeConfig overtimeConfig = const OvertimeConfig(),
  PenaltyConfig penaltyConfig = const PenaltyConfig(),
  AlertConfig alertConfig = const AlertConfig(),
}) {
  return SessionConfig(
    participantA: ParticipantConfig(
      id: 'a',
      name: 'A',
      totalAllocatedSeconds: aTotalSeconds,
    ),
    participantB: ParticipantConfig(
      id: 'b',
      name: 'B',
      totalAllocatedSeconds: bTotalSeconds,
    ),
    turnLimitSeconds: 60,
    firstSpeakerId: 'a',
    overtimeConfig: overtimeConfig,
    penaltyConfig: penaltyConfig,
    alertConfig: alertConfig,
  );
}
