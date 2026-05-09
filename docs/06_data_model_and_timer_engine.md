# 06. Data Model & Timer Engine

## 1. 핵심 개념
말차례 CalmTurn의 핵심은 “현재 발언자에게만 시간이 흐른다”는 것이다. v3에서는 시간이 네 가지로 나뉜다.

1. **전체 발언 시간**: 대화 전체에서 각자가 사용할 수 있는 총 말하기 시간. 각자 다르게 설정할 수 있다.
2. **턴당 발언 제한**: 한 번의 차례에서 기본적으로 말할 수 있는 시간.
3. **오버타임**: 턴 시간이 0이 된 뒤 차례 넘기기를 누르지 않은 시간.
4. **알림 기준 시간**: 시간이 얼마 남았을 때 알려줄지 정하는 값. 기본 10초.

현재 발언자가 Normal 상태로 말하는 동안 전체 시간과 턴 시간이 동시에 줄어든다. 턴 시간이 0이 되면 Overtime 상태로 들어가며, 오버타임이 증가한다. 오버타임 중에도 현재 발언자의 전체 시간이 남아 있다면 전체 시간은 계속 줄어든다.

## 2. 핵심 결정
### 2.1 전체 발언 시간은 참가자별로 다를 수 있다
기본값은 같은 시간이다. 그러나 사용자가 합의하면 다음처럼 다르게 설정할 수 있다.

```text
A totalAllocatedSeconds = 300
B totalAllocatedSeconds = 600
```

### 2.2 턴 제한 종료 후 기본 동작은 자동 전환이 아니다
턴 시간이 0이 되면 앱은 상대 차례로 자동 전환하지 않고 오버타임을 측정한다.

```text
turnRemainingSeconds == 0
  -> currentTurnOvertimeSeconds starts counting up
```

### 2.3 패널티는 오버타임 기준 도달 이벤트다
기본값은 오버타임 60초다.

```text
if currentTurnOvertimeSeconds >= penaltyThresholdSeconds:
    add penalty
```

### 2.4 10초 전 알림은 이벤트다
알림 자체는 엔진이 실행하지 않는다. 엔진은 AlertEvent를 만들고 UI/FeedbackService가 처리한다.

## 3. 상태 머신
```text
Draft
  -> WaitingConsent
  -> Running.Normal
  -> Running.Overtime
  -> Paused
  -> Running.Normal / Running.Overtime
  -> NeedsExtension
  -> Finished
```

## 4. 상태 설명
### Draft
세션이 설정 중이다. 참가자 이름, 전체 발언 시간, 턴당 제한, 오버타임, 패널티, 알림을 입력한다.

### WaitingConsent
두 사람이 규칙에 동의하는 단계다.

### Running.Normal
현재 발언자의 전체 시간과 턴 시간이 흐르고 있다.

### Running.Overtime
현재 발언자의 턴 시간이 끝났고, 차례 넘기기를 누르지 않아 오버타임이 흐르고 있다.

### Paused
휴식 또는 일시정지 상태다. 전체 시간, 턴 시간, 오버타임이 모두 멈춘다.

### NeedsExtension
현재 발언자의 전체 시간이 0이다. 종료하거나 시간을 추가해야 한다.

### Finished
세션이 종료되었고 기록이 저장될 수 있다.

## 5. 데이터 모델 초안

### Participant
```dart
class Participant {
  final String id;
  final String name;
  final int totalAllocatedSeconds;
  final int totalRemainingSeconds;
  final int totalUsedSeconds;
  final int turnCount;
  final int overtimeTotalSeconds;
  final int penaltyCount;

  const Participant({
    required this.id,
    required this.name,
    required this.totalAllocatedSeconds,
    required this.totalRemainingSeconds,
    required this.totalUsedSeconds,
    required this.turnCount,
    required this.overtimeTotalSeconds,
    required this.penaltyCount,
  });
}
```

### SessionConfig
```dart
class SessionConfig {
  final ParticipantConfig participantA;
  final ParticipantConfig participantB;
  final int turnLimitSeconds;
  final String firstSpeakerId;
  final OvertimeConfig overtimeConfig;
  final PenaltyConfig penaltyConfig;
  final AlertConfig alertConfig;
  final bool requireBothConsentForExtension;

  const SessionConfig({
    required this.participantA,
    required this.participantB,
    required this.turnLimitSeconds,
    required this.firstSpeakerId,
    required this.overtimeConfig,
    required this.penaltyConfig,
    required this.alertConfig,
    this.requireBothConsentForExtension = true,
  });
}
```

### ParticipantConfig
```dart
class ParticipantConfig {
  final String id;
  final String name;
  final int totalAllocatedSeconds;

  const ParticipantConfig({
    required this.id,
    required this.name,
    required this.totalAllocatedSeconds,
  });
}
```

### OvertimeConfig
```dart
enum TurnLimitBehavior {
  overtime,
  autoSwitch,
  autoPause,
}

class OvertimeConfig {
  final bool enabled;
  final bool showOvertime;
  final TurnLimitBehavior behavior;

  const OvertimeConfig({
    this.enabled = true,
    this.showOvertime = true,
    this.behavior = TurnLimitBehavior.overtime,
  });
}
```

