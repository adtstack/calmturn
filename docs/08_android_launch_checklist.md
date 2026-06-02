# 08. Android / Google Play Launch Checklist

## 1. 개발 환경
- Android Studio 설치
- Flutter SDK
- Android SDK / command-line tools
- Google Play Console 계정, Play 배포 시 필요
- 실제 Android 테스트 기기

## 2. Flutter Android 준비
- Application ID 정하기
  - 확정: `me.newlines.calmturn`
- 앱 표시 이름 정하기
  - 확정: `말차례 CalmTurn`
- Android minSdk/targetSdk 결정
- 앱 아이콘 추가
- Splash screen 설정
- Release APK/AAB 빌드 테스트

## 3. v3 기능 기준 Android 테스트 항목
### 타이머
- 각자 같은 전체 시간으로 시작
- 각자 다른 전체 시간으로 시작
- 턴 제한 카운트다운
- 오버타임 카운트업
- 패널티 기준 1분 도달
- 패널티 기준 변경
- 휴식/재개
- 전체 시간 0 도달
- 시간 연장

### 알림
- 10초 전 화면 표시
- 10초 전 진동/햅틱
- 10초 전 소리
- 소리 끄기
- 진동 끄기
- 화면 표시만 사용
- 오버타임 시작 알림
- 패널티 도달 알림

### 기록
- 오버타임 합계 저장
- 패널티 횟수 저장
- 각자 다른 전체 시간 저장
- 알림 설정 저장
- [자동 검증] 기록 삭제와 모든 기록 삭제가 history store 회귀 테스트(`test/history/session_record_store_test.dart`)와 설정 화면 흐름에서 확인되는지 점검
- [수동 검증] 실제 Android 기기에서 삭제 후 앱 재시작 시 기록이 남지 않는지 확인

## 4. Google Play Console 준비
- 앱 생성
- Application ID 연결
- 카테고리 선택
- 가격 및 배포 국가 설정
- 개인정보 처리방침 URL 준비
- 지원 URL 준비
- 앱 설명, 짧은 설명, 키워드성 문구 작성
- 스크린샷 준비

## 5. 개인정보 제출 준비
MVP가 로컬 저장만 한다면 개인정보 설명이 단순해진다. 그래도 Play Console Data safety에는 앱과 서드파티 SDK가 수집하는 데이터를 정확히 입력해야 한다.

확인할 것:
- 분석 SDK를 넣었는가?
- 광고 SDK를 넣었는가?
- 서버로 세션 데이터를 보내는가?
- 사용자 메모를 외부로 전송하는가?
- 고객지원 폼이 이메일을 수집하는가?
- 마이크를 사용하는가?
- 음성 녹음을 하는가?

MVP 원칙:
- 마이크 사용 없음
- 음성 녹음 없음
- 자동 음성 인식 없음
- 위치 정보 없음
- 연락처 없음
- 광고 추적 없음

## 6. Android 내부 테스트
Google Play 내부 테스트 또는 직접 APK 설치 테스트에서는 다음을 확인한다.

- 부부/연인 사용자가 패널티 표현을 부담스러워하지 않는가?
- “오버타임 표시”와 “패널티” 중 어떤 표현을 선호하는가?
- 10초 전 알림이 도움이 되는가?
- 소리와 진동 중 어떤 방식을 선호하는가?
- 각자 다른 전체 시간 설정이 실제로 필요한가?
- 오버타임 1분 기준이 적절한가?
- 자동 전환보다 오버타임 방식이 자연스러운가?

## 7. 접근성
- [자동 검증] 큰 글씨에서도 Timer 화면 핵심 상태(A/B 차례, 오버타임, 주의 표시)가 보이는지 `test/app/timer_screen_test.dart` 위젯 테스트로 확인
- [자동 검증] 오버타임/주의 표시 상태가 색상뿐 아니라 화면 텍스트와 Semantics 라벨에 포함되는지 확인
- [수동 검증] 실제 Android TalkBack에서 타이머 영역 라벨이 자연스럽게 읽히는지 확인
- [자동/수동 검증] 버튼 터치 영역은 얼굴 방향 타이머 영역 위젯 테스트와 실제 기기 탭으로 확인
- [자동 검증] 소리/진동을 꺼도 화면 알림 fallback이 노출되는지 위젯 테스트로 확인
- [수동 검증] 실제 Android 기기에서 소리/진동/화면 알림 체감을 확인
- 오버타임과 패널티 상태를 텍스트로 표시하기

