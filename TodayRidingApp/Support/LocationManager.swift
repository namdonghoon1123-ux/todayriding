import Combine
import CoreLocation
import Foundation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var latestLocation: CLLocation?

    private let manager = CLLocationManager()
    private var wantsSingleLocation = false

    /// Info.plist `UIBackgroundModes` 배열에 `location`이 있어야 백그라운드 위치 업데이트를 켤 수 있다.
    /// Xcode가 `INFOPLIST_KEY_UIBackgroundModes`를 array로 변환 못 해주는 경우가 있어서
    /// 런타임에 다시 한 번 확인 → 누락 상태면 백그라운드 모드는 끈 채로 동작(앱 크래시 회피).
    private static let supportsBackgroundLocation: Bool = {
        guard let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else {
            return false
        }
        return modes.contains("location")
    }()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 5
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// 라이딩 트래킹용 연속 위치 업데이트 시작.
    /// 백그라운드/잠금화면에서도 기록이 유지되도록 백그라운드 업데이트를 켠다.
    /// Info.plist에 `UIBackgroundModes=location`이 빠져 있으면 백그라운드 옵션은 건너뛰고
    /// 포그라운드 추적만 시작한다(빌드 시 plist 누락으로 인한 어설션 회피).
    func startUpdating() {
        manager.pausesLocationUpdatesAutomatically = false

        if Self.supportsBackgroundLocation {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        }

        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()

        if Self.supportsBackgroundLocation {
            manager.allowsBackgroundLocationUpdates = false
        }
    }

    /// 홈 화면 날씨/미세먼지용 단발성 위치 요청. 권한 미결정이면 요청 후 승인 시 자동으로 1회 받아온다.
    func requestOneShotLocation() {
        wantsSingleLocation = true
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            wantsSingleLocation = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if wantsSingleLocation,
           manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latestLocation = locations.last
        wantsSingleLocation = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        wantsSingleLocation = false
    }
}
