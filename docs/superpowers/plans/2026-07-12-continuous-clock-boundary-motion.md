# Continuous Clock Boundary Motion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 턴 전환 시 중앙으로 순간 이동하지 않고 현재 화면 위치부터 새 발언자의 영역 비율에 맞춰 연속 이동하는 시계 경계를 구현한다.

**Architecture:** 타이머 도메인 엔진은 그대로 두고 `_ClockZoneLayout`만 `AnimationController`를 소유하는 상태 위젯으로 바꾼다. 경계는 세션 시작에만 50%로 초기화하며, 턴 전환·재개 시 컨트롤러의 실제 현재값부터 새 목표 끝점까지 남은 턴 시간 동안 선형 이동한다.

**Tech Stack:** Flutter, Dart, `AnimationController`, `AnimatedBuilder`, `flutter_test`

---

**Design reference:** `docs/superpowers/specs/2026-07-12-continuous-clock-boundary-motion-design.md`

## File map

- Modify: `lib/main.dart` — 세션 단위 경계 상태와 연속 경계 애니메이션 생명주기
- Modify: `test/app/timer_screen_test.dart` — 선형 이동, 수동·자동 전환, 일시정지, 크기 변경 회귀 테스트와 장시간 애니메이션용 다이얼로그 헬퍼
- Modify: `test/release_identity_test.dart` — 제품 문서의 경계 이동 계약 정합성 검증
- Modify: `README.md` — 사용자 대상 실행 화면 설명
- Modify: `docs/00_product_brief.md` — 핵심 경험 계약
- Modify: `docs/01_prd.md` — 실행 화면 요구사항
- Modify: `docs/02_mvp_scope.md` — MVP 포함 범위
- Modify: `docs/03_user_flows.md` — 턴 전환 흐름
- Modify: `docs/04_screen_specs.md` — 실행 화면 표시 규칙
- Modify: `docs/08_android_launch_checklist.md` — 실제 기기 수동 QA
- Modify: `docs/09_vibe_coding_prompts.md` — 후속 에이전트 회귀 방지 프롬프트
- Modify: `docs/10_copy_and_brand.md` — Play 설명 초안
- Modify: `docs/11_time_rules.md` — 총 시간과 화면 경계 규칙 분리

## Execution safety

계획 작성 시점에 설정 저장·마이그레이션 관련 별도 변경이 작업 트리에 존재한다. 다음 경로는 이 계획의 범위가 아니므로 읽기 전용으로 취급하고 스테이징·수정·포맷하지 않는다.

- `lib/core/storage/migration_tombstone.dart`
- `lib/core/storage/storage_transaction_queue.dart`
- `lib/features/settings/app_settings.dart`
- `lib/features/settings/app_settings_persistence.dart`
- `lib/features/settings/app_settings_storage_io.dart`
- `lib/features/settings/app_settings_storage_stub.dart`
- `lib/features/settings/app_settings_storage_web.dart`
- `test/settings/app_settings_migration_test.dart`
- `test/settings/app_settings_test.dart`
- `test/settings/app_settings_web_migration_test.dart`

각 커밋은 해당 Task의 `git add` 목록만 사용한다. `git add .`와 `git add -A`는 사용하지 않는다.

### Task 1: 연속 선형 이동과 수동 턴 전환

**Files:**
- Modify: `test/app/timer_screen_test.dart:60-190,355-485`
- Modify: `lib/main.dart:21,206-218,286-316,475-679`

- [ ] **Step 1: 기존 경계 테스트를 새 계약의 실패 테스트로 바꾼다**

`test/app/timer_screen_test.dart`의 감속·중앙 초기화 기대값을 아래 선형 이동·위치 연속성 계약으로 교체한다.

