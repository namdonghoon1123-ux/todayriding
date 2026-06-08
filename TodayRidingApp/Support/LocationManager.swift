import Combine
import CoreLocation
import Foundation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var latestLocation: CLLocation?

    private let manager = CLLocationManager()
    private var wantsSingleLocation = false

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
    /// (Info.plist `UIBackgroundModes`에 `location`이 있어야 한다.)
    func startUpdating() {
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
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
