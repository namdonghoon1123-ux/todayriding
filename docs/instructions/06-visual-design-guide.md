# 시각 디자인 지침

무드:

- 다크
- 스포티
- 데이터 중심

시각 레퍼런스:

- 첨부 디자인 가이드의 다크 화면들

단위:

- iOS pt 기준

## 컬러 토큰

| 토큰 | HEX | 용도 |
|---|---|---|
| bg | #0B0F14 | 메인 배경 |
| surface | #11161D | 카드 / 패널 |
| surface2 | #161C24 | 칩 / 세컨더리 카드 |
| brand | #FF6B35 | CTA, 강조, 경로선, 아이콘 |
| good | #3BD17F | 좋음 / 추천 |
| ok | #E8B563 | 보통 / 주의 |
| bad | #FF5247 | 나쁨 / 비추천 / 종료 버튼 |
| text-primary | #FFFFFF | 주요 텍스트와 숫자 |
| text-secondary | #9AA3AF | 보조 텍스트 |
| text-tertiary | #7C8694 | 라벨, 단위, 캡션 |
| hairline | #FFFFFF @ 8% | 구분선 |

상태 색상:

- 좋음/추천: good
- 보통/주의: ok
- 나쁨/비추천: bad

기록 누적 카드 그라데이션:

```text
linear-gradient(135deg, #FF7A45, #FF5722)
```

## 타이포그래피

기본 폰트:

- SF Pro
- 한글도 시스템 폰트 사용
- 큰 숫자는 rounded 디자인 권장

| 토큰 | 용도 | 크기 / 굵기 |
|---|---|---|
| display-xl | 라이딩 중 거리 | 76 / Bold |
| display-l | 홈 적합도 점수 | 92 / Bold |
| display-m | 공유 카드 거리 | 56 / Bold |
| title | 화면 제목 | 30 / Bold |
| headline | 카드, route 이름 | 17-20 / Semibold |
| stat | 스탯 숫자 | 22-30 / Bold |
| body | 본문, 판단 문구 | 15 / Medium |
| label | 칩 라벨 | 11.5-13 / Semibold |
| caption | 단위, 캡션 | 11-13 / Semibold |

규칙:

- 큰 숫자는 항상 흰색으로 표시한다.
- 단위와 라벨은 text-tertiary를 사용한다.
- 값과 단위는 baseline 정렬한다.
- 값과 단위 사이 간격은 약 3pt로 둔다.

## 스페이싱, 라운딩, 그림자

- 화면 좌우 패딩: 20
- 큰 패널/카드 라운딩: 20
- 칩 라운딩: 16
- 버튼 라운딩: 18
- 큰 공유 카드 라운딩: 26
- pill 라운딩: 999
- 카드 사이 간격: 12
- 칩 사이 간격: 9-10
- 섹션 사이 간격: 16-22
- 다크 UI이므로 그림자는 최소화한다.
- 브랜드 버튼만 오렌지 글로우를 사용한다.

## 아이콘

SF Symbols를 사용한다.

| 의미 | 심볼 |
|---|---|
| 위치 | location.fill |
| 기온 | thermometer.medium |
| 습도 | humidity.fill |
| 바람 | wind |
| 강수 | cloud.rain.fill |
| 미세먼지 | aqi.medium |
| 맑음/해 | sun.max.fill |
| 일몰 | sunset.fill |
| 자전거 | bicycle |
| 시간 | clock.fill |
| 속도 | speedometer |
| 경로 | point.topleft.down.curvedto.point.bottomright.up |
| 공유 | square.and.arrow.up |
| 일시정지 | pause.fill |
| 종료 | stop.fill |
| 재생 | play.fill |
| 메모 | pencil |
| 이동 | chevron.right |

## 주요 컴포넌트

### PrimaryButton

- 풀폭
- 높이 58
- 라운딩 18
- 배경 brand
- 텍스트 흰색 17.5 Bold
- 좌측 아이콘 22 + 라벨
- 가운데 정렬
- gap 8
- 브랜드 글로우 사용

### MetricChip

- 배경 surface2
- 라운딩 16
- 패딩 13 x 14
- 상단: 아이콘 + 라벨
- 하단: 값 + 단위

### ScoreHeader

- 큰 점수 display-l
- 등급 pill
- 적합도 / 100점 라벨
- 점수와 pill 색은 등급에 따라 good, ok, bad로 바뀐다.

### RouteMap

- 경로선: 흰색 외곽 + brand 선
- 시작점: 흰 채움 + good 링
- 끝/현재점: brand 채움 + 흰 링
- 라이브 현재 위치: 오렌지 점 + 펄스 링

### RecordingPill

- 반투명 다크 배경 + blur
- pill 라운딩
- 빨강 점 + 기록 중 텍스트

## 화면별 레이아웃

### 홈

1. 헤더: 위치 + 날짜
2. ScoreHeader
3. 한 줄 판단
4. 시간대별 적합도 카드
5. 메트릭 칩 4개
6. 일몰 안내
7. 하단 고정 PrimaryButton

### 라이딩 중

1. 상단 지도
2. RecordingPill
3. 하단 시트
4. 거리 히어로
5. 시간 / 현재 속도 / 평균 속도
6. 일시정지 / 종료 컨트롤

### 오늘탔다

1. 헤더
2. 경로 미니맵 카드
3. 스탯 그리드 2 x 2
4. 날씨 요약 칩 + 미세먼지 요약 칩
5. 메모 입력
6. 공유 카드 만들기 버튼

### 공유 카드

- 비율 9:16
- 배경 그라데이션
- 경로 미니맵
- 날짜
- 큰 거리
- route 이름
- 시간/평균/최고 3등분
- 날씨/미세먼지 한 줄
- 오늘탈까 로고 영역
- 저장/공유 액션

