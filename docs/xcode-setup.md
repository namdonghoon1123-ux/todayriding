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

## 터미널 검증

화면이 아니라 코어 로직만 확인하려면 아래 명령을 사용한다.

```sh
swift run TodayRidingValidation
```

성공 시:

```text
TodayRidingValidation passed
```
