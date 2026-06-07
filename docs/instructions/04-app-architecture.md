# 앱 아키텍처 지침

## 기본 구조

SwiftUI를 기본으로 하되, 데이터 수집, 저장, 동기화, 렌더링은 Service로 분리한다.

권장 폴더:

```text
Models/
Services/
ViewModels/
Views/
Views/Components/
Utilities/
supabase/
```

## Models

- Ride
- RidePoint
- WeatherSnapshot
- AirQualitySnapshot
- RideSummary

## Services

- LocationManager
- RideTracker
- WeatherService
- MockWeatherService
- AirQualityService
- MockAirQualityService
- SupabaseService
- LocalRideStore
- RideSyncService
- ShareCardRenderer

## ViewModels

- HomeViewModel
- RideTrackingViewModel
- RideSummaryViewModel
- ShareCardViewModel

## Views

- HomeView
- RideTrackingView
- RideSummaryView
- ShareCardView
- Components

## Utilities

- DistanceCalculator
- RidingScoreCalculator
- DateFormatter 또는 앱 전용 날짜 포맷터
- SpeedFormatter

## 설계 원칙

- 외부 API는 프로토콜 뒤에 숨긴다.
- 초기에는 Mock 구현으로 화면과 흐름을 완성한다.
- 실제 기상청/에어코리아/Supabase 연동은 대체 가능한 구현체로 추가한다.
- 라이딩 중 데이터는 네트워크보다 로컬 저장을 우선한다.
- ShareCardRenderer는 화면 미리보기와 이미지 생성 책임을 분리한다.
- 컴파일 가능한 코드를 우선한다.
- 한 번에 많은 외부 의존성을 추가하지 않는다.

## 로컬 저장 선택 기준

원문은 SwiftData 또는 SQLite 중 적합한 방식을 열어두었다.

MVP 권장 해석:

- SwiftData를 우선 검토한다.
- GPS 포인트 저장량, 배치 쓰기, 마이그레이션, 디버깅 요구가 커지면 SQLite를 검토한다.
- 구현 전 결정이 필요하면 `LocalRideStore` 프로토콜을 먼저 정의하고 저장 구현체를 교체 가능하게 만든다.

