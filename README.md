# 오늘탈까

개인용 iPhone 자전거 라이딩 비서 앱 MVP.

핵심 흐름:

```text
오늘탈까 -> 라이딩 시작 -> GPS 기록 -> 오늘탔다 요약 -> 공유 카드
```

## 현재 구현

- SwiftUI iOS 앱 프로젝트: `TodayRiding.xcodeproj`
- 코어 Swift Package: `TodayRidingCore`
- Mock 날씨/미세먼지 서비스
- 규칙 기반 라이딩 적합도 계산
- GPS 포인트 기반 거리/시간/속도 계산
- 파일 기반 로컬 임시 저장: `FileRideStore`
- Supabase REST 업로드 서비스 초안: `HTTPSupabaseService`
- 공유 카드 미리보기, 이미지 렌더링, 사진 저장, iOS 공유 시트
- Supabase 스키마 초안: `supabase/schema.sql`

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

## 코어 검증

```sh
swift run TodayRidingValidation
```

성공 시:

```text
TodayRidingValidation passed
```

## 문서

- 작업 지침: `docs/instructions/`
- Xcode 설정: `docs/xcode-setup.md`
- 남은 작업: `TODO.md`

