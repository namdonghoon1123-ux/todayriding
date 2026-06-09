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

## 테스트 / 검증 가이드

Xcode 없이 가능한 것 vs 꼭 필요한 것을 구분해두자.

### Xcode 없이 가능

| 무엇 | 명령 | 검증 범위 |
|------|------|----------|
| 코어 로직 단위 테스트 | `swift test` | 57+ XCTest cases (Tracker, FileStore, Sync, GPX, Statistics, Coach, Suggester, KMA grid/solar/TM, 강수 알림 평가 등) |
| End-to-end 흐름 (CLI) | `swift run TodayRidingValidation` | 위 검증의 CLI 형태 + 의도적인 회귀 픽스처 |
| 화면 흐름 미리보기 | `open web-preview/index.html` | 라이딩 시작→트래킹→요약→공유→기록 |
| 새 기능 미리보기 | `open web-preview/extras.html` | 코치 카드 4톤, 리포트, 코스 추천, HealthKit 토글 |

### Xcode / 시뮬레이터 필요

- iOS 앱 빌드 (`xcodebuild ... -sdk iphonesimulator`)
- SwiftUI 화면 라이브 미리보기
- `RideTrackingViewModel` 통합 (LocationManager + WeatherService + HealthKit)

### 실기기 필요

- GPS 추적 정확도
- 백그라운드/잠금화면 위치 기록
- 사진 라이브러리 저장 + iOS 공유 시트
- HealthKit 사이클링 워크아웃 저장
- 로컬 알림 수신 (매일 7시 / 강수확률 상승)

### CI (GitHub Actions)

`.github/workflows/ci.yml` 가 PR/푸시마다 자동 실행:
1. **Core validation (macOS)** — `swift test` + `swift run TodayRidingValidation`
2. **Core validation (Linux)** — Ubuntu container의 `swift:6.0-jammy`로 같은 검증 (코어가 macOS 외 플랫폼에서도 빌드되는지 보증)
3. **iOS Simulator build** — `xcodebuild` 시뮬레이터 빌드 (서명 없이)

CI 통과 = 화면 외 모든 로직이 정상.

## Build Settings 주입

키는 Git에 커밋하지 않는다. Xcode `TodayRiding` target의 Build Settings에 사용자 정의 값으로 추가:

| 키 | 용도 | 부재 시 |
|----|------|--------|
| `TODAYRIDING_SUPABASE_URL` | Supabase project URL | 라이딩 로컬에만 저장, `pending` 상태 유지 |
| `TODAYRIDING_SUPABASE_ANON_KEY` | Supabase anon public key | 위와 동일 |
| `TODAYRIDING_KMA_API_KEY` | 기상청 단기예보 키 | Mock 날씨 데이터 사용 |
| `TODAYRIDING_AIRKOREA_API_KEY` | 에어코리아 API 키 | Mock 미세먼지 데이터 사용 |
| `TODAYRIDING_AIRKOREA_STATION` | (선택) 고정 측정소명 | 좌표 기반 자동 조회 |

```text
TodayRidingValidation passed
```

## Supabase 설정 (멀티 사용자)

오늘탈까는 **Supabase Auth 이메일/패스워드 로그인**을 통해 여러 사용자가 한 프로젝트를 공유할 수 있다. 각자 자기 라이딩만 보고/쓸 수 있도록 PostgreSQL **Row Level Security**가 적용된다.

### 1. 스키마 적용

Supabase 대시보드 → SQL Editor에 `supabase/schema.sql` 전체를 붙여넣고 Run.

생성/적용 내역:
- `rides`, `ride_points`, `ride_photos` 세 테이블 모두 `user_id uuid not null references auth.users(id) on delete cascade`
- 세 테이블 `enable row level security` + `auth.uid() = user_id` 정책

### 2. Build Settings 키 주입

Xcode `TodayRiding` target → Build Settings에:

- `TODAYRIDING_SUPABASE_URL`: 예 `https://xxxx.supabase.co`
- `TODAYRIDING_SUPABASE_ANON_KEY`: **publishable** key (절대 secret key 아님)

키는 Git에 커밋하지 않는다. **service_role secret key는 iOS 앱에 절대 넣지 말 것** — RLS를 우회한다.

### 3. 사용자 추가

앱 첫 실행 시 회원가입 화면이 뜬다. 함께 쓸 두 분이 각자 이메일/비밀번호로 가입하면 끝.

Supabase 대시보드 → Authentication → Users 에서 가입 현황을 볼 수 있다.

### 4. 동작

- 로그인 안 한 상태: 라이딩은 **로컬에만** 저장되고 `pending` 유지
- 로그인 후: 라이딩 종료 시 Supabase REST API로 `rides`, `ride_points`에 본인 user_id로 업로드
- 토큰 만료 60초 전 자동 갱신, 갱신 실패 시 로그아웃되고 다음 로그인까지 로컬 큐에 누적
- 앱 재실행 시 Keychain의 세션 자동 복원 + pending 라이딩 자동 재업로드

## 날씨 / 미세먼지 설정

data.go.kr 일반 인증키(Decoding)를 Build Settings에 주입한다. 자세한 내용은 `docs/xcode-setup.md` 참고.

- `TODAYRIDING_KMA_API_KEY`: 기상청 단기예보 조회서비스 키
- `TODAYRIDING_AIRKOREA_API_KEY`: 에어코리아 대기오염정보 키
- `TODAYRIDING_AIRKOREA_STATION`: (선택) 고정 측정소명

키가 없으면 Mock 데이터로 동작한다.

## 문서

- 작업 지침: `docs/instructions/`
- Xcode 설정: `docs/xcode-setup.md`
- 남은 작업 / 미완료 추적: `TODO.md`