MVP 기본값은 `TurnLimitBehavior.overtime`이다. `autoSwitch`, `autoPause`는 후속 버전 옵션으로 둔다.

### PenaltyConfig
```dart
enum PenaltyRepeatMode {
  oncePerTurn,
  everyThreshold,
}

enum PenaltyLabelMode {
  overtimeMark,
  warningMark,
  penalty,
}

class PenaltyConfig {
  final bool enabled;
  final int thresholdSeconds;
  final PenaltyRepeatMode repeatMode;
  final PenaltyLabelMode labelMode;

  const PenaltyConfig({
    this.enabled = true,
    this.thresholdSeconds = 60,
    this.repeatMode = PenaltyRepeatMode.oncePerTurn,
    this.labelMode = PenaltyLabelMode.overtimeMark,
  });
}
```

### AlertConfig
```dart
class AlertConfig {
  final int warningBeforeSeconds;
  final bool turnWarningEnabled;
  final bool totalWarningEnabled;
  final bool overtimeStartAlertEnabled;
  final bool penaltyAlertEnabled;
  final bool visualEnabled;
  final bool soundEnabled;
  final bool hapticEnabled;
  final String soundType;
  final String hapticStrength;

  const AlertConfig({
    this.warningBeforeSeconds = 10,
    this.turnWarningEnabled = true,
    this.totalWarningEnabled = true,
    this.overtimeStartAlertEnabled = true,
    this.penaltyAlertEnabled = true,
    this.visualEnabled = true,
    this.soundEnabled = false,
    this.hapticEnabled = true,
    this.soundType = 'soft',
    this.hapticStrength = 'medium',
  });
}
```

### TimerSnapshot
```dart
enum TimerPhase {
  draft,
  waitingConsent,
  runningNormal,
  runningOvertime,
  paused,
  needsExtension,
  finished,
}

class TimerSnapshot {
  final TimerPhase phase;
  final List<Participant> participants;
  final String activeParticipantId;
  final int currentTurnRemainingSeconds;
  final int currentTurnOvertimeSeconds;
  final bool hasPenaltyInCurrentTurn;
  final Set<String> firedAlertKeys;

  const TimerSnapshot({
    required this.phase,
    required this.participants,
    required this.activeParticipantId,
    required this.currentTurnRemainingSeconds,
    required this.currentTurnOvertimeSeconds,
    required this.hasPenaltyInCurrentTurn,
    required this.firedAlertKeys,
  });
}
```

### TimerEvent
```dart
sealed class TimerEvent {}

class TurnWarningEvent extends TimerEvent {
  final String participantId;
  final int remainingSeconds;
}

class TotalWarningEvent extends TimerEvent {
  final String participantId;
  final int remainingSeconds;
}

class OvertimeStartedEvent extends TimerEvent {
  final String participantId;
}

class PenaltyReachedEvent extends TimerEvent {
  final String participantId;
  final int overtimeSeconds;
  final int penaltyCount;
}

class TurnPassedEvent extends TimerEvent {
  final String fromParticipantId;
  final String toParticipantId;
}

class TotalTimeEndedEvent extends TimerEvent {
  final String participantId;
}
```

## 6. 시간 계산 규칙

### 6.1 Normal 상태
매 초마다:

```text
active.totalRemainingSeconds -= 1
active.totalUsedSeconds += 1
currentTurnRemainingSeconds -= 1
```

단, `totalRemainingSeconds`가 0이 되면 NeedsExtension으로 이동한다.

### 6.2 사전 알림
```text
if currentTurnRemainingSeconds == alert.warningBeforeSeconds:
    emit TurnWarningEvent

if active.totalRemainingSeconds == alert.warningBeforeSeconds:
    emit TotalWarningEvent
```

이벤트는 같은 조건에서 한 번만 발생해야 한다.

### 6.3 턴 시간이 0이 되는 순간
```text
if currentTurnRemainingSeconds == 0:
    phase = Running.Overtime
    currentTurnOvertimeSeconds = 0
    emit OvertimeStartedEvent
```

### 6.4 Overtime 상태
매 초마다:

```text
currentTurnOvertimeSeconds += 1
active.overtimeTotalSeconds += 1
active.totalRemainingSeconds -= 1
active.totalUsedSeconds += 1
```

단, 전체 시간이 0이면 NeedsExtension으로 이동하고 오버타임은 더 증가하지 않는다.

### 6.5 패널티 발생
기본 반복 모드가 `oncePerTurn`일 때:

```text
if penalty.enabled
  and !hasPenaltyInCurrentTurn
  and currentTurnOvertimeSeconds >= penalty.thresholdSeconds:
      active.penaltyCount += 1
      hasPenaltyInCurrentTurn = true
      emit PenaltyReachedEvent
```

반복 모드가 `everyThreshold`일 때:

