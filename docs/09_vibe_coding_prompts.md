# 09. Step-by-step Vibe Coding Prompts

이 문서는 앱을 한 번에 만들라고 시키지 않고, 작은 단위로 안정적으로 만들어가기 위한 프롬프트 모음이다. 각 단계가 끝나면 실행, 테스트, 커밋을 하고 다음 단계로 넘어간다.

## 공통 규칙 프롬프트
```text
너는 Flutter 시니어 개발자다. 앱 이름은 말차례다. 이 앱은 두 사람이 체스 시계처럼 말할 시간을 나누는 대화 타이머다.

중요 원칙:
- MVP는 로그인, 클라우드, 녹음, AI, 결제 없이 만든다.
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
  features/
    session_setup/
    timer/
    history/
    settings/
  shared/

test/
  timer/

패키지는 우선 flutter_riverpod, go_router, uuid, intl만 추가해줘. 로컬 저장은 아직 넣지 마.
앱 첫 화면에는 “말차례” 제목과 “새 대화 시작”, “5분씩 빠른 시작” 버튼만 표시해줘.
```

## Prompt 1 — 타이머 도메인 모델
```text
UI를 건드리지 말고 타이머 도메인 모델만 만들어줘.

필요한 모델:
- Participant
- ConversationSession
- TimerState
- SessionStatus: draft, waitingConsent, running, paused, finished
- ActiveSpeaker: participantA, participantB, none

총량 모드만 구현해줘. 각 참가자는 initialTime과 remainingTime을 가져야 해.
```

## Prompt 2 — 타이머 엔진 구현
```text
TimerEngine 클래스를 만들어줘.

필요 메서드:
- start(activeSpeaker)
- switchSpeaker()
- pause()
- resume()
- finish()
- getCurrentState(now)

중요:
Timer.periodic에 의존해 시간을 깎지 말고, activeStartedAt과 now의 차이로 남은 시간을 계산해줘.
```

## Prompt 3 — 단위 테스트
```text
TimerEngine에 대한 단위 테스트를 작성해줘.

테스트 케이스:
1. A가 30초 말하면 A의 시간이 30초 줄어든다.
2. A에서 B로 전환하면 이후 B의 시간이 줄어든다.
3. pause 상태에서는 시간이 줄어들지 않는다.
4. resume 이후 시간이 다시 줄어든다.
5. 시간이 0이 되면 timeExpired 또는 finished 상태로 전환된다.
```

## Prompt 4 — 세션 설정 화면
```text
세션 설정 화면을 만들어줘.

필드:
- 참가자 A 이름, 기본값 “나”
- 참가자 B 이름, 기본값 “상대”
- 시간 프리셋: 각 3분, 5분, 10분, 15분
- 대화 유형: 부부/연인, 가족, 회의, 토론, 직접 설정

저장 버튼을 누르면 동의 화면으로 이동하게 해줘.
```

## Prompt 5 — 동의 화면
```text
동의 화면을 만들어줘.

표시할 규칙:
- 말하는 사람의 시간이 줄어듭니다.
- 말이 끝나면 차례를 넘겨주세요.
- 누구든 휴식을 누를 수 있습니다.
- 이 앱은 승패를 정하지 않습니다.

참가자 A 동의 버튼과 참가자 B 동의 버튼이 모두 눌려야 “시작” 버튼이 활성화되게 해줘.
```

## Prompt 6 — 타이머 화면
```text
타이머 화면을 만들어줘.

요구사항:
- 화면을 두 참가자 영역으로 나눠줘.
- 각 영역에 이름과 남은 시간을 크게 보여줘.
- 현재 말하는 사람을 시각적으로 강조해줘.
- “차례 넘기기”, “휴식”, “종료” 버튼을 제공해줘.
- 시간이 10초 이하가 되면 텍스트로 “곧 시간이 끝나요”를 표시해줘.
```

## Prompt 7 — 휴식 모드
```text
휴식 모드를 구현해줘.

휴식 버튼을 누르면 타이머가 멈추고 다음 문구를 보여줘.
“잠깐 쉬어도 괜찮아요. 지금은 해결보다 진정이 먼저일 수 있어요.”

재개 버튼을 누르면 원래 발언자부터 다시 시작하게 해줘.
종료 버튼도 제공해줘.
```

## Prompt 8 — 종료 회고 화면
```text
종료 회고 화면을 만들어줘.

필드:
- 오늘 합의한 것
- 아직 남은 것
- 다음에 이야기할 것

저장 버튼을 누르면 홈으로 돌아가게 해줘.
아직 로컬 저장은 구현하지 말고, 콘솔에 결과를 출력해줘.
```

## Prompt 9 — 로컬 저장
```text
세션 기록을 로컬에 저장해줘.

저장할 데이터:
- id
- 날짜
- 참가자 이름
- 각자 사용 시간
- 휴식 횟수
- 회고 메모 3개

MVP에는 Hive를 사용해줘. 기록 목록과 기록 상세 화면도 만들어줘.
```

## Prompt 10 — iOS polish
```text
iPhone 출시를 고려해 UI를 다듬어줘.

요구사항:
- 큰 글씨에서도 레이아웃이 깨지지 않게 해줘.
- 버튼 터치 영역을 충분히 크게 해줘.
- VoiceOver label을 주요 버튼에 추가해줘.
- 앱이 백그라운드에 갔다 돌아와도 타이머 상태가 복원되게 점검해줘.
```

## Prompt 11 — App Store 준비
```text
App Store 제출 전 점검을 도와줘.

확인할 것:
- 앱 표시 이름
- Bundle ID
- 앱 아이콘
- Launch screen
- 개인정보 처리방침 링크가 들어갈 위치
- 지원 URL이 필요한 위치
- 심사용 데모 시나리오
- 앱 설명에 치료/진단/보장 표현이 없는지
```

## 커밋 메시지 예시
- `feat: add timer domain models`
- `test: cover timer engine state transitions`
- `feat: add consent screen`
- `feat: implement break mode`
- `feat: persist session history locally`
- `chore: prepare iOS release metadata`

## 개발 중 계속 물어볼 질문
1. 이 기능이 대화를 더 안전하게 만드는가?
2. 이 기능이 한 사람의 통제 도구가 될 위험은 없는가?
3. 이 기능을 빼도 MVP 검증이 가능한가?
4. 이 데이터는 꼭 저장해야 하는가?
5. App Store 설명에서 과장된 약속을 하고 있지 않은가?
