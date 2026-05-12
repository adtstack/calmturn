# 12. Settings & Notifications

## 1. 이 문서의 목적
이 문서는 말차례 CalmTurn v3의 설정값과 알림 정책을 정리한다. 개발 중 기본값, 사용자 설정, 저장 항목, 이벤트 처리 기준이 헷갈리면 이 문서를 기준으로 삼는다.

## 2. 설정 그룹
설정은 네 그룹으로 나눈다.

1. 시간 설정
2. 오버타임 설정
3. 패널티 설정
4. 알림 설정

## 3. 시간 설정
### 3.1 전체 발언 시간 모드
| 값 | 설명 | 기본값 |
|---|---|---|
| same | 두 사람이 같은 전체 시간을 가진다 | 기본 |
| customPerParticipant | 각자 다른 전체 시간을 가진다 | 선택 |

### 3.2 전체 발언 시간 기본값
| 항목 | 값 |
|---|---:|
| 기본 전체 시간 | 각자 5분 |
| 최소 권장값 | 1분 |
| 최대 권장값 | 30분 |
| 직접 입력 | 가능 |

### 3.3 턴당 발언 제한 기본값
| 항목 | 값 |
|---|---:|
| 기본 턴 제한 | 1분 |
| 프리셋 | 30초, 45초, 1분, 1분 30초, 2분 |
| 직접 입력 | 가능 |

## 4. 오버타임 설정
### 4.1 기본값
| 설정 | 기본값 | 설명 |
|---|---:|---|
| 오버타임 사용 | 켜짐 | 턴 시간이 끝난 뒤 초과 시간을 잼 |
| 오버타임 표시 | 켜짐 | 화면에 +00:00 표시 |
| 턴 종료 동작 | 오버타임 | 기본은 오버타임, 오버타임 OFF 시 자동 휴식 |

### 4.2 오버타임 사용 방식
기본 방식:
```text
턴 시간이 0이 됨
=> 오버타임 시작
=> 차례 넘기기를 누를 때까지 증가
```

MVP 결정:
- 기본은 오버타임
- 오버타임을 끄면 자동 휴식

후속 옵션:
- 자동 전환
- 오버타임 최대 허용 시간 후 자동 휴식

## 5. 패널티 설정
### 5.1 기본값
| 설정 | 기본값 | 설명 |
|---|---:|---|
| 패널티 사용 | 켜짐 | 오버타임 기준 도달 시 기록 |
| 패널티 기준 | 1분 | 오버타임 60초 이상 |
| 반복 패널티 | 꺼짐 | 한 턴에 1회만 |
| 표시 명칭 | 오버타임 표시 | 부드러운 표현 우선 |

### 5.2 패널티 기준 옵션
- 15초
- 30초
- 1분
- 2분
- 3분
- 직접 입력

### 5.3 반복 패널티
꺼짐:
```text
한 턴에서 오버타임이 기준을 넘으면 패널티 1회만 기록
```

켜짐:
```text
오버타임이 기준 시간만큼 늘어날 때마다 패널티 추가 기록
```

예:
```text
기준 60초, 반복 켜짐
60초 = 1회
120초 = 2회
180초 = 3회
```

### 5.4 표시 명칭
사용자에게 보여줄 명칭은 설정 가능하게 둘 수 있다.

옵션:
- 오버타임 표시
- 주의 표시
- 패널티

권장 기본값은 “오버타임 표시”다.

## 6. 알림 설정
### 6.1 기본값
| 설정 | 기본값 |
|---|---:|
| 사전 알림 시점 | 10초 전 |
| 턴 시간 알림 | 켜짐 |
| 전체 시간 알림 | 켜짐 |
| 오버타임 시작 알림 | 켜짐 |
| 패널티 도달 알림 | 켜짐 |
| 화면 표시 | 켜짐 |
| 소리 | 꺼짐 또는 부드러운 소리 |
| 진동/햅틱 | 켜짐 |

## 7. 알림 대상
### 7.1 턴 시간 종료 전 알림
조건:
```text
currentTurnRemainingSeconds == warningBeforeSeconds
```

