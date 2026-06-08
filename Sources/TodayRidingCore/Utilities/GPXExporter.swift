import Foundation

/// 라이딩 경로를 GPX 1.1 문서 문자열로 내보낸다.
///
/// 표준 트랙(`trk` / `trkseg` / `trkpt`) 구조를 사용하며, 고도/시간/속도가 있으면 함께 기록한다.
/// Strava, Garmin Connect 등 일반 GPX 도구와 호환된다.
public enum GPXExporter {
    public static func gpx(for ride: Ride, points: [RidePoint]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let trackName = escape(ride.title ?? "오늘 라이딩")

        var lines: [String] = []
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append("<gpx version=\"1.1\" creator=\"오늘탈까\" xmlns=\"http://www.topografix.com/GPX/1/1\">")
        lines.append("  <metadata>")
        lines.append("    <name>\(trackName)</name>")
        lines.append("    <time>\(formatter.string(from: ride.startedAt))</time>")
        lines.append("  </metadata>")
        lines.append("  <trk>")
        lines.append("    <name>\(trackName)</name>")
        lines.append("    <trkseg>")

        for point in points.sorted(by: { $0.sequence < $1.sequence }) {
            lines.append(contentsOf: trackPointLines(point, formatter: formatter))
        }

        lines.append("    </trkseg>")
        lines.append("  </trk>")
        lines.append("</gpx>")

        return lines.joined(separator: "\n") + "\n"
    }

    private static func trackPointLines(_ point: RidePoint, formatter: ISO8601DateFormatter) -> [String] {
        let lat = format(point.coordinate.latitude)
        let lon = format(point.coordinate.longitude)

        var lines = ["      <trkpt lat=\"\(lat)\" lon=\"\(lon)\">"]
        if let altitude = point.altitude {
            lines.append("        <ele>\(format(altitude))</ele>")
        }
        lines.append("        <time>\(formatter.string(from: point.recordedAt))</time>")
        if let speed = point.speedMps {
            lines.append("        <extensions><speed>\(format(speed))</speed></extensions>")
        }
        lines.append("      </trkpt>")

        return lines
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
