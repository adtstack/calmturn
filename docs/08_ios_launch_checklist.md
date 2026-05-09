# 08. iOS / App Store Launch Checklist

## 1. 개발 환경
- macOS 기기
- Xcode 설치
- Flutter SDK
- Apple Developer Program 가입
- 실제 iPhone 테스트 기기

## 2. Flutter iOS 준비
- Bundle ID 정하기
  - 예: `com.yourcompany.malcharye`
- 앱 표시 이름 정하기
  - 예: `말차례`
- iOS 최소 버전 결정
- 앱 아이콘 추가
- Launch screen 설정
- Release 빌드 테스트

## 3. App Store Connect 준비
- 앱 레코드 생성
- Bundle ID 연결
- 카테고리 선택
- 가격 및 배포 국가 설정
- 개인정보 처리방침 URL 준비
- 지원 URL 준비
- 앱 설명, 부제, 키워드 작성
- 스크린샷 준비

## 4. 개인정보 제출 준비
MVP가 로컬 저장만 한다면 개인정보 설명이 단순해진다. 그래도 App Store Connect에는 앱과 서드파티 SDK가 수집하는 데이터를 정확히 입력해야 한다.

확인할 것:
- 분석 SDK를 넣었는가?
- 광고 SDK를 넣었는가?
- 서버로 세션 데이터를 보내는가?
- 사용자 메모를 외부로 전송하는가?
- 고객지원 폼이 이메일을 수집하는가?

## 5. TestFlight
- 내부 테스터 추가
- 외부 테스터 그룹 만들기
- 피드백 질문 준비
- 크래시와 사용성 문제 수집

## 6. 심사 리스크 체크
### 안전
- 앱이 폭력적 상황에서 사용을 계속하라고 유도하지 않는가?
- 위험하면 멈추라는 안내가 있는가?

### 의료/상담 오해
- 치료, 진단, 심리 분석을 주장하지 않는가?
- 관계 개선을 보장하지 않는가?

### 사용자 생성 콘텐츠
- 사용자가 만든 콘텐츠를 온라인에 게시하는 기능이 있는가?
- 있다면 신고/차단/문의 기능이 필요한가?
- MVP에서는 온라인 공유를 제외하는 것이 안전하다.

### 앱 완성도
- 더미 텍스트가 남아 있지 않은가?
- 모든 버튼이 동작하는가?
- 앱이 크래시 없이 실행되는가?
- 심사용 데모 방법을 설명했는가?

## 7. 스크린샷 구성
1. 홈 — “말할 차례를 나눠볼까요?”
2. 동의 — “두 사람이 모두 동의해야 시작돼요.”
3. 타이머 — “각자의 시간이 공평하게 보여요.”
4. 휴식 — “잠깐 쉬어도 괜찮아요.”
5. 회고 — “오늘의 작은 합의를 남겨요.”

## 8. App Store 설명 초안
### 제목
말차례 — 대화 시간을 나누는 타이머

### 부제
서로의 말할 시간을 지켜주는 대화 시계

### 설명
말차례는 체스 시계처럼 두 사람의 대화 시간을 공평하게 나눠주는 앱입니다. 말이 겹치거나 한쪽이 오래 말할 때, 화면을 보며 차례를 넘기고 잠깐 쉬어갈 수 있습니다.

부부, 연인, 가족, 친구, 동료와의 민감한 대화부터 회의와 토론까지 사용할 수 있습니다.

주요 기능:
- 두 사람의 발언 시간을 나눠주는 대화 타이머
- 양쪽 동의 후 시작
- 차례 넘기기
- 휴식 모드
- 대화 후 합의와 남은 주제 기록
- 기본 로컬 저장

말차례는 상담이나 치료 앱이 아닙니다. 관계를 진단하거나 결과를 보장하지 않습니다. 위험하거나 불편한 상황에서는 대화를 멈추고 안전을 우선하세요.

## 9. 심사 노트 초안
This app is a two-person conversation timer. It helps users split speaking time fairly, similar to a chess clock, but it does not provide medical, therapeutic, diagnostic, or counseling services. The app does not record audio and stores session notes locally by default.

Suggested demo:
1. Open the app.
2. Tap Quick Start.
3. Tap consent for both participants.
4. Start the timer and switch turns.
5. Use Break.
6. End session and save a short note.

## 10. 출시 후 체크
- 첫 주 크래시 모니터링
- 리뷰에서 “통제적이다/차갑다” 피드백 확인
- 실제 사용 세션 완료율 확인
- 사용자들이 어떤 프리셋을 많이 쓰는지 확인
- 안전 관련 불편 신고가 있는지 확인