```dart
testWidgets('clock boundary moves linearly throughout the current turn', (
  tester,
) async {
  await tester.binding.setSurfaceSize(const Size(1000, 400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await _pumpTimer(tester, _config());

  final leftZone = find.byKey(const ValueKey('clock-left-zone'));
  final initialWidth = tester.getSize(leftZone).width;

  await tester.pump(const Duration(seconds: 15));
  final firstQuarterWidth = tester.getSize(leftZone).width;

  await tester.pump(const Duration(seconds: 15));
  final halfwayWidth = tester.getSize(leftZone).width;

  expect(initialWidth, closeTo(500, 1));
  expect(firstQuarterWidth, closeTo(375, 2));
  expect(halfwayWidth, closeTo(250, 2));
  expect(
    initialWidth - firstQuarterWidth,
    closeTo(firstQuarterWidth - halfwayWidth, 2),
  );

  await _finishThroughDialog(tester);
  await tester.pumpWidget(const SizedBox.shrink());
});

testWidgets('next speaker continues from the visible boundary position', (
  tester,
) async {
  await tester.binding.setSurfaceSize(const Size(1000, 400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await _pumpTimer(tester, _config());
  final leftZone = find.byKey(const ValueKey('clock-left-zone'));

  await tester.pump(const Duration(seconds: 30));
  final widthBeforePass = tester.getSize(leftZone).width;
  expect(widthBeforePass, closeTo(250, 2));

  await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
  await tester.pump();

  expect(find.bySemanticsLabel(RegExp('B.*말하는 중')), findsOneWidget);
  expect(tester.getSize(leftZone).width, closeTo(widthBeforePass, 0.5));

  await tester.pump(const Duration(seconds: 30));
  expect(tester.getSize(leftZone).width, closeTo(625, 2));

  await _finishThroughDialog(tester);
  await tester.pumpWidget(const SizedBox.shrink());
});

testWidgets('turn pass during an animation frame preserves exact position', (
  tester,
) async {
  await tester.binding.setSurfaceSize(const Size(1000, 400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await _pumpTimer(tester, _config());
  final leftZone = find.byKey(const ValueKey('clock-left-zone'));

  await tester.pump(const Duration(milliseconds: 30350));
  final widthBeforePass = tester.getSize(leftZone).width;
  await tester.tap(find.bySemanticsLabel(RegExp('A.*말하는 중')));
  await tester.pump();

  expect(tester.getSize(leftZone).width, closeTo(widthBeforePass, 0.5));

  await _finishThroughDialog(tester);
  await tester.pumpWidget(const SizedBox.shrink());
});
```

기존 `active speaker remaining time pulls the boundary inward`, `clock background moves while the readout stays anchored`, `active speaker zone shrinks away when total time reaches zero` 테스트에서는 목표값 정착용 `800ms` 추가 pump를 제거한다. 연속 애니메이션은 정확히 30초, 1초, 총 잔여시간 동안 목표 비율에 도달해야 한다.

- [ ] **Step 2: 장시간 실행 애니메이션을 기다리지 않는 테스트 다이얼로그 헬퍼를 만든다**

계속 실행 중인 `AnimationController` 때문에 `pumpAndSettle()`이 제한시간을 초과하지 않도록 `test/app/timer_screen_test.dart`의 종료 헬퍼를 아래처럼 바꾼다.

```dart
Future<void> _openFinishDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('finish-session-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('종료할까요?'), findsOneWidget);
}

Future<void> _finishThroughDialog(WidgetTester tester) async {
  await _openFinishDialog(tester);
  await _tapText(tester, '종료');
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
    await tester.pump(const Duration(milliseconds: 300));
  }
}
```

기존 종료 확인 테스트도 아래처럼 바꿔 실행 중 애니메이션에서 settle을 기다리지 않는다.

```dart
await tester.tap(find.byKey(const ValueKey('pause-session-button')));
await tester.pump();
expect(find.byKey(const ValueKey('resume-session-button')), findsOneWidget);

await tester.tap(find.byKey(const ValueKey('resume-session-button')));
await tester.pump();
expect(find.byKey(const ValueKey('pause-session-button')), findsOneWidget);

await _openFinishDialog(tester);
await _tapText(tester, '취소', settle: false);
expect(find.text('종료할까요?'), findsNothing);
```

