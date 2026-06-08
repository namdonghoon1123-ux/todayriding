# TODO

## 1차 MVP 후속

### 코드 구현 완료 (실기기/실키 검증 필요)

- [x] 기상청 `KMAWeatherService` 실제 API 매핑
  - 초단기실황 + 단기예보 호출, 격자 변환/풍향/강수형태/체감온도/일몰 계산 구현
  - 격자 변환·일몰·체감온도 계산은 `TodayRidingValidation`으로 검증됨
  - 실제 키로 라이브 응답 정합성 검증 필요
- [x] 에어코리아 `AirKoreaService` 실제 API 매핑
  - TM 좌표 변환 → 최근접 측정소 조회 → 실시간 PM10/PM2.5 호출 구현
  - TM 좌표계 정합성은 실제 키로 검증 필요
- [x] Supabase 동기화 실패 항목 수동 재시도 버튼 (기록 화면)
- [x] 앱 재실행 시 `pending`/`failed` 라이딩 자동 재시도 (`RootView`)
- [x] 기록 리스트에서 실제 경로 썸네일 렌더링
- [x] 날씨/미세먼지 좌표를 실기기 GPS 위치로 연동
  - `LocationManager.requestOneShotLocation` + `HomeViewModel.updateCoordinate`, 미승인 시 서울시청 기본 좌표
- [x] GPX 내보내기 (`GPXExporter` + 요약 화면 `ShareLink`)
- [x] 월간/연간 리포트 (`RideStatisticsCalculator` + `ReportView`)
  - 전체/연/월 통계, 개인 기록, 연속 라이딩(스트릭) 집계. 홈 우상단 리포트 버튼
- [x] 코어 단위 테스트 추가 (`Tests/TodayRidingCoreTests`, Xcode 필요)

### 실기기 / Xcode 검증 대기

- [ ] Supabase 프로젝트 생성 후 URL/anon key 주입 및 실기기 업로드 테스트
- [ ] 기상청/에어코리아 실제 키 주입 후 라이브 응답 검증
- [ ] 실기기 GPS 기록 테스트 (홈 위치 권한 + 라이딩 트래킹)
- [ ] 사진 저장 권한 실제 기기 테스트
- [ ] Xcode 설치 후 iOS Simulator 빌드 검증 + `swift test` 실행

### 기술 부채

- [ ] SwiftData 또는 SQLite 기반 `LocalRideStore` 검토
  - 현재는 JSON 파일 기반 `FileRideStore`로 라이딩/포인트 영속 저장까지 구현됨

## 2차 기능

### 코드 구현 완료 (실기기/권한 검증 필요)

- [x] 백그라운드/잠금화면 위치 기록
  - `LocationManager` 백그라운드 업데이트 + Info.plist `UIBackgroundModes=location`
- [x] 알림 기능 (매일 라이딩 리마인더)
  - `NotificationManager` + 앱 실행 시 권한 요청/예약
- [x] 라이딩 중 비구름 접근 알림
  - `RainAlertEvaluator`(Core, 검증됨) + 라이딩 중 주기적 날씨 재확인 → 로컬 알림

### 미착수 (외부 키/계정/데이터 필요)

- [ ] HealthKit 연동 (entitlement·실기기 필요)
- [ ] 코스 추천 (외부 코스/지도 데이터 필요)
- [ ] AI 라이딩 코치 (LLM API 연동 필요)