## 8. Google Play 설명 초안 기준
피해야 할 표현:
- 싸움을 해결합니다
- 관계를 치료합니다
- 감정을 분석합니다
- 상대의 잘못을 판정합니다
- 폭력 예방 도구입니다

권장 표현:
- 대화 시간을 나누는 타이머
- 서로의 차례를 지키는 대화 시계
- 턴 제한과 오버타임을 기록하는 앱
- 발언 시간과 휴식 시간을 정리하는 도구

## 9. 스크린샷 구성 추천
1. 홈: “말할 차례를 나눠볼까요?”
2. 설정: “각자의 전체 시간을 정해요”
3. 설정: “오버타임과 알림을 조절해요”
4. 타이머: “10초 남았습니다”
5. 타이머: “오버타임 +00:12”
6. Wrap-up: “오늘의 대화를 정리해요”

## 10. 출시 전 체크리스트
- [x] 제품명 확정: 말차례 CalmTurn
- [x] 앱 표시명 확정: 말차례 CalmTurn
- [ ] 개인정보 처리방침 작성
- [ ] 지원 URL 준비
- [ ] 앱 아이콘 제작
- [ ] 런치 화면 제작
- [ ] v3 타이머 엔진 단위 테스트 통과
- [ ] 실제 Android 기기에서 진동/소리 확인
- [ ] Google Play 설명 작성
- [ ] Android 내부 테스트 또는 APK/AAB 배포
- [ ] 베타 피드백 반영
- [ ] 스크린샷 제작
- [ ] Google Play 검토 제출

## 11. 현재 Android 스캐폴드 주의사항
현재 `android/` 폴더는 Android Studio에서 실행하고 APK/AAB 빌드를 확인하기 위한 초기 스캐폴드다. 출시 전에 아래 항목은 반드시 다시 결정하고 반영한다.

- [x] Application ID를 기본값 `com.example.calmturn`에서 실제 소유 도메인 기반 ID로 변경한다.
  - 확정값: `me.newlines.calmturn`
  - Google Play에 한 번 등록한 Application ID는 앱 정체성이 되므로 임시값으로 출시하지 않는다.
- [x] Android `namespace`와 Kotlin `MainActivity` 패키지 경로가 Application ID 정책과 맞는지 확인한다.
- [x] 앱 표시명을 최종 확정한다.
  - 확정값: `말차례 CalmTurn`
- [x] 기본 Flutter 런처 아이콘을 브랜드 아이콘으로 교체한다.
- [x] 기본 흰색/템플릿 런치 화면을 제품 톤에 맞는 Splash screen으로 교체한다.
- [x] Release 빌드에서 debug signing을 제거하고 `android/key.properties` 기반 release signing config를 추가한다.
  - 실제 업로드 전에는 release keystore를 생성하고 `android/key.properties`를 로컬에 준비한다.
- [ ] `versionCode`와 `versionName` 증가 규칙을 정한다.
- [ ] `minSdk`와 `targetSdk`가 Google Play 요구사항과 실제 테스트 기기 범위에 맞는지 확인한다.
- [ ] Android SDK `cmdline-tools`가 설치되어 있고 `flutter doctor`에서 Android toolchain이 통과하는지 확인한다.
- [ ] Android SDK 라이선스가 모두 수락되어 있는지 확인한다.
- [ ] 진동, 소리, 화면 알림을 실제 Android 기기에서 확인한다.
- [ ] 권한 목록을 점검하고 불필요한 권한이 추가되지 않았는지 확인한다.
- [ ] 개인정보 처리방침 URL과 지원 URL을 준비한다.
- [ ] Google Play Data safety 답변을 MVP 원칙에 맞게 작성한다.
- [ ] 내부 테스트 트랙에 AAB를 올리기 전에 APK 직접 설치 테스트를 먼저 수행한다.
