# 말차례 / CalmTurn 제품 문서팩

## 한 줄 정의
말차례는 체스 시계처럼 대화 시간을 공평하게 나누어, 말이 겹치거나 한쪽이 독점하지 않도록 돕는 2인 대화 타이머 앱입니다.

## 핵심 관점
이 제품은 “싸움에서 이기기”가 아니라 “서로 말할 공간을 확보하기” 위한 도구입니다. 따라서 디자인, 카피, 기능명은 경쟁·승패·판정이 아니라 차례·휴식·합의·존중을 중심으로 잡습니다.

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

## 권장 첫 실행 순서
1. `01_prd.md`를 읽고 제품의 목적과 비목표를 확정합니다.
2. `02_mvp_scope.md`에서 “v0.1 앱” 범위를 고정합니다.
3. `09_vibe_coding_prompts.md`의 Prompt 0부터 순서대로 구현합니다.
4. TestFlight 전에는 `07_safety_privacy.md`와 `08_ios_launch_checklist.md`를 다시 확인합니다.

## 공식 참고 자료
- Flutter iOS 배포 문서: https://docs.flutter.dev/deployment/ios
- Flutter Cupertino widgets: https://docs.flutter.dev/ui/widgets/cupertino
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple TestFlight/App Store 제출 안내: https://developer.apple.com/app-store/submitting/