문구:
```text
10초 남았습니다.
```

### 7.2 전체 발언 시간 종료 전 알림
조건:
```text
active.totalRemainingSeconds == warningBeforeSeconds
```

문구:
```text
전체 시간이 10초 남았습니다.
```

### 7.3 오버타임 시작 알림
조건:
```text
currentTurnRemainingSeconds == 0
phase changes to Running.Overtime
```

문구:
```text
오버타임이 시작됐어요.
```

### 7.4 패널티 기준 도달 알림
조건:
```text
currentTurnOvertimeSeconds >= penaltyThresholdSeconds
```

문구:
```text
오버타임 기준에 도달했어요.
```

## 8. 알림 방식
### 8.1 화면 표시
- 배너
- 짧은 텍스트
- 숫자 강조
- 카드 테두리 강조

화면 표시는 접근성과 안전을 위해 기본 켜짐으로 둔다.

### 8.2 소리
- 부드러운 소리
- 짧은 소리
- 무음

소리는 갈등 상황에서 자극적일 수 있으므로 사용자가 쉽게 끌 수 있어야 한다.

### 8.3 진동/햅틱
- 약함
- 기본
- 강함
- 꺼짐

기기에서 지원하지 않으면 아무 동작을 하지 않고 화면 표시로 대체한다.

## 9. 알림 중복 방지
같은 이벤트는 한 번만 실행한다.

예시 이벤트 키:
```text
turn-warning:{sessionId}:{turnId}:{participantId}
total-warning:{sessionId}:{participantId}:{remainingSeconds}
overtime-start:{sessionId}:{turnId}:{participantId}
penalty:{sessionId}:{turnId}:{participantId}:{penaltyIndex}
```

## 10. 설정 저장
저장해야 할 앱 기본 설정:
- defaultTotalTimeMode
- defaultTotalSeconds
- defaultTurnLimitSeconds
- overtimeEnabled
- overtimeVisible
- penaltyEnabled
- penaltyThresholdSeconds
- penaltyRepeatMode
- penaltyLabelMode
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

## 11. 세션별 설정 스냅샷
세션이 시작되면 앱 기본 설정을 복사해 세션 설정으로 저장한다. 세션 중 앱 설정을 바꿔도 이미 진행 중인 세션에는 자동 적용하지 않는다. 진행 중 설정 변경은 별도 기능으로 다룬다.

## 12. 권장 기본 설정 JSON 예시
```json
{
  "defaultTotalTimeMode": "same",
  "defaultTotalSeconds": 300,
  "defaultTurnLimitSeconds": 60,
  "overtimeEnabled": true,
  "overtimeVisible": true,
  "penaltyEnabled": true,
  "penaltyThresholdSeconds": 60,
  "penaltyRepeatMode": "oncePerTurn",
  "penaltyLabelMode": "overtimeMark",
  "warningBeforeSeconds": 10,
  "turnWarningEnabled": true,
  "totalWarningEnabled": true,
  "overtimeStartAlertEnabled": true,
  "penaltyAlertEnabled": true,
  "visualEnabled": true,
  "soundEnabled": false,
  "hapticEnabled": true,
  "soundType": "soft",
  "hapticStrength": "medium"
}
```

## 13. 테스트 체크리스트
- [ ] 10초 전 턴 알림이 한 번만 발생한다.
- [ ] 10초 전 전체 시간 알림이 한 번만 발생한다.
- [ ] 소리를 끄면 소리가 나지 않는다.
- [ ] 진동을 끄면 진동이 발생하지 않는다.
- [ ] 화면 표시를 끄면 배너가 나오지 않는다.
- [ ] 오버타임 시작 알림이 설정값을 따른다.
- [ ] 패널티 알림이 설정값을 따른다.
- [ ] 패널티 기준을 30초로 바꾸면 30초에 발생한다.
- [ ] 반복 패널티를 켜면 기준마다 발생한다.
- [ ] 반복 패널티를 끄면 한 턴에 한 번만 발생한다.