```text
penaltyIndex = currentTurnOvertimeSeconds ~/ penalty.thresholdSeconds
if penaltyIndex > lastPenaltyIndexInCurrentTurn:
    active.penaltyCount += 1
    emit PenaltyReachedEvent
```

### 6.6 차례 넘기기
```text
passTurn():
    previous = active
    next = otherParticipant
    previous.turnCount += 1
    activeParticipantId = next.id
    currentTurnRemainingSeconds = min(config.turnLimitSeconds, next.totalRemainingSeconds)
    currentTurnOvertimeSeconds = 0
    hasPenaltyInCurrentTurn = false
    clear per-turn alert flags
    phase = Running.Normal
    emit TurnPassedEvent
```

### 6.7 전체 시간이 0인 참가자의 턴
전체 시간이 0인 참가자에게 차례를 넘길 수 없다. 먼저 시간을 추가하거나 종료해야 한다.

```text
if next.totalRemainingSeconds <= 0:
    phase = NeedsExtension
```

## 7. 세션 기록 모델
```dart
class SessionRecord {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final SessionConfigSnapshot config;
  final List<ParticipantResult> participantResults;
  final int breakCount;
  final int totalBreakSeconds;
  final String? agreedNotes;
  final String? nextTopics;

  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.config,
    required this.participantResults,
    required this.breakCount,
    required this.totalBreakSeconds,
    this.agreedNotes,
    this.nextTopics,
  });
}
```

### ParticipantResult
```dart
class ParticipantResult {
  final String participantId;
  final String name;
  final int totalAllocatedSeconds;
  final int totalUsedSeconds;
  final int totalRemainingSeconds;
  final int turnCount;
  final int overtimeTotalSeconds;
  final int penaltyCount;

  const ParticipantResult({
    required this.participantId,
    required this.name,
    required this.totalAllocatedSeconds,
    required this.totalUsedSeconds,
    required this.totalRemainingSeconds,
    required this.turnCount,
    required this.overtimeTotalSeconds,
    required this.penaltyCount,
  });
}
```

## 8. 테스트 케이스

### TC-01. 참가자별 다른 전체 시간
- A 300초, B 600초로 시작한다.
- A가 10초 말하면 A는 290초, B는 600초다.

### TC-02. 턴 시간 감소
- 턴 제한 60초로 시작한다.
- 10초 후 턴 남은 시간은 50초다.

### TC-03. 10초 전 턴 알림
- 턴 제한 60초로 시작한다.
- 50초가 지나 턴 남은 시간이 10초가 되면 TurnWarningEvent가 1회 발생한다.
- 51초 이후 같은 이벤트가 반복되지 않는다.

### TC-04. 10초 전 전체 시간 알림
- A의 전체 시간이 20초다.
- 10초 후 A 전체 시간이 10초가 되면 TotalWarningEvent가 1회 발생한다.

### TC-05. 오버타임 시작
- 턴 제한 60초로 시작한다.
- 60초가 지나면 phase는 Running.Overtime이다.
- currentTurnOvertimeSeconds는 0이다.
- OvertimeStartedEvent가 발생한다.

### TC-06. 오버타임 증가
- Running.Overtime에서 5초가 지난다.
- currentTurnOvertimeSeconds는 5다.
- active.overtimeTotalSeconds도 5 증가한다.

### TC-07. 패널티 1회 발생
- 패널티 기준 60초다.
- 오버타임 60초에 도달하면 penaltyCount가 1 증가한다.
- PenaltyReachedEvent가 발생한다.

### TC-08. 같은 턴에서 패널티 중복 방지
- 반복 패널티가 꺼져 있다.
- 오버타임 120초가 되어도 같은 턴에서 penaltyCount는 1만 증가한다.

### TC-09. 반복 패널티
- 반복 패널티가 켜져 있다.
- 기준 60초다.
- 오버타임 60초에 1회, 120초에 2회째가 발생한다.

### TC-10. 차례 넘기기
- A가 오버타임 20초 상태다.
- 차례 넘기기를 누른다.
- activeParticipantId는 B가 된다.
- currentTurnRemainingSeconds는 B의 턴 제한으로 초기화된다.
- currentTurnOvertimeSeconds는 0이다.

### TC-11. 전체 시간 종료
- A의 전체 시간이 3초 남았다.
- 3초 후 NeedsExtension 상태가 된다.
- 오버타임 또는 턴 시간은 더 증가하지 않는다.

### TC-12. 휴식
- Running.Normal에서 pause를 호출한다.
- 30초가 지나도 전체 시간과 턴 시간은 변하지 않는다.
- resume 후 다시 감소한다.

## 9. 구현 주의사항
- UI에서 직접 초를 빼지 않는다.
- 엔진은 현재 상태와 이벤트만 반환한다.
- 소리/진동은 FeedbackService가 처리한다.
- 사전 알림은 이벤트별로 중복 방지 키를 둔다.
- 오버타임과 패널티는 대화 기록에 저장한다.
- 패널티를 승패 판단에 사용하지 않는다.
- 앱이 백그라운드로 갔다가 돌아오면 실제 경과 시간을 계산해 엔진에 전달한다.
