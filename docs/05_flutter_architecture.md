# 05. Flutter Architecture - v4

## 기술 선택
- Flutter + Cupertino UI
- 순수 Dart 타이머 엔진
- 로컬 JSON 저장소
- 외부 서버 없음

## 구조
```text
lib/
  main.dart
  features/
    settings/
    timer/
      domain/
    history/
```

## 앱 계층
- `CalmTurnApp`: 테마와 루트 주입
- `_CalmTurnRoot`: 설정 로드, 시작 화면, 고급설정, 기록 화면 라우팅
- `SessionSetupPage`: v4 시작 화면
- `SettingsScreen`: 고급설정
- `TimerHomePage`: 실행 화면과 마무리 진입
- `WrapUpPage`: 종료 후 기록 입력
- `HistoryScreen`, `HistoryDayScreen`, `HistoryDetailScreen`: 기록 보기

## 도메인 계층
- `TimerEngine`: 시간 흐름, 차례 넘김, 일시정지, 종료 이벤트를 담당한다.
- `SessionConfig`: 참가자, 총 발언시간, 턴 제한, 오버타임, 알림 설정 스냅샷이다.
- `TimerSnapshot`: 현재 상태를 UI에 전달한다.
- `TimerEvent`: 알림과 기록에 필요한 상태 변화를 표현한다.

## 저장소
- 설정은 `AppSettingsStore`를 통해 저장한다.
- 기록은 `SessionRecordStore`를 통해 저장한다.
- 웹/IO/테스트 저장소를 분리한다.
- 기록은 로컬에만 저장한다.

## UI 원칙
- 시작 화면에는 핵심 설정만 둔다.
- 고급설정은 별도 화면에 둔다.
- 실행 화면은 장식보다 터치 영역과 시간 가독성을 우선한다.
- 패널티/주의 문구는 실행 화면과 기본 기록 화면에 표시하지 않는다.
- 기록 상세에서는 참가자별 사용 시간을 확인할 수 있다.

## 테스트 전략
- 타이머 엔진은 순수 Dart 테스트로 검증한다.
- 설정 검증은 단위 테스트로 막는다.
- 시작/실행/마무리/기록 흐름은 Flutter 위젯 테스트로 검증한다.
- 릴리스 정체성은 `test/release_identity_test.dart`로 검증한다.
- 출시 전 기본 검증은 README의 명령 세트를 따른다.

## 유지보수 원칙
- UI 문구는 README와 `docs/10_copy_and_brand.md`를 기준으로 맞춘다.
- 시간 규칙은 `docs/11_time_rules.md`를 기준으로 맞춘다.
- 설정/알림 기본값은 `docs/12_settings_and_notifications.md`를 기준으로 맞춘다.
- 죽은 화면이나 테스트가 없는 보조 위젯은 남기지 않는다.
