# 09. Step-by-step Vibe Coding Prompts

이 문서는 앱을 한 번에 만들라고 시키지 않고, 작은 단위로 안정적으로 만들어가기 위한 프롬프트 모음이다. 각 단계가 끝나면 실행, 테스트, 커밋을 하고 다음 단계로 넘어간다.

## 개발환경 선행 확인
```text
Flutter 프로젝트 생성이나 Dart 코드 구현을 시작하기 전에 `flutter --version`과 `dart --version`이 실행되는지 확인해줘.
둘 중 하나라도 현재 PATH에서 실행되지 않으면 코드 생성을 시작하지 말고, Flutter/Dart 설치 또는 PATH 설정을 먼저 완료해줘.
```

## 공통 규칙 프롬프트
```text
너는 Flutter 시니어 개발자다. 앱 이름은 말차례 CalmTurn이다. 이 앱은 두 사람이 체스 시계처럼 말할 시간을 나누되, 전체 발언 시간, 턴당 발언 제한, 오버타임, 패널티, 알림을 함께 관리하는 대화 타이머다.

중요 원칙:
- MVP는 2인 대화만 지원한다.
- 각 참여자의 전체 발언 시간은 기본적으로 같지만, 사용자가 합의하면 각자 다르게 설정할 수 있다.
- 한 번의 차례에는 턴당 발언 제한이 있다.
- 말하는 사람의 전체 시간과 이번 턴 시간이 동시에 줄어든다.
- 턴 시간이 0이 되면 기본적으로 자동 전환하지 않고 오버타임 상태로 들어간다.
- 차례 넘기기를 누르지 않으면 현재 발언자의 오버타임이 계속 증가한다.
- 사용자가 오버타임을 끄면 턴 시간이 0이 되는 순간 자동 휴식 상태로 들어간다.
- 자동 휴식 중에는 전체 시간, 턴 시간, 오버타임, 패널티가 변하지 않는다.
- 자동 휴식 이후 차례 넘기기를 누르면 상대 차례가 새 턴으로 시작된다.
- 오버타임이 기본 1분에 도달하면 패널티 이벤트를 발생시킨다.
- 패널티 기준은 설정 가능해야 한다.
- 각자 발언 시간이 10초 남으면 알림 이벤트를 발생시킨다.
- 알림 시점과 방식은 설정 가능해야 한다.
- 알림 방식은 화면, 소리, 진동/햅틱을 지원할 수 있게 설계한다.
- MVP는 로그인, 클라우드, 녹음, AI, 결제 없이 만든다.
- MVP에서는 누가 실제로 말하는지 음성으로 감지하지 않는다. 버튼 입력 기준으로 차례를 판단한다.
- 타이머 로직은 UI와 분리한다.
- 모든 핵심 타이머 로직에는 단위 테스트를 작성한다.
- iOS 출시를 고려해 접근성과 단순한 UI를 우선한다.
- 한 번에 전체 앱을 만들지 말고, 내가 요청한 단계만 구현한다.
```

## Prompt 0 — 프로젝트 생성과 구조
```text
Flutter 프로젝트를 새로 만들고, 아래 구조로 폴더를 정리해줘.

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

test/
  timer/
  settings/

아직 UI를 많이 만들지 말고, 기본 앱이 실행되는 상태와 폴더 구조만 만들어줘.
```

## Prompt 1 — 도메인 모델 만들기
```text
말차례 CalmTurn의 도메인 모델을 만들어줘.

필요한 모델:
- ParticipantConfig
- Participant
- SessionConfig
- OvertimeConfig
- PenaltyConfig
- AlertConfig
- TimerSnapshot
- TimerEvent
- SessionRecord
- ParticipantResult

요구사항:
- 참가자별 전체 발언 시간은 다를 수 있다.
- 턴당 제한 시간이 있다.
- 오버타임 설정이 있다.
- 패널티 기준 시간이 있다. 기본값은 60초다.
- 알림 기준 시간이 있다. 기본값은 10초다.
- 알림 방식은 visual, sound, haptic을 bool 값으로 표현한다.
- 모든 모델은 불변 객체로 만들어줘.
- copyWith가 필요하면 추가해줘.
- 아직 UI는 만들지 마.
```

