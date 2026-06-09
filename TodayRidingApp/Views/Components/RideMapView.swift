import MapKit
import SwiftUI
import TodayRidingCore

/// iOS 17+ Map API 기반 라이딩 지도. 경로 폴리라인 + 현재 위치 마커.
struct RideMapView: View {
    let points: [RidePoint]
    var follow: Bool = true

    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $camera) {
            if points.count > 1 {
                MapPolyline(coordinates: coordinates)
                    .stroke(AppTheme.brand, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }

            if let start = coordinates.first {
                Annotation("출발", coordinate: start) {
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.brand, lineWidth: 3)
                        )
                }
            }

            if let last = coordinates.last, points.count > 1 {
                Annotation("현재", coordinate: last) {
                    Circle()
                        .fill(AppTheme.brand)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 3)
                        )
                        .shadow(color: AppTheme.brand.opacity(0.5), radius: 6, y: 2)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .onChange(of: points.count) { _, _ in
            updateCamera()
        }
        .onAppear {
            updateCamera()
        }
    }

    private var coordinates: [CLLocationCoordinate2D] {
        points.map {
            CLLocationCoordinate2D(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude
            )
        }
    }

    private func updateCamera() {
        let coords = coordinates
        guard !coords.isEmpty else {
            // 기본 좌표: 서울시청
            camera = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5666, longitude: 126.9784),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
            return
        }

        if follow, let last = coords.last, coords.count == 1 {
            camera = .region(MKCoordinateRegion(
                center: last,
                latitudinalMeters: 600,
                longitudinalMeters: 600
            ))
            return
        }

        // 전체 경로 보이도록 자동 fit
        let lats = coords.map(\.latitude)
        let lngs = coords.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else {
            return
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.003, (maxLat - minLat) * 1.4),
            longitudeDelta: max(0.003, (maxLng - minLng) * 1.4)
        )
        camera = .region(MKCoordinateRegion(center: center, span: span))
    }
}
