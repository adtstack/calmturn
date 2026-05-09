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
  features/
    session_setup/
      presentation/
      application/
      domain/
    timer/
      presentation/
      application/
      domain/
    history/
      presentation/
      application/
      domain/
      data/
    settings/
      presentation/
      application/
  shared/
    widgets/
    models/
```

## 3. 상태관리
권장: Riverpod

이유:
- 타이머 상태를 명확하게 관리하기 좋다.
- 테스트하기 쉽다.
- 기능별 provider를 분리하기 좋다.

대안:
- BLoC: 상태 전이가 복잡해질 경우 적합
- Provider: 단순하지만 확장성은 Riverpod보다 낮음

## 4. 로컬 저장
MVP 권장: Drift 또는 Hive

### Drift 장점
- SQLite 기반
- 기록 검색/정렬/마이그레이션에 강함
- 장기적으로 안정적

### Hive 장점
- 빠른 MVP 구현
- 모델 저장이 쉬움
- SQL을 몰라도 됨

권장 결정:
- 빠른 MVP: Hive
- 출시 후 확장 고려: Drift

## 5. 라우팅
권장: go_router

화면:
- `/` 홈
- `/session/new` 세션 설정
- `/session/consent` 동의
- `/session/timer` 타이머
- `/session/wrap-up` 종료 회고
- `/history` 기록 목록
- `/history/:id` 기록 상세
- `/settings` 설정

## 6. 핵심 도메인 모델
```dart
enum SessionStatus { draft, waitingConsent, running, paused, finished }
enum TimerMode { totalBank, round }

enum ActiveSpeaker { participantA, participantB, none }

class Participant {
  final String id;
  final String name;
}

class ConversationSession {
  final String id;
  final Participant participantA;
  final Participant participantB;
  final TimerMode mode;
  final Duration initialTimePerPerson;
  final DateTime createdAt;
}
```

## 7. 타이머 구현 원칙
- `Timer.periodic`만 믿지 말고 실제 시간 차이를 계산한다.
- 상태에는 `lastTickAt` 또는 `activeStartedAt`을 둔다.
- 앱이 잠깐 멈춰도 DateTime 기반으로 남은 시간을 복원한다.
- 타이머 로직은 UI와 분리한다.

## 8. 테스트 전략
### 단위 테스트
- 시작하면 A 시간이 줄어든다.
- 차례를 넘기면 B 시간이 줄어든다.
- 일시정지 중에는 시간이 줄어들지 않는다.
- 0초가 되면 종료 상태가 된다.

### 위젯 테스트
- 동의 버튼 2개가 눌려야 시작 버튼이 활성화된다.
- 휴식 버튼을 누르면 휴식 화면이 표시된다.
- 종료 후 회고 화면으로 이동한다.

### 수동 테스트
- 실제 iPhone에서 화면을 테이블 위에 놓고 조작
- 큰 글씨 모드
- VoiceOver
- 앱 백그라운드 복원

## 9. 추천 패키지
MVP 기준:
- `flutter_riverpod` — 상태관리
- `go_router` — 라우팅
- `hive` 또는 `drift` — 로컬 저장
- `path_provider` — 로컬 파일 경로
- `intl` — 날짜 포맷
- `uuid` — 세션 ID

주의:
- 분석/광고 SDK는 MVP에서 넣지 않는다.
- 녹음/마이크 권한은 MVP에서 요청하지 않는다.
- 불필요한 개인정보 권한은 요청하지 않는다.

## 10. iOS UI
- iOS 감성을 살리려면 Cupertino 위젯을 적극 사용한다.
- 단, Material 컴포넌트와 섞어도 문제는 없다.
- 핵심은 네이티브처럼 보이는 것보다 “대화 중 조작이 단순한 것”이다.

## 11. 개발 원칙
1. 타이머 엔진 먼저
2. UI는 단순하게
3. 로컬 저장은 나중에 붙이기
4. AI/녹음/클라우드는 금지
5. iOS 실제 기기 테스트를 초기에 시작
