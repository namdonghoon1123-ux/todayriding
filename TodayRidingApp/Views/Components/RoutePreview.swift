import SwiftUI
import TodayRidingCore

struct RoutePreview: View {
    let points: [RidePoint]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.surface2
                GridBackground()
                    .stroke(AppTheme.hairline, lineWidth: 1)

                if points.count > 1 {
                    Path { path in
                        let mapped = normalizedPoints(in: proxy.size)
                        guard let first = mapped.first else { return }
                        path.move(to: first)
                        for point in mapped.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(.white.opacity(0.45), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))

                    Path { path in
                        let mapped = normalizedPoints(in: proxy.size)
                        guard let first = mapped.first else { return }
                        path.move(to: first)
                        for point in mapped.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(AppTheme.brand, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                } else {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        let coordinates = points.map(\.coordinate)
        guard let minLatitude = coordinates.map(\.latitude).min(),
              let maxLatitude = coordinates.map(\.latitude).max(),
              let minLongitude = coordinates.map(\.longitude).min(),
              let maxLongitude = coordinates.map(\.longitude).max()
        else {
            return []
        }

        let latitudeSpan = max(maxLatitude - minLatitude, 0.0001)
        let longitudeSpan = max(maxLongitude - minLongitude, 0.0001)
        let inset: CGFloat = 24

        return coordinates.map { coordinate in
            let x = (coordinate.longitude - minLongitude) / longitudeSpan
            let y = 1 - (coordinate.latitude - minLatitude) / latitudeSpan
            return CGPoint(
                x: inset + CGFloat(x) * (size.width - inset * 2),
                y: inset + CGFloat(y) * (size.height - inset * 2)
            )
        }
    }
}

private struct GridBackground: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 36

        stride(from: rect.minX, through: rect.maxX, by: step).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        stride(from: rect.minY, through: rect.maxY, by: step).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

