# 05. Flutter Architecture

## 1. 기술 선택
Flutter는 iOS와 Android를 하나의 코드베이스로 만들 수 있고, iOS 스타일 UI를 위해 Cupertino 위젯을 사용할 수 있다. MVP는 Flutter로 충분하며, iPhone 출시도 가능하다.

## 2. 권장 구조
```text
lib/
  main.dart
  app.dart
  core/
    theme/
    utils/
    constants/
    time/
  features/
    session_setup/
      presentation/
      application/
      domain/
    timer/
      presentation/
      application/
      domain/
    feedback/
      application/
      domain/
      data/
    history/
      presentation/
      application/
      domain/
      data/
    settings/
      presentation/
      application/
      domain/
      data/
  shared/
    widgets/
    models/
```

## 3. 상태관리
권장: Riverpod

이유:
- 타이머 상태를 UI와 분리하기 쉽다.
- 단위 테스트가 쉽다.
- 세션 설정, 타이머, 설정값, 기록 저장을 각각 관리하기 좋다.

대안:
- Bloc
- Provider
- ValueNotifier 기반 단순 구조

MVP에서는 Riverpod 또는 ValueNotifier 중 하나로 시작해도 된다. 핵심은 **타이머 엔진을 UI에서 분리하는 것**이다.

## 4. 핵심 도메인 객체
```text
Participant
SessionConfig
OvertimeConfig
PenaltyConfig
AlertConfig
TimerSession
TimerSnapshot
TimerEvent
PenaltyEvent
AlertEvent
SessionRecord
```

## 5. 도메인 모델 개요
### Participant
- id
- name
- totalAllocatedSeconds
- totalRemainingSeconds
- totalUsedSeconds
- turnCount
- overtimeTotalSeconds
- penaltyCount

### SessionConfig
- participantA
- participantB
- turnLimitSeconds
- firstSpeakerId
- overtimeConfig
- penaltyConfig
- alertConfig
- requireConsentForExtension

### OvertimeConfig
- enabled
- showOvertime
- countUp
- behavior
  - overtime
  - autoPause, when overtime is disabled
  - autoSwitch, future

### PenaltyConfig
- enabled
- thresholdSeconds
- repeatMode
  - oncePerTurn
  - everyThreshold
- labelMode
  - overtimeMark
  - warningMark
  - penalty

### AlertConfig
- warningBeforeSeconds
- turnWarningEnabled
- totalWarningEnabled
- overtimeStartAlertEnabled
- penaltyAlertEnabled
- visualEnabled
- soundEnabled
- hapticEnabled
- soundType
- hapticStrength

## 6. 타이머 엔진 구조
타이머 엔진은 순수 Dart 클래스로 만든다. UI 위젯, 플랫폼 소리, 진동, 저장소에 직접 의존하지 않는다.

```text
TimerEngine
  - start(config)
  - tick(elapsedSeconds)
  - passTurn()
  - pause()
  - resume()
  - finish()
  - addTime(participantId, seconds)
  - snapshot()
```

엔진은 상태 변경 결과로 이벤트를 반환한다.

```text
TimerEvent
  - TurnWarning
  - TotalWarning
  - OvertimeStarted
  - PenaltyReached
  - TurnPassed
  - TotalTimeEnded
  - SessionPaused
  - SessionFinished
```

UI는 이벤트를 받아 화면 표시를 갱신하고, FeedbackService는 알림 설정에 따라 소리/진동/햅틱을 실행한다.

## 7. 상태 머신
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

### Running.Normal
- 턴 시간이 남아 있다.
- 현재 발언자의 전체 시간과 턴 시간이 줄어든다.
- 사전 알림 조건을 검사한다.

### Running.Overtime
- 턴 시간이 0이다.
- 오버타임이 증가한다.
- 현재 발언자의 전체 시간이 남아 있으면 전체 시간도 계속 줄어든다.
- 패널티 기준 도달 여부를 검사한다.

### NeedsExtension
- 현재 발언자의 전체 시간이 0이다.
- 추가 시간 또는 종료를 선택해야 한다.

## 8. FeedbackService
소리, 진동, 햅틱, 화면 알림은 타이머 엔진이 직접 처리하지 않는다.

