# 오늘탈까 작업 지침 인덱스

이 폴더는 첨부 요구사항을 구현 작업용 Markdown 지침으로 나눈 것이다.

## 문서 목록

1. [01-product-brief.md](01-product-brief.md)
   - 앱 정체성, MVP 목표, 핵심 사용자 흐름
2. [02-mvp-scope.md](02-mvp-scope.md)
   - 1차 MVP 포함/제외 범위와 완료 기준
3. [03-data-api-storage.md](03-data-api-storage.md)
   - 날씨, 미세먼지, 위치, 지도, Supabase, 로컬 저장 지침
4. [04-app-architecture.md](04-app-architecture.md)
   - SwiftUI 앱 구조, 모델, 서비스, ViewModel, 유틸리티
5. [05-screen-flows.md](05-screen-flows.md)
   - 홈, 라이딩 중, 요약, 공유 카드 화면 지침
6. [06-visual-design-guide.md](06-visual-design-guide.md)
   - 다크 스포티 디자인 토큰, 컴포넌트, 화면별 레이아웃
7. [07-implementation-plan.md](07-implementation-plan.md)
   - 구현 순서와 단계별 검증 기준
8. [08-instruction-conflict-review.md](08-instruction-conflict-review.md)
   - 지침 간 충돌, 모호점, 권장 해석

## 현재 작업 원칙

- 지금은 앱 코드 구현 전 단계다.
- 먼저 문서 지침을 기준으로 MVP 범위를 고정한다.
- 구현 시에는 Mock 데이터로 전체 흐름을 먼저 연결한다.
- 실제 API, Supabase, 백그라운드 위치, 공유 이미지 저장 등은 인터페이스와 초안부터 만들고 점진적으로 붙인다.

