# 오늘탈까

개인용 iPhone 자전거 라이딩 비서 앱 MVP.

핵심 흐름:

```text
오늘탈까 -> 라이딩 시작 -> GPS 기록 -> 오늘탔다 요약 -> 공유 카드
```

## 현재 구현

### 핵심
- SwiftUI iOS 앱 프로젝트: `TodayRiding.xcodeproj`
- 코어 Swift Package: `TodayRidingCore`
- 규칙 기반 라이딩 적합도 계산
- GPS 포인트 기반 거리/시간/속도 계산
- 파일 기반 로컬 저장: `FileRideStore`
- 저장된 라이딩 기록 리스트 (경로 썸네일 포함) + 요약 재진입

### 외부 연동 (키 없을 때 Mock fallback)
- 기상청 `KMAWeatherService` — 초단기실황 + 단기예보, 격자/풍향/체감온도/일몰
- 에어코리아 `AirKoreaService` — TM 좌표 변환 → 최근접 측정소 → PM10/2.5
- 홈 화면 좌표를 단발성 GPS 위치로 연동 (미승인 시 서울시청 기본 좌표)
- Supabase REST 업로드 (`HTTPSupabaseService`)
- 실패 분류 (`pending` 재시도 가능 vs `failed`)
- 앱 시작 시 미동기화 라이딩 자동 재시도 + 기록 화면 수동 재시도

### 공유 / 내보내기
- 공유 카드 미리보기 + 이미지 렌더링 + 사진 저장 + iOS 공유 시트
- GPX 1.1 내보내기 (요약 화면 `ShareLink`)

### 통계 / 코치 / 추천
- 월간/연간 리포트 (`RideStatisticsCalculator`, `ReportView`) — 전체/연/월 통계, 개인 기록, 연속 라이딩 스트릭
- AI 라이딩 코치 (`RidingCoach`) — 최근 통계 + 추천 점수로 톤별 코칭 카드 (홈 화면)
- 코스 추천 (`CourseSuggester`) — 과거 라이딩에서 최장/최근/최고속/자주 다닌 출발지 4개를 리포트 화면 하단에 노출

### 알림 / 백그라운드
- 매일 라이딩 리마인더 + 라이딩 중 비구름 접근 알림 (`NotificationManager`, `RainAlertEvaluator`)
- 백그라운드/잠금화면 위치 기록 (`UIBackgroundModes=location`)

### HealthKit
- 라이딩 종료 시 사이클링 워크아웃을 건강 앱에 저장 (`HealthKitWorkoutRecorder`)
- 홈 헤더 ❤️ 토글로 ON/OFF, 첫 ON 시 권한 요청

### CI / 테스트
- GitHub Actions (`.github/workflows/ci.yml`) — core validation + iOS Simulator build
- XCTest 단위 테스트: `Tests/TodayRidingCoreTests` (`swift test`)
- CLI 검증: `swift run TodayRidingValidation`

## 화면 테스트

Xcode 설치 후:

```sh
open /Volumes/Extreme_SSD/todayriding/TodayRiding.xcodeproj
```

Xcode에서:

1. Scheme: `TodayRiding`
2. Run destination: iPhone Simulator
3. Run

앱에서 확인할 흐름:

```text
홈 -> 라이딩 시작 -> + 버튼으로 Mock 위치 추가 -> 종료 -> 요약 -> 공유 카드 만들기
```

홈 헤더의 각 버튼:
- ❤️ 건강 앱 저장 토글 (HealthKit)
- 📊 리포트 보기 (월간/연간 통계 + 코스 추천)
- 🕐 기록 보기

## 웹 미리보기

Xcode 설치 전에도 기본 화면 흐름은 브라우저에서 확인할 수 있다.

```sh
open /Volumes/Extreme_SSD/todayriding/web-preview/index.html
```

또는:

```sh
cd /Volumes/Extreme_SSD/todayriding/web-preview
python3 -m http.server 8080
```

브라우저에서 `http://127.0.0.1:8080/index.html`.

웹 미리보기는 화면/상호작용 확인용이다. 실제 GPS, 사진 저장, Supabase 업로드, HealthKit, 알림은 iOS 앱에서 검증한다.

## 코어 검증

```sh
swift run TodayRidingValidation
swift test                       # XCTest 41+ cases
```

성공 시 `TodayRidingValidation passed` 및 `Executed N tests` 출력.

## Build Settings 주입

키는 Git에 커밋하지 않는다. Xcode `TodayRiding` target의 Build Settings에 사용자 정의 값으로 추가:

| 키 | 용도 | 부재 시 |
|----|------|--------|
| `TODAYRIDING_SUPABASE_URL` | Supabase project URL | 라이딩 로컬에만 저장, `pending` 상태 유지 |
| `TODAYRIDING_SUPABASE_ANON_KEY` | Supabase anon public key | 위와 동일 |
| `TODAYRIDING_KMA_API_KEY` | 기상청 단기예보 키 | Mock 날씨 데이터 사용 |
| `TODAYRIDING_AIRKOREA_API_KEY` | 에어코리아 API 키 | Mock 미세먼지 데이터 사용 |
| `TODAYRIDING_AIRKOREA_STATION` | (선택) 고정 측정소명 | 좌표 기반 자동 조회 |

Supabase 테이블은 `supabase/schema.sql` 기준으로 생성한다.

## 문서

- 작업 지침: `docs/instructions/`
- Xcode 설정: `docs/xcode-setup.md`
- 남은 작업 / 미완료 추적: `TODO.md`