```text
FeedbackService
  - handle(AlertEvent event, AlertConfig config)
  - playSound(soundType)
  - triggerHaptic(strength)
  - showVisualCue(event)
```

장점:
- iOS와 Android 플랫폼 차이를 분리할 수 있다.
- 테스트에서 소리/진동을 목 처리할 수 있다.
- 사용자가 알림을 끄면 서비스에서 막을 수 있다.

## 9. 로컬 저장 구조
MVP는 로컬 저장만 한다.

권장 저장 대상:
- 앱 설정값
- 최근 세션 기록
- 사용자 입력 메모

저장소 후보:
- SharedPreferences 계열: 간단한 설정값
- 로컬 DB 계열: 세션 기록이 늘어날 때

초기 MVP에서는 설정값과 기록 수가 적으므로 단순 저장으로 시작해도 된다. 단, 데이터 모델은 나중에 로컬 DB로 옮기기 쉽게 분리한다.

## 10. 화면 계층 구조
```text
App
  HomeScreen
  SessionSetupFlow
    ParticipantStep
    TimeConfigStep
    OvertimeConfigStep
    AlertConfigStep
    ConsentScreen
  TimerScreen
    ParticipantCard
    TurnClock
    OvertimeBanner
    PenaltyBadge
    TimerControls
  BreakScreen
  ExtensionScreen
  WrapUpScreen
  HistoryScreen
  SettingsScreen
```

## 11. 테스트 전략
### 단위 테스트
반드시 작성:
- 참가자별 전체 시간이 다르게 설정되는지
- 턴 시간이 감소하는지
- 턴 시간이 0이 되면 오버타임이 시작되는지
- 오버타임이 증가하는지
- 오버타임 60초에 패널티가 발생하는지
- 반복 패널티가 꺼져 있으면 한 턴에 한 번만 발생하는지
- 반복 패널티가 켜져 있으면 기준마다 발생하는지
- 10초 전 알림 이벤트가 발생하는지
- 알림 이벤트가 중복 발생하지 않는지
- 전체 시간이 0이 되면 NeedsExtension으로 이동하는지
- 휴식 중에는 시간이 흐르지 않는지

### 위젯 테스트
- 설정 화면에서 각자 다른 시간 입력
- Consent 화면 규칙 표시
- Timer 화면 Normal/Overtime/Penalty 상태 표시
- Alert 설정 토글
- Wrap-up 요약 표시

### 수동 테스트
- 실제 iPhone에서 햅틱/진동 확인
- 소리 설정 확인
- 화면이 잠깐 꺼졌다 돌아온 후 타이머 확인
- 긴 세션에서 시간 오차 확인

## 12. 백그라운드/시간 정확도
타이머는 단순히 1초마다 숫자를 빼는 방식만 사용하면 앱이 백그라운드에 있을 때 오차가 생길 수 있다.

권장 방식:
- 세션 시작 시각과 마지막 업데이트 시각을 저장한다.
- UI 업데이트는 1초마다 한다.
- 실제 계산은 현재 시각과 마지막 계산 시각의 차이로 한다.
- 앱이 다시 활성화되면 경과 시간을 엔진에 전달한다.

## 13. 알림 구현 주의
MVP의 10초 전 알림은 앱 내부 피드백이다. 푸시 알림이 아니다.

- 앱이 열려 있을 때 화면/소리/진동으로 알린다.
- 앱 밖에서 알림을 보내는 기능은 MVP에서 제외한다.
- 소리와 햅틱은 사용자 설정을 따른다.
- 기기나 OS 설정 때문에 소리/진동이 실행되지 않을 수 있으므로 화면 표시를 항상 기본 피드백으로 둔다.

## 14. 의존성 원칙
- 타이머 엔진은 외부 패키지 없이 순수 Dart로 작성한다.
- 플랫폼 피드백은 어댑터로 분리한다.
- 저장소는 인터페이스를 먼저 만들고 구현체를 나중에 바꿀 수 있게 한다.
- UI는 엔진 상태를 읽기만 하고, 시간 계산을 직접 하지 않는다.
