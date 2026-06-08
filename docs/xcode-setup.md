# Xcode 설정 메모

현재 저장소에는 SwiftUI 앱 소스, 검증 가능한 Swift Package 코어, iOS 앱용 Xcode 프로젝트가 함께 있다.

## 구성

- `TodayRiding.xcodeproj`: iOS 앱 프로젝트
- `Sources/TodayRidingCore`: 모델, 서비스 프로토콜, Mock 서비스, 계산 로직
- `Sources/TodayRidingValidation`: 터미널 검증 executable
- `TodayRidingApp`: Xcode iOS App 타겟에 추가할 SwiftUI 앱 소스
- `supabase/schema.sql`: Supabase 테이블 초안

## 현재 Mac 상태

현재 확인된 상태:

- `/Applications` 아래 Xcode 앱이 없다.
- `xcode-select -p`는 `/Library/Developer/CommandLineTools`를 가리킨다.
- 그래서 이 환경에서는 `xcodebuild`로 iOS 앱 빌드를 검증할 수 없다.

Xcode 설치 후 아래 명령으로 Xcode developer directory를 선택한다.

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## 화면 테스트 방법

1. Xcode를 설치한다.
2. `TodayRiding.xcodeproj`를 연다.
3. Scheme에서 `TodayRiding`을 선택한다.
4. 실행 대상은 iPhone Simulator를 선택한다.
5. Run을 누른다.
6. 앱에서 아래 흐름을 확인한다.

```text
홈 화면 -> 라이딩 시작 -> + 버튼으로 Mock 위치 추가 -> 종료 -> 요약 -> 공유 카드 만들기
```

## 권한 설정

Xcode 프로젝트는 generated Info.plist를 사용하며 위치/사진 저장 권한 문구를 빌드 설정에 넣어두었다.

```text
Privacy - Location When In Use Usage Description
라이딩 경로와 거리 기록을 위해 위치 정보가 필요합니다.

Privacy - Photo Library Additions Usage Description
공유 카드를 사진 앱에 저장하기 위해 권한이 필요합니다.
```

백그라운드 위치 기록을 위해 `UIBackgroundModes`에 `location`이 빌드 설정으로 주입돼 있다.
라이딩 트래킹 중에는 잠금화면/백그라운드에서도 위치가 기록되며 상단에 위치 표시기가 나타난다.

알림(매일 리마인더, 비구름 접근 경고)은 앱 첫 실행 시 권한을 요청한다. 권한 문구는 시스템 기본값을 사용한다.

## 터미널 검증

화면이 아니라 코어 로직만 확인하려면 아래 명령을 사용한다.

```sh
swift run TodayRidingValidation
```

성공 시:

```text
TodayRidingValidation passed
```

`TodayRidingValidation`은 거리/점수/트래커/저장소뿐 아니라 기상청 격자 변환, 일몰 계산,
TM 좌표 변환, 풍향/강수형태/체감온도 계산까지 검증한다. Command Line Tools만 있어도 실행된다.

XCTest 기반 테스트(`Tests/TodayRidingCoreTests`)는 XCTest 모듈이 필요해 **Xcode 설치 후**에만 동작한다.

```sh
swift test
```

## Supabase 설정

Supabase 키는 저장소에 커밋하지 않는다.

Xcode에서 `TodayRiding` target을 선택하고 Build Settings에 아래 값을 추가한다.

```text
TODAYRIDING_SUPABASE_URL = https://<project-ref>.supabase.co
TODAYRIDING_SUPABASE_ANON_KEY = <anon public key>
```

앱은 generated Info.plist의 아래 키로 값을 읽는다.

```text
TODAYRIDING_SUPABASE_URL
TODAYRIDING_SUPABASE_ANON_KEY
```

값이 없으면 라이딩은 로컬 JSON 저장소에 남고 `pending` 상태가 된다. 값이 있으면 라이딩 종료 시 `rides`, `ride_points` 테이블 업로드를 시도한다.

앱 실행 시 `pending`/`failed` 상태의 라이딩은 자동으로 재업로드를 시도하며, 기록 화면에서 각 항목의 재시도 버튼으로 수동 재시도도 가능하다.

## 날씨 / 미세먼지 API 설정

기상청·에어코리아 키도 저장소에 커밋하지 않는다. data.go.kr에서 발급한 **일반 인증키(Decoding)** 를 사용한다.

`TodayRiding` target Build Settings에 추가한다.

```text
TODAYRIDING_KMA_API_KEY = <기상청 단기예보 조회서비스 Decoding 키>
TODAYRIDING_AIRKOREA_API_KEY = <에어코리아 대기오염정보 Decoding 키>
TODAYRIDING_AIRKOREA_STATION = <선택: 고정 측정소명(예: 성수동). 비우면 좌표 기준 최근접 측정소 사용>
```

앱은 generated Info.plist의 동일 키로 값을 읽는다. 키가 없으면 `MockWeatherService`,
`MockAirQualityService`로 폴백한다.

- 기상청: 초단기실황(기온/습도/풍속/풍향/강수형태) + 단기예보(강수확률/하늘상태), 일몰은 좌표 기반 천문 계산
- 에어코리아: 좌표 → TM 변환 → 최근접 측정소 → 실시간 PM10/PM2.5

> 현재 좌표는 서울시청 기본값을 사용한다. 실기기 GPS 연동은 후속 작업이다.(`TODO.md`)
> 두 API의 실제 응답 정합성(특히 에어코리아 TM 좌표계)은 실제 키로 검증이 필요하다.
