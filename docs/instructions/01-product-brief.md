# 제품 지침

## 앱 정체성

오늘탈까는 개인용 iPhone 자전거 라이딩 앱이다.

이 앱은 단순 날씨 앱, GPS 운동 기록 앱, 콘텐츠 생성 앱 중 하나가 아니라, 자전거 라이딩 전, 중, 후를 모두 도와주는 개인 라이딩 비서 앱이다.

핵심 흐름은 다음과 같다.

```text
오늘탈까 -> 라이딩 중 확인 -> 오늘탔다
```

## 1차 MVP 목표

1차 MVP는 완성형 앱보다 핵심 흐름이 돌아가는 기반을 만드는 것이 목표다.

필수 흐름:

1. 앱 실행
2. 오늘탈까 홈 화면 표시
3. Mock 날씨/미세먼지 기반 라이딩 적합도 계산
4. 라이딩 시작
5. GPS 기록 화면 진입
6. 라이딩 종료
7. 오늘탔다 요약 화면 표시
8. 공유 카드 미리보기 생성

## 개발 방향

- SwiftUI 기반 iOS 네이티브 앱으로 개발한다.
- 개인용 iPhone 앱으로 시작한다.
- 초기 배포 목표는 App Store가 아니라 Xcode로 iPhone에 직접 설치해 테스트하는 것이다.
- 대부분의 UI/API 흐름은 Xcode Simulator에서 테스트 가능해야 한다.
- 실제 GPS 기록, 백그라운드 위치, 배터리, 잠금화면 상태 기록은 iPhone 실기기 테스트를 전제로 한다.

## 기술 방향

- Swift
- SwiftUI
- Xcode
- CoreLocation
- MapKit
- Supabase
- 로컬 임시 저장: SwiftData 또는 SQLite 중 적합한 방식
- 사진/공유: PhotosUI, ShareLink 또는 UIActivityViewController

## 구현 원칙

- SwiftUI를 기본으로 사용한다.
- UIKit은 SwiftUI만으로 구현이 불편한 경우에만 제한적으로 사용한다.
- 처음부터 실제 외부 API 연동에 집착하지 않는다.
- Mock 데이터로 화면과 흐름이 먼저 작동하게 만든다.
- API 키와 Supabase 키는 코드에 하드코딩하지 않는다.
- 필요한 설정값은 placeholder 또는 설정 파일 구조로 분리한다.

