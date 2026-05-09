# 말차례 CalmTurn 제품 문서팩 v3

## 한 줄 정의
말차례 CalmTurn은 두 사람이 **서로 동의한 전체 발언 시간**을 가지고, 각 차례마다 **턴당 발언 제한**을 적용하며, 시간을 넘겼을 때 **오버타임과 패널티**를 기록하는 대화 타이머 앱입니다.

## v3에서 확정된 핵심 변경
v2까지의 핵심은 “공평한 전체 시간 + 턴당 제한 + 번갈아 말하기”였습니다. v3에서는 실제 대화 상황을 반영해 다음 규칙을 추가합니다.

1. **전체 발언 시간은 무조건 동일하지 않아도 된다.**
   - 기본값은 동일 시간입니다.
   - 사용자가 합의하면 A 5분, B 10분처럼 각자 다르게 설정할 수 있습니다.
   - 이 제품에서 공평함은 “항상 같은 시간”이 아니라 “서로 동의한 시간이 투명하게 보이는 것”입니다.

2. **턴 시간이 끝나도 바로 자동 전환하지 않는다.**
   - 기본 동작은 오버타임 진입입니다.
   - 현재 발언자가 차례 넘기기를 누르지 않으면 오버타임이 계속 측정됩니다.
   - 다음 사람이 말을 시작했더라도 버튼을 누르지 않으면 앱 기준으로는 이전 발언자의 오버타임으로 기록됩니다.

3. **오버타임은 설정 가능하다.**
   - 오버타임 사용 여부
   - 패널티 발생 기준 시간
   - 기본값: 오버타임 1분 이상이면 패널티 1회
   - 반복 패널티 여부
   - 강제 일시정지 또는 자동 전환 같은 엄격한 동작은 후속 버전 옵션으로 둡니다.

4. **10초 전 알림은 설정 가능하다.**
   - 기본값: 턴 시간이 10초 남았을 때 알림
   - 전체 발언 시간이 10초 남았을 때도 알림 가능
   - 알림 방식: 화면 표시, 소리, 진동/햅틱 중 선택 가능

## 핵심 시간 모델
| 개념 | 의미 | 기본값 | 설정 가능 여부 |
|---|---|---:|---|
| 전체 발언 시간 | 각 사람이 대화 전체에서 쓸 수 있는 총 말하기 시간 | 각자 5분 | 가능, 각자 다르게 가능 |
| 턴당 발언 제한 | 한 번의 차례에서 말할 수 있는 기본 제한 시간 | 1분 | 가능 |
| 오버타임 | 턴 시간이 끝난 뒤 차례 넘기기를 누르지 않은 시간 | 켜짐 | 가능 |
| 패널티 기준 | 오버타임이 이 시간 이상이면 패널티 발생 | 1분 | 가능 |
| 사전 알림 | 시간이 얼마 남았을 때 알려줄지 | 10초 | 가능 |
| 알림 방식 | 화면/소리/진동 중 어떤 방식으로 알릴지 | 화면+진동 | 가능 |

## 문서 구성
1. `00_product_brief.md` — 제품 개요, 이름, 포지셔닝
2. `01_prd.md` — PRD 본문
3. `02_mvp_scope.md` — MVP 범위와 단계별 로드맵
4. `03_user_flows.md` — 사용자 흐름과 화면 IA
5. `04_screen_specs.md` — 화면별 상세 스펙
6. `05_flutter_architecture.md` — Flutter 개발 구조와 기술 설계
7. `06_data_model_and_timer_engine.md` — 데이터 모델과 타이머 엔진
8. `07_safety_privacy.md` — 안전·윤리·개인정보 원칙
9. `08_ios_launch_checklist.md` — iPhone/App Store 출시 체크리스트
10. `09_vibe_coding_prompts.md` — 차근차근 개발하기 위한 프롬프트 세트
11. `10_copy_and_brand.md` — 앱 문구, 온보딩, 앱스토어 문구 초안
12. `11_time_rules.md` — 전체 시간, 턴 제한, 오버타임, 패널티 규칙
13. `12_settings_and_notifications.md` — 설정값과 알림 정책

## 권장 첫 실행 순서
1. `11_time_rules.md`에서 시간 규칙을 먼저 확정합니다.
2. `12_settings_and_notifications.md`에서 설정값 기본값을 확인합니다.
3. `01_prd.md`로 제품 범위와 요구사항을 확인합니다.
4. `06_data_model_and_timer_engine.md`를 기준으로 타이머 엔진을 구현합니다.
5. `09_vibe_coding_prompts.md`의 Prompt 0부터 순서대로 개발합니다.
6. TestFlight 전에는 `07_safety_privacy.md`와 `08_ios_launch_checklist.md`를 다시 확인합니다.

## 공식 참고 자료
- Flutter iOS 배포 문서: https://docs.flutter.dev/deployment/ios
- Flutter Cupertino widgets: https://docs.flutter.dev/ui/widgets/cupertino
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple TestFlight/App Store 제출 안내: https://developer.apple.com/app-store/submitting/
