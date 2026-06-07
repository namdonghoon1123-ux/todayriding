# 데이터, API, 저장 지침

## 날씨 데이터

한국 기준 기상청 API 사용을 우선 고려한다.

필요 데이터:

- 현재 기온
- 체감온도
- 습도
- 강수확률
- 강수 형태
- 강수량
- 하늘 상태
- 구름
- 풍속
- 풍향
- 초단기예보
- 단기예보
- 일몰 시간

후보 API:

- 기상청 단기예보 API
- 기상청 초단기실황 API
- 기상청 초단기예보 API
- 기상청 레이더 API

MVP 초기 구조:

- WeatherService 프로토콜을 정의한다.
- MockWeatherService를 구현한다.
- 추후 KMAWeatherService로 교체 가능하게 설계한다.
- API 키는 코드에 하드코딩하지 않는다.

## 미세먼지 데이터

한국 기준 에어코리아 API 사용을 우선 고려한다.

필요 데이터:

- PM10
- PM2.5
- 통합대기환경지수
- 측정소 위치
- 측정 시간
- 오존 등은 추후 확장

후보 API:

- 에어코리아 측정소별 실시간 대기오염정보
- 에어코리아 시도별 실시간 대기오염정보
- 가까운 측정소 조회 API

MVP 초기 구조:

- AirQualityService 프로토콜을 정의한다.
- MockAirQualityService를 구현한다.
- 추후 AirKoreaService로 교체 가능하게 설계한다.
- API 키는 코드에 하드코딩하지 않는다.

## 위치/GPS 데이터

GPS 기록은 CoreLocation을 사용한다.

필수 기록:

- 위도
- 경도
- 기록 시각
- 속도
- 정확도
- 라이딩 세션 ID

선택 기록:

- 고도

GPS 세부 튜닝은 초기에 완벽하게 하지 않아도 된다. 다만 실제 라이딩 앱으로 확장 가능한 구조는 유지한다.

## 지도

1차 MVP에서는 MapKit을 사용한다.

필수 기능:

- 현재 위치 표시
- 이동 경로 Polyline 표시
- 시작 위치 표시
- 종료 위치 표시
- 종료 후 경로 미니맵 표시
- 공유 카드에 지도 스냅샷 사용 가능하도록 구조화

카카오맵/네이버 지도는 1차 MVP에서 제외한다. 국내 자전거길/경로 탐색이 필요해질 때 추후 검토한다.

## 저장 구조

저장소는 Supabase를 메인 저장소로 사용한다.

라이딩 중 GPS 기록은 네트워크 상태에 영향을 받으면 안 되므로 아래 구조를 따른다.

```text
Supabase 메인 저장소 + 라이딩 중 로컬 임시 저장 + 종료 후 동기화
```

구현 방향:

- 라이딩 중 위치 포인트는 로컬에 먼저 저장한다.
- 라이딩 종료 후 Supabase에 업로드한다.
- 업로드 실패 시 pending 상태로 남긴다.
- 앱 재실행 시 pending 기록을 다시 동기화한다.
- Supabase 클라이언트는 별도 Service로 분리한다.

## Supabase 테이블 초안

필요하면 `/supabase/schema.sql` 파일로 SQL 초안을 만든다.

### rides

- id UUID primary key
- user_id UUID nullable
- title text nullable
- started_at timestamptz
- ended_at timestamptz nullable
- duration_seconds integer
- moving_seconds integer nullable
- distance_meters double precision
- average_speed_kmh double precision
- max_speed_kmh double precision
- start_lat double precision nullable
- start_lng double precision nullable
- end_lat double precision nullable
- end_lng double precision nullable
- weather_snapshot jsonb nullable
- air_quality_snapshot jsonb nullable
- memo text nullable
- share_card_url text nullable
- sync_status text
- created_at timestamptz default now()
- updated_at timestamptz default now()

### ride_points

- id UUID primary key
- ride_id UUID references rides(id)
- recorded_at timestamptz
- lat double precision
- lng double precision
- altitude double precision nullable
- speed_mps double precision nullable
- horizontal_accuracy double precision nullable
- sequence integer
- created_at timestamptz default now()

### ride_photos

사진 기능은 1차 MVP에서 최소화한다. 필요하면 초안만 만든다.

- id UUID primary key
- ride_id UUID references rides(id)
- local_identifier text nullable
- storage_path text nullable
- created_at timestamptz default now()

## 권한

필수 권한:

- 위치 권한
- 사진 접근 권한: 사진 첨부 기능 구현 시
- 사진 저장 권한 또는 공유 기능: 공유 카드 저장/공유 구현 시

1차 MVP에서 알림은 제외하므로 알림 권한은 필수가 아니다.

Info.plist 위치 권한 문구 예시:

```text
라이딩 경로와 거리 기록을 위해 위치 정보가 필요합니다.
```

백그라운드 위치 권한은 1차 MVP에서 신중하게 다룬다. 우선 포그라운드 기록부터 안정화한다.