- [ ] **Step 3: 실패를 확인한다**

Run:

```bash
flutter test test/app/timer_screen_test.dart --plain-name "clock boundary moves linearly throughout the current turn"
flutter test test/app/timer_screen_test.dart --plain-name "next speaker continues from the visible boundary position"
flutter test test/app/timer_screen_test.dart --plain-name "turn pass during an animation frame preserves exact position"
```

Expected: 기존 구현은 700ms 감속 갱신을 사용하고 턴 전환 때 50%로 재생성되므로 최소한 선형 진행 또는 위치 연속성 기대값에서 FAIL한다.

- [ ] **Step 4: 세션 단위 시각 상태로 부모를 단순화한다**

`lib/main.dart`에서 `_clockBoundaryAnimationDuration`, `_turnVisualTotalSeconds`, `_turnVisualVersion`, `_resetTurnVisualProgress()`를 제거한다. `_TimerHomePageState`에는 세션 재시작만 식별하는 값을 둔다.

```dart
int _clockSessionVersion = 0;

void _beginSession() {
  _engine = TimerEngine.start(widget.config);
  _startedAt = DateTime.now();
  _feedbackCues = const [];
  _wrapUpRecord = null;
  _breakCount = 0;
  _totalBreakSeconds = 0;
  _breakStartedAt = null;
  _clockSessionVersion += 1;
}
```

`_commit()`의 `TurnPassedEvent` 전용 시각 초기화 블록을 삭제하고 `_ClockZoneLayout` 호출을 다음처럼 바꾼다.

```dart
_ClockZoneLayout(
  key: ValueKey('clock-zone-session-$_clockSessionVersion'),
  participantA: participantA,
  participantB: participantB,
  snapshot: snapshot,
  turnLimitSeconds: widget.config.turnLimitSeconds,
  turnDangerFlashEnabled:
      widget.config.alertConfig.turnDangerFlashEnabled,
  showOvertime: showOvertime,
  canResume: canResume,
  onPassTurn: canPass ? _passTurn : null,
),
```

- [ ] **Step 5: `_ClockZoneLayout`을 연속 애니메이션 상태 위젯으로 바꾼다**

기존 `TweenAnimationBuilder`와 `_currentTurnClockFraction()`을 제거한다. `_ClockZoneLayout` 필드에서 `turnVisualTotalSeconds`와 `turnVisualVersion`을 제거하고 다음 상태 생명주기를 추가한다.

```dart
final class _ClockZoneLayout extends StatefulWidget {
  final Participant participantA;
  final Participant participantB;
  final TimerSnapshot snapshot;
  final int turnLimitSeconds;
  final bool turnDangerFlashEnabled;
  final bool showOvertime;
  final bool canResume;
  final VoidCallback? onPassTurn;

  const _ClockZoneLayout({
    super.key,
    required this.participantA,
    required this.participantB,
    required this.snapshot,
    required this.turnLimitSeconds,
    required this.turnDangerFlashEnabled,
    required this.showOvertime,
    required this.canResume,
    required this.onPassTurn,
  });

  @override
  State<_ClockZoneLayout> createState() => _ClockZoneLayoutState();
}

final class _ClockZoneLayoutState extends State<_ClockZoneLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _boundaryController;

  @override
  void initState() {
    super.initState();
    _boundaryController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
      value: 0.5,
    );
    _startBoundaryMotion();
  }

  @override
  void didUpdateWidget(covariant _ClockZoneLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.activeParticipantId !=
        widget.snapshot.activeParticipantId) {
      _startBoundaryMotion();
    }
  }

  @override
  void dispose() {
    _boundaryController.dispose();
    super.dispose();
  }

  double get _targetFraction {
    return widget.snapshot.activeParticipantId == widget.participantA.id
        ? 0
        : 1;
  }

  void _startBoundaryMotion() {
    final remainingSeconds = widget.snapshot.currentTurnRemainingSeconds;
    if (remainingSeconds <= 0) {
      return;
    }
    _boundaryController.animateTo(
      _targetFraction,
      duration: Duration(seconds: remainingSeconds),
      curve: Curves.linear,
    );
  }
}
```