## Prompt 2 — 순수 Dart 타이머 엔진 만들기
```text
순수 Dart로 TimerEngine을 만들어줘. Flutter UI나 플랫폼 API에 의존하지 않아야 한다.

필수 기능:
- start(config)
- tick(Duration elapsed)
- passTurn()
- pause()
- resume()
- finish()
- addTime(participantId, seconds)
- snapshot()

타이머 규칙:
- 현재 발언자의 전체 시간과 턴 시간이 동시에 줄어든다.
- 오버타임이 켜져 있으면 턴 시간이 0이 될 때 Running.Overtime 상태로 간다.
- 오버타임 중에는 currentTurnOvertimeSeconds가 증가한다.
- 오버타임 중에도 현재 발언자의 전체 시간이 남아 있으면 전체 시간이 계속 줄어든다.
- 오버타임이 penaltyThresholdSeconds에 도달하면 PenaltyReachedEvent를 발생시킨다.
- 오버타임이 꺼져 있으면 턴 시간이 0이 될 때 Paused 상태로 간다.
- 오버타임이 꺼진 자동 휴식 상태에서는 추가 tick에도 전체 시간, 턴 시간, 오버타임, 패널티가 변하지 않는다.
- 자동 휴식 이후 passTurn()을 누르면 상대 차례가 되고 턴 시간이 초기화된다.
- 기본 반복 모드는 oncePerTurn이다.
- currentTurnRemainingSeconds가 warningBeforeSeconds에 도달하면 TurnWarningEvent를 한 번 발생시킨다.
- active.totalRemainingSeconds가 warningBeforeSeconds에 도달하면 TotalWarningEvent를 한 번 발생시킨다.
- 전체 시간이 0이 되면 NeedsExtension 상태로 간다. 전체 시간이 먼저 0이 되는 경우에는 자동 휴식보다 NeedsExtension이 우선한다.
- 휴식 중에는 시간이 흐르지 않는다.

테스트하기 쉽게 이벤트 리스트를 반환하도록 만들어줘.
```

## Prompt 3 — 타이머 엔진 단위 테스트
```text
TimerEngine에 대한 단위 테스트를 작성해줘.

테스트 케이스:
1. A 5분, B 10분처럼 전체 시간이 다르게 설정된다.
2. Normal 상태에서 현재 발언자의 전체 시간과 턴 시간이 줄어든다.
3. 턴 시간이 10초 남으면 TurnWarningEvent가 한 번 발생한다.
4. 전체 시간이 10초 남으면 TotalWarningEvent가 한 번 발생한다.
5. 턴 시간이 0이 되면 Running.Overtime 상태가 된다.
6. 오버타임이 증가한다.
7. 오버타임 60초에 패널티가 1회 발생한다.
8. oncePerTurn 모드에서는 같은 턴에 패널티가 중복 발생하지 않는다.
9. everyThreshold 모드에서는 60초, 120초마다 패널티가 발생한다.
10. passTurn을 누르면 상대 차례가 되고 턴 시간이 초기화된다.
11. pause 상태에서는 시간이 흐르지 않는다.
12. 전체 시간이 0이 되면 NeedsExtension 상태가 된다.
13. 오버타임이 꺼져 있으면 턴 시간이 0이 될 때 Paused 상태가 된다.
14. 오버타임이 꺼진 자동 휴식 상태에서 tick을 호출해도 시간이 더 흐르지 않고 패널티가 발생하지 않는다.
15. 자동 휴식 상태에서 passTurn을 누르면 상대 차례가 되고 턴 시간이 초기화된다.
16. 전체 시간이 턴 제한보다 짧으면 자동 휴식보다 NeedsExtension이 우선한다.

실패 케이스도 포함해줘.
```

## Prompt 4 — 세션 설정 화면 만들기
```text
SessionSetupFlow를 만들어줘.

화면 요소:
- 참가자 A 이름
- 참가자 B 이름
- 전체 발언 시간 모드: 같은 시간 / 각자 다르게
- 같은 시간일 때 프리셋: 3분, 5분, 10분, 15분, 직접 입력
- 각자 다르게일 때 A 시간, B 시간 직접 입력
- 턴당 제한 프리셋: 30초, 45초, 1분, 1분 30초, 2분, 직접 입력
- 첫 발언자 선택
- 다음 버튼

요구사항:
- 입력값을 검증해줘.
- 각자 다른 전체 시간이면 안내 문구를 보여줘.
- 아직 타이머 화면과 연결하지 말고 SessionConfig를 만들 수 있게 해줘.
```

## Prompt 5 — 오버타임/패널티/알림 설정 화면 만들기
```text
OvertimePenaltyAlertSettings 화면을 만들어줘.

필드:
- 오버타임 사용 여부
- 패널티 기준: 15초, 30초, 1분, 2분, 직접 입력
- 반복 패널티 여부
- 사전 알림 시점: 5초, 10초, 15초, 30초, 직접 입력
- 턴 시간 알림 켜기/끄기
- 전체 시간 알림 켜기/끄기
- 오버타임 시작 알림 켜기/끄기
- 패널티 알림 켜기/끄기
- 화면 표시 켜기/끄기
- 소리 켜기/끄기
- 진동/햅틱 켜기/끄기

기본값:
- 오버타임 켜짐
- 패널티 기준 60초
- 반복 패널티 꺼짐
- 사전 알림 10초
- 화면 표시 켜짐
- 진동/햅틱 켜짐
- 소리 꺼짐

설정값으로 OvertimeConfig, PenaltyConfig, AlertConfig를 생성해줘.
```

## Prompt 6 — Consent 화면 만들기
```text
ConsentScreen을 만들어줘.

표시해야 할 내용:
- 참가자별 전체 발언 시간
- 턴당 발언 제한
- 오버타임 사용 여부
- 패널티 기준
- 반복 패널티 여부
- 10초 전 알림 또는 설정된 알림 시점
- 알림 방식: 화면/소리/진동
- 첫 발언자

요구사항:
- 두 사람이 각각 동의해야 시작 버튼이 활성화된다.
- 각자 전체 시간이 다르면 더 눈에 띄게 표시해줘.
- “차례를 넘기지 않으면 오버타임이 기록됩니다” 문구를 넣어줘.
- “불편하면 언제든 휴식하거나 종료할 수 있습니다” 문구를 넣어줘.
```

