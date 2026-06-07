# TODO

## 1차 MVP 후속

- SwiftData 또는 SQLite 기반 `LocalRideStore` 검토
  - 현재는 JSON 파일 기반 `FileRideStore`로 라이딩/포인트 영속 저장까지 구현됨
- Supabase 프로젝트 생성 후 URL/anon key 주입
  - 현재는 SDK 없이 REST 업로드 가능한 `HTTPSupabaseService` 초안 구현됨
- 기상청 `KMAWeatherService` 실제 API 매핑
  - 현재는 교체 가능한 타입과 명확한 not implemented 오류만 있음
- 에어코리아 `AirKoreaService` 실제 API 매핑
  - 현재는 교체 가능한 타입과 명확한 not implemented 오류만 있음
- 실기기 GPS 기록 테스트
- 사진 저장 권한 실제 기기 테스트
- Xcode 설치 후 iOS Simulator 빌드 검증

## 2차 기능

- 백그라운드/잠금화면 위치 기록 안정화
- 알림 기능
- 라이딩 중 비구름 접근 알림
- HealthKit 연동
- GPX 내보내기
- 기록 리스트 화면
- 월간/연간 리포트
- 코스 추천
- AI 라이딩 코치