기존 `LayoutBuilder` 안의 `TweenAnimationBuilder<double>`는 아래 `AnimatedBuilder`로 교체한다. 내부 `Stack`과 읽기 영역은 그대로 두고 필드 접근만 `widget.`으로 바꾼다.

```dart
return AnimatedBuilder(
  animation: _boundaryController,
  builder: (context, child) {
    final leftFraction = _boundaryController.value.clamp(0.0, 1.0);
    final leftWidth = totalWidth * leftFraction;
    final rightWidth = totalWidth - leftWidth;
    final showLeftBackground = _shouldShowClockBackground(leftWidth);
    final showRightBackground = _shouldShowClockBackground(rightWidth);
    final showLeftReadout = widget.participantA.totalRemainingSeconds > 0;
    final showRightReadout = widget.participantB.totalRemainingSeconds > 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLeftBackground)
              SizedBox(
                key: const ValueKey('clock-left-zone'),
                width: leftWidth,
                child: const _ClockZoneBackground(isDark: false),
              ),
            if (showRightBackground)
              SizedBox(
                key: const ValueKey('clock-right-zone'),
                width: rightWidth,
                child: const _ClockZoneBackground(isDark: true),
              ),
          ],
        ),
        _TurnDangerFlash(
          snapshot: widget.snapshot,
          turnLimitSeconds: widget.turnLimitSeconds,
          enabled: widget.turnDangerFlashEnabled,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLeftReadout)
              Expanded(
                child: _ClockReadout(
                  participant: widget.participantA,
                  snapshot: widget.snapshot,
                  showOvertime: widget.showOvertime,
                  canResume: widget.canResume,
                  isDark: false,
                  onPassTurn: widget.onPassTurn,
                ),
              ),
            if (showRightReadout)
              Expanded(
                child: _ClockReadout(
                  participant: widget.participantB,
                  snapshot: widget.snapshot,
                  showOvertime: widget.showOvertime,
                  canResume: widget.canResume,
                  isDark: true,
                  onPassTurn: widget.onPassTurn,
                ),
              ),
          ],
        ),
      ],
    );
  },
);
```

- [ ] **Step 6: 포맷하고 Task 1 테스트를 통과시킨다**

Run:

```bash
dart format lib/main.dart test/app/timer_screen_test.dart
flutter test test/app/timer_screen_test.dart
```

Expected: `timer_screen_test.dart` 전체 PASS. 테스트 종료 시 pending timer 또는 `pumpAndSettle timed out` 오류가 없어야 한다.

- [ ] **Step 7: Task 1을 커밋한다**

```bash
git add lib/main.dart test/app/timer_screen_test.dart
git commit -m "fix: preserve clock boundary across turns"
```

### Task 2: 일시정지, 자동 전환, 크기 변경 상태 동기화

