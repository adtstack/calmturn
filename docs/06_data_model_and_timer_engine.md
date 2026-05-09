# 06. Data Model & Timer Engine

## 1. 핵심 개념
말차례의 핵심은 “현재 발언자에게만 시간이 흐른다”는 것이다. 체스 시계와 유사하지만, 승패가 아니라 대화의 균형을 위한 것이다.

## 2. 상태 머신
```text
Draft
  -> WaitingConsent
  -> Running
  -> Paused
  -> Running
  -> Finished
```

## 3. 상태 설명
### Draft
세션이 설정 중이다.

### WaitingConsent
두 사람이 규칙에 동의하는 단계다.

### Running
한 사람의 타이머가 흐르고 있다.

### Paused
휴식 또는 일시정지 상태다.

### Finished
세션이 종료되었고 기록이 저장될 수 있다.

## 4. 데이터 모델 초안
```dart
class SessionRecord {
  final String id;
  final String type;
  final String participantAName;
  final String participantBName;
  final int initialSecondsPerPerson;
  final int remainingSecondsA;
  final int remainingSecondsB;
  final int usedSecondsA;
  final int usedSecondsB;
  final int pauseCount;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? agreementNote;
  final String? unresolvedNote;
  final String? nextTopicNote;
}
```

## 5. 이벤트 모델
```dart
enum TimerEventType {
  sessionStarted,
  speakerSwitched,
  paused,
  resumed,
  timeExpired,
  sessionFinished,
}

class TimerEvent {
  final TimerEventType type;
  final DateTime timestamp;
  final String? speakerId;
}
```

## 6. 타이머 계산 방식
### 나쁜 방식
매초 `remainingSeconds -= 1`만 하는 방식.

문제:
- 앱이 버벅이면 오차가 생긴다.
- 백그라운드 복원이 어렵다.

### 좋은 방식
활성 발언자가 시작한 시각을 저장하고, 현재 시각과의 차이로 남은 시간을 계산한다.

```dart
Duration calculateRemaining({
  required Duration baseRemaining,
  required DateTime activeStartedAt,
  required DateTime now,
}) {
  final elapsed = now.difference(activeStartedAt);
  final remaining = baseRemaining - elapsed;
  return remaining.isNegative ? Duration.zero : remaining;
}
```

## 7. 기본 규칙
1. 시작 시 기본 발언자는 사용자가 선택하거나 A로 시작한다.
2. 발언자 전환 시 현재 발언자의 남은 시간을 확정 저장한다.
3. 일시정지 시 현재 발언자의 남은 시간을 확정하고 activeSpeaker를 none으로 둔다.
4. 재개 시 activeStartedAt을 새로 설정한다.
5. 한 사람의 시간이 0이 되면 앱은 자동으로 종료 또는 추가 시간 선택을 안내한다.

## 8. 추가 시간 정책
MVP 기본:
- 추가 시간은 양쪽 동의 필요
- 1분, 3분, 5분 옵션
- 추가된 시간은 양쪽에 동일하게 부여

## 9. 총량 모드
각자에게 총 발언 시간이 주어진다.

예:
- A 5분
- B 5분
- A가 2분 말하고 넘김
- B가 1분 말하고 넘김
- A는 3분 남음, B는 4분 남음

장점:
- 체스 시계와 가장 유사
- 구현이 단순
- 싸움/회의 모두에 적합

## 10. 라운드 모드
각 라운드마다 발언 시간이 정해진다.

예:
- 1라운드: A 2분, B 2분
- 2라운드: A 2분, B 2분

장점:
- 토론에 적합
- 한 사람이 시간을 몰아서 쓰는 것을 방지

MVP는 총량 모드만 구현하고, 라운드 모드는 v1.1로 미뤄도 된다.

## 11. 테스트 케이스
### Case 1: 기본 시작
- Given A/B 각 5분
- When A가 시작하고 30초 후 전환
- Then A는 4분 30초, B는 5분

### Case 2: 일시정지
- Given A가 말하는 중
- When 20초 후 일시정지하고 1분 대기
- Then A의 시간은 추가로 줄어들지 않음

### Case 3: 재개
- Given 일시정지 상태
- When 재개 후 A가 10초 말함
- Then A의 시간이 10초 줄어듦

### Case 4: 시간 종료
- Given A에게 5초 남음
- When 6초 경과
- Then A의 남은 시간은 0, 상태는 timeExpired

## 12. 오류 방지
- 종료된 세션은 재개할 수 없다.
- 시간이 0인 사람은 발언자로 설정하지 않는다.
- 앱 종료 후 복원 시, paused 상태였으면 시간이 흐르지 않아야 한다.
- running 상태에서 앱이 백그라운드에 갔다 돌아오면 실제 경과 시간을 반영한다.
