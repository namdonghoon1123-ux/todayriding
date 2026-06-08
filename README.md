# 오늘탈까

개인용 iPhone 자전거 라이딩 비서 앱 MVP.

핵심 흐름:

```text
오늘탈까 -> 라이딩 시작 -> GPS 기록 -> 오늘탔다 요약 -> 공유 카드
```

## 현재 구현

- SwiftUI iOS 앱 프로젝트: `TodayRiding.xcodeproj`
- 코어 Swift Package: `TodayRidingCore`
- Mock 날씨/미세먼지 서비스 (키 없을 때 폴백)
- 기상청 `KMAWeatherService` / 에어코리아 `AirKoreaService` 실제 API 연동 (키 주입 시)
- 홈 화면 날씨/미세먼지 좌표를 단발성 GPS 위치로 연동 (미승인 시 기본 좌표)
- 규칙 기반 라이딩 적합도 계산
- GPS 포인트 기반 거리/시간/속도 계산
- 파일 기반 로컬 임시 저장: `FileRideStore`
- Supabase REST 업로드 서비스: `HTTPSupabaseService`
- Supabase 설정 주입 시 라이딩 종료 후 `rides`, `ride_points` 업로드 시도
- 앱 실행 시 미동기화 라이딩 자동 재시도 + 기록 화면 수동 재시도 버튼
- 공유 카드 미리보기, 이미지 렌더링, 사진 저장, iOS 공유 시트
- GPX 내보내기 (요약 화면 공유) : `GPXExporter`
- 월간/연간 리포트 : 전체/연/월 통계, 개인 기록, 연속 라이딩 (`RideStatisticsCalculator`, `ReportView`)
- 매일 라이딩 리마인더 + 라이딩 중 비구름 접근 알림 (`NotificationManager`, `RainAlertEvaluator`)
- 백그라운드/잠금화면 위치 기록 (`UIBackgroundModes=location`)
- 저장된 라이딩 기록 리스트(경로 썸네일 포함)와 요약 재진입
- Supabase 스키마 초안: `supabase/schema.sql`
- 코어 단위 테스트: `Tests/TodayRidingCoreTests` (Xcode), `swift run TodayRidingValidation` (CLI)

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

홈 우측 상단 기록 버튼에서 저장된 라이딩을 다시 열 수 있다.

## 웹 미리보기

Xcode 설치 전에도 기본 화면 흐름은 브라우저에서 확인할 수 있다.

파일 직접 열기:

```sh
open /Volumes/Extreme_SSD/todayriding/web-preview/index.html
```

또는 로컬 서버로 열기:

```sh
cd /Volumes/Extreme_SSD/todayriding/web-preview
python3 -m http.server 8080
```

브라우저에서:

```text
http://127.0.0.1:8080/index.html
```

웹 미리보기에서 확인 가능한 흐름:

```text
홈 -> 라이딩 시작 -> + 버튼으로 Mock 위치 추가 -> 종료 -> 요약 -> 공유 카드 -> 기록 리스트
```

웹 미리보기는 화면/상호작용 확인용이다. 실제 GPS, 사진 저장, Supabase 업로드는 iOS 앱에서 검증한다.

## 코어 검증

```sh
swift run TodayRidingValidation
```

성공 시:

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
- 남은 작업: `TODO.md`