**Files:**
- Modify: `test/app/timer_screen_test.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: 일시정지 위치 보존 실패 테스트를 추가한다**

```dart
testWidgets('pause freezes the boundary and resume continues in place', (
  tester,
) async {
  await tester.binding.setSurfaceSize(const Size(1000, 400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await _pumpTimer(tester, _config());
  final leftZone = find.byKey(const ValueKey('clock-left-zone'));
  await tester.pump(const Duration(seconds: 15));
  final widthBeforePause = tester.getSize(leftZone).width;

  await tester.tap(find.byKey(const ValueKey('pause-session-button')));
  await tester.pump();
  await tester.pump(const Duration(seconds: 5));
  expect(tester.getSize(leftZone).width, closeTo(widthBeforePause, 0.5));

  await tester.tap(find.byKey(const ValueKey('resume-session-button')));
  await tester.pump();
  final widthAfterResume = tester.getSize(leftZone).width;
  expect(widthAfterResume, closeTo(widthBeforePause, 0.5));

  await tester.pump(const Duration(seconds: 10));
  expect(tester.getSize(leftZone).width, lessThan(widthAfterResume - 50));

  await _finishThroughDialog(tester);
  await tester.pumpWidget(const SizedBox.shrink());
});
```

- [ ] **Step 2: 자동 전환과 화면 비율 보존 테스트를 추가한다**

`_config()`가 오버타임 설정을 받을 수 있게 다음 인자를 추가한다.

```dart
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
```

다음 테스트를 추가한다.

```dart
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

testWidgets('overtime holds the boundary at the reached edge', (tester) async {
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
```

- [ ] **Step 3: 일시정지 테스트가 실패하는지 확인한다**

Run:

```bash
flutter test test/app/timer_screen_test.dart --plain-name "pause freezes the boundary and resume continues in place"
```

Expected: Task 1 구현은 발언자 변경만 감지하므로 일시정지 중에도 경계가 이동해 FAIL한다.

- [ ] **Step 4: 단계 변화에도 애니메이션을 동기화한다**

`_ClockZoneLayoutState.didUpdateWidget`과 시작 메서드를 다음처럼 바꾼다.

```dart
@override
void didUpdateWidget(covariant _ClockZoneLayout oldWidget) {
  super.didUpdateWidget(oldWidget);
  final speakerChanged = oldWidget.snapshot.activeParticipantId !=
      widget.snapshot.activeParticipantId;
  final phaseChanged = oldWidget.snapshot.phase != widget.snapshot.phase;
  if (speakerChanged || phaseChanged) {
    _syncBoundaryMotion();
  }
}

void _syncBoundaryMotion() {
  _boundaryController.stop(canceled: false);
  if (widget.snapshot.phase != TimerPhase.runningNormal) {
    return;
  }

  final remainingSeconds = widget.snapshot.currentTurnRemainingSeconds;
  if (remainingSeconds <= 0) {
    return;
  }

  _boundaryController.animateTo(
    _targetFraction,
    duration: Duration(seconds: remainingSeconds),
    curve: Curves.linear,
  );
}
```

`initState()`도 `_startBoundaryMotion()` 대신 `_syncBoundaryMotion()`을 호출한다. 이 규칙으로 정상 진행만 애니메이션하고, pause/overtime/needsExtension/finished에서는 실제 현재값을 유지한다.

- [ ] **Step 5: 상태 전환 테스트와 전체 타이머 화면 테스트를 통과시킨다**

Run:

```bash
dart format lib/main.dart test/app/timer_screen_test.dart
flutter test test/app/timer_screen_test.dart --plain-name "pause freezes the boundary and resume continues in place"
flutter test test/app/timer_screen_test.dart --plain-name "auto switch reverses from the reached edge"
flutter test test/app/timer_screen_test.dart --plain-name "surface resize preserves the boundary fraction"
flutter test test/app/timer_screen_test.dart --plain-name "repeated early passes reverse without position resets"
flutter test test/app/timer_screen_test.dart --plain-name "auto pause holds the boundary at the reached edge"
flutter test test/app/timer_screen_test.dart --plain-name "overtime holds the boundary at the reached edge"
flutter test test/app/timer_screen_test.dart --plain-name "new session resets the boundary to center"
flutter test test/app/timer_screen_test.dart
```

Expected: 모두 PASS. 일시정지 구간의 경계 폭은 허용 오차 안에서 같고, 자동 전환 후 30초에는 50%에 도달한다.

- [ ] **Step 6: Task 2를 커밋한다**

```bash
git add lib/main.dart test/app/timer_screen_test.dart
git commit -m "test: cover clock boundary lifecycle"
```

### Task 3: 제품 문서를 연속 경계 계약으로 맞춘다

**Files:**
- Modify: `test/release_identity_test.dart`
- Modify: `README.md`
- Modify: `docs/00_product_brief.md`
- Modify: `docs/01_prd.md`
- Modify: `docs/02_mvp_scope.md`
- Modify: `docs/03_user_flows.md`
- Modify: `docs/04_screen_specs.md`
- Modify: `docs/08_android_launch_checklist.md`
- Modify: `docs/09_vibe_coding_prompts.md`
- Modify: `docs/10_copy_and_brand.md`
- Modify: `docs/11_time_rules.md`

- [ ] **Step 1: 문서 계약 실패 테스트를 추가한다**

`test/release_identity_test.dart`에 다음 테스트를 추가한다.

```dart
test('v4 docs describe continuous clock boundary motion', () {
  const paths = <String>[
    'README.md',
    'docs/00_product_brief.md',
    'docs/01_prd.md',
    'docs/02_mvp_scope.md',
    'docs/03_user_flows.md',
    'docs/04_screen_specs.md',
    'docs/08_android_launch_checklist.md',
    'docs/09_vibe_coding_prompts.md',
    'docs/10_copy_and_brand.md',
    'docs/11_time_rules.md',
  ];
  const continuityRule = '턴이 넘어가도 경계는 현재 위치를 유지한다.';
  const stalePhrases = <String>[
    '남은 시간 비율만큼 화면 영역도 줄어든다.',
    '현재 발언자의 총 남은 시간이 줄어들수록 해당 영역 폭도 줄어든다.',
    '현재 발언자의 총 남은 시간이 줄면 해당 영역 폭도 줄어든다.',
    '전체 남은 시간 비율에 따른 영역 폭 변화',
    '현재 발언자의 영역 폭이 총 남은 시간에 맞춰 줄어든다.',
    '현재 발언자 총 남은 시간에 따른 영역 폭 변화',
    '한 사람의 총 시간이 줄어들면 실행 화면의 해당 영역 폭도 줄어든다.',
    '남편 영역 폭은 총 남은 시간 비율에 맞춰 줄어든다.',
  ];

  final contents = <String, String>{
    for (final path in paths) path: File(path).readAsStringSync(),
  };
  for (final entry in contents.entries) {
    expect(entry.value, contains(continuityRule), reason: entry.key);
  }

  final combined = contents.values.join('\n');
  for (final stalePhrase in stalePhrases) {
    expect(combined, isNot(contains(stalePhrase)), reason: stalePhrase);
  }
});
```

- [ ] **Step 2: 문서 테스트가 실패하는지 확인한다**

Run:

```bash
flutter test test/release_identity_test.dart --plain-name "v4 docs describe continuous clock boundary motion"
```

Expected: 문서에 연속성 문장이 없고 기존 총 잔여시간 비율 표현이 남아 있어 FAIL한다.

- [ ] **Step 3: 열 개 문서의 실행 화면 설명을 같은 계약으로 교체한다**

각 문서의 문맥에 맞게 기존 총 잔여시간 기반 문장을 제거하고 아래 세 문장을 그대로 포함한다.

```markdown
- 경계는 50:50에서 시작한다.
- 턴이 넘어가도 경계는 현재 위치를 유지한다.
- 새 발언자의 현재 영역은 턴 시간 동안 화면 바깥쪽 끝을 향해 선형으로 줄어든다.
```

`docs/03_user_flows.md`의 Flow 4는 다음 순서로 쓴다.

```markdown
## Flow 4. 실행 중 차례 넘기기
1. 첫 발언자의 영역이 활성 상태로 보인다.
2. 현재 발언자의 턴 시간과 총 남은 시간이 줄어든다.
3. 현재 발언자의 영역이 화면 바깥쪽 끝을 향해 선형으로 줄어든다.
4. 화면 영역을 탭하면 경계 위치를 유지한 채 차례가 상대에게 넘어간다.
5. 상대의 현재 영역 전체를 이동거리로 사용하는 새 턴이 시작된다.
6. 턴이 넘어가도 경계는 현재 위치를 유지한다.
```

`docs/11_time_rules.md`에서는 총 발언시간 절에서 화면 폭 문장을 제거하고 별도 절로 분리한다.

```markdown
## 시계 경계
- 경계는 50:50에서 시작한다.
- 턴이 넘어가도 경계는 현재 위치를 유지한다.
- 새 발언자의 현재 영역은 턴 시간 동안 화면 바깥쪽 끝을 향해 선형으로 줄어든다.
- 일시정지 중에는 경계도 현재 위치에서 멈춘다.
- 오버타임에는 현재 발언자 쪽 화면 끝 위치를 유지한다.
```

`docs/08_android_launch_checklist.md`에는 실제 기기에서 중앙 순간 이동이 없는지 확인하는 항목을 추가한다.

```markdown
- [ ] 턴을 중간에 넘겨도 경계가 중앙으로 순간 이동하지 않는다.
- [ ] 턴이 넘어가도 경계는 현재 위치를 유지한다.
- [ ] 일시정지와 재개 전후 경계 위치가 이어진다.
```

- [ ] **Step 4: 문서 테스트와 포맷을 확인한다**

Run:

```bash
dart format test/release_identity_test.dart
flutter test test/release_identity_test.dart
rg -n "[ \\t]+$" README.md docs/00_product_brief.md docs/01_prd.md docs/02_mvp_scope.md docs/03_user_flows.md docs/04_screen_specs.md docs/08_android_launch_checklist.md docs/09_vibe_coding_prompts.md docs/10_copy_and_brand.md docs/11_time_rules.md
```

Expected: release identity 테스트 전체 PASS, `rg` 출력 없음.

- [ ] **Step 5: Task 3을 커밋한다**

```bash
git add README.md docs/00_product_brief.md docs/01_prd.md docs/02_mvp_scope.md docs/03_user_flows.md docs/04_screen_specs.md docs/08_android_launch_checklist.md docs/09_vibe_coding_prompts.md docs/10_copy_and_brand.md docs/11_time_rules.md test/release_identity_test.dart
git commit -m "docs: align continuous clock boundary rules"
```

### Task 4: 전체 검증과 최종 검토

**Files:**
- Verify: all files changed in Tasks 1-3

- [ ] **Step 1: 변경된 Dart 파일 포맷과 정적 검사를 실행한다**

```bash
dart format --output=none --set-exit-if-changed lib/main.dart test/app/timer_screen_test.dart test/release_identity_test.dart
flutter analyze
```

Expected: 두 명령 모두 exit 0, analyzer issue 없음.

- [ ] **Step 2: 집중 회귀 테스트를 다시 실행한다**

```bash
flutter test test/app/timer_screen_test.dart
flutter test test/release_identity_test.dart
```

Expected: 두 테스트 파일 모두 PASS.

- [ ] **Step 3: 저장소 전체 게이트를 실행한다**

```bash
./tool/check.sh
```

Expected: 의존성 확인, analyze, 모든 Dart/Flutter 테스트, web build가 순서대로 통과한다.

- [ ] **Step 4: diff 위생과 범위를 확인한다**

```bash
git diff --check HEAD~3..HEAD
rg -n "[ \\t]+$" lib/main.dart test/app/timer_screen_test.dart test/release_identity_test.dart README.md docs/00_product_brief.md docs/01_prd.md docs/02_mvp_scope.md docs/03_user_flows.md docs/04_screen_specs.md docs/08_android_launch_checklist.md docs/09_vibe_coding_prompts.md docs/10_copy_and_brand.md docs/11_time_rules.md
git status --short
git log -5 --oneline --decorate
```

Expected: diff 오류와 trailing whitespace 출력 없음. 이 계획의 범위 파일에는 미커밋 변경이 없고, 설정·저장소 관련 기존 별도 변경은 내용과 staging 상태가 보존된다. 설계·계획·구현·수명주기 테스트·문서 정합성 커밋이 현재 브랜치에 존재한다.