## Prompt 7 — Timer 화면 만들기
```text
TimerScreen을 만들어줘.

필수 요소:
- 참가자 A 카드
- 참가자 B 카드
- 각자의 전체 남은 시간
- 각자의 오버타임 합계
- 각자의 패널티 횟수
- 현재 발언자 표시
- 현재 턴 남은 시간
- 오버타임 상태 표시
- 차례 넘기기 버튼
- 잠깐 쉬기 버튼
- 종료 버튼

상태별 UI:
- Normal: 현재 턴 남은 시간을 크게 표시
- Warning: “10초 남았습니다” 또는 설정된 문구 표시
- Overtime: “오버타임 +00:12”처럼 증가 표시
- Penalty: “오버타임 기준에 도달했어요” 표시
- NeedsExtension: 시간 추가/종료 선택 표시

TimerEngine의 TimerSnapshot과 TimerEvent를 사용해서 UI를 갱신해줘.
```

## Prompt 8 — FeedbackService 만들기
```text
FeedbackService를 만들어줘.

목표:
- TimerEvent와 AlertConfig를 받아서 화면 표시, 소리, 진동/햅틱 요청을 처리한다.
- 실제 플랫폼 API 호출은 어댑터로 분리한다.
- 테스트에서는 MockFeedbackAdapter를 사용할 수 있게 한다.

필요 기능:
- handleTurnWarning
- handleTotalWarning
- handleOvertimeStarted
- handlePenaltyReached
- playSound
- triggerHaptic
- showVisualCue

요구사항:
- visualEnabled가 false면 화면 알림을 만들지 않는다.
- soundEnabled가 false면 소리를 재생하지 않는다.
- hapticEnabled가 false면 햅틱을 실행하지 않는다.
- 같은 이벤트가 중복 실행되지 않도록 이벤트 id를 받을 수 있게 해줘.
```

## Prompt 9 — 휴식, 시간 연장, 종료
```text
BreakScreen, TimeExtensionScreen, WrapUpScreen을 만들어줘.

BreakScreen:
- 모든 시간이 멈춘 상태를 보여준다.
- 이어서 하기, 오늘은 여기까지 버튼이 있다.

TimeExtensionScreen:
- 누구에게 시간을 추가할지 선택한다.
- 추가 시간 1분, 3분, 5분, 직접 입력을 제공한다.
- 기본은 양쪽 동의가 필요하다.

WrapUpScreen:
- 각자 사용한 시간
- 각자 남은 시간
- 각자 오버타임 합계
- 각자 패널티 횟수
- 휴식 횟수
- 합의한 것 입력
- 다음에 이야기할 것 입력
- 저장/저장하지 않기

승패 표현은 쓰지 마.
```

## Prompt 10 — 로컬 기록 저장
```text
세션 기록을 로컬에 저장하는 기능을 만들어줘.

저장 항목:
- 세션 날짜
- 참가자 이름
- 각자 설정한 전체 발언 시간
- 턴당 제한
- 오버타임 설정
- 패널티 기준
- 알림 설정
- 각자 사용한 시간
- 각자 오버타임 합계
- 각자 패널티 횟수
- 휴식 횟수
- 메모

기능:
- 기록 저장
- 기록 목록 조회
- 기록 상세 조회
- 기록 삭제
- 모든 기록 삭제

저장소 인터페이스와 구현체를 분리해줘.
```

## Prompt 11 — 앱 설정 화면
```text
SettingsScreen을 만들어줘.

설정 항목:
- 기본 전체 발언 시간
- 전체 발언 시간 기본 모드: 같은 시간 / 각자 다르게
- 기본 턴 제한
- 오버타임 기본값
- 패널티 기준 기본값
- 반복 패널티 기본값
- 사전 알림 시점 기본값
- 턴 시간 알림
- 전체 시간 알림
- 오버타임 시작 알림
- 패널티 알림
- 화면 표시
- 소리
- 진동/햅틱
- 기록 자동 저장 여부
- 모든 기록 삭제

설정값은 다음 새 세션 생성 시 기본값으로 적용되게 해줘.
```

## Prompt 12 — iOS 마감 품질
```text
iOS 출시를 위해 UI와 품질을 다듬어줘.

확인할 것:
- iPhone 작은 화면에서도 TimerScreen이 잘 보이는지
- 큰 글씨 접근성에서 레이아웃이 깨지지 않는지
- 버튼 터치 영역이 충분한지
- 오버타임과 패널티가 색상만이 아니라 텍스트로도 표현되는지
- 소리/진동 설정이 실제로 적용되는지
- 앱이 백그라운드로 갔다 돌아와도 경과 시간이 반영되는지
- 로컬 기록 삭제가 잘 되는지
- App Store 설명에 치료/진단 표현이 없는지

필요하면 위젯 테스트와 수동 테스트 체크리스트를 추가해줘.
```
