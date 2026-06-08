import Foundation

public protocol AirQualityService: Sendable {
    func currentAirQuality() async throws -> AirQualitySnapshot
}

/// 한국환경공단 에어코리아 대기오염정보 연동.
///
/// - 측정소정보(getNearbyMsrstnList): 좌표(TM) 기준 최근접 측정소 조회
/// - 대기오염정보(getMsrstnAcctoRltmMesureDnsty): 측정소별 실시간 PM10/PM2.5
///
/// `stationName`을 직접 지정하면 측정소 조회를 건너뛴다.
/// `apiKey`는 data.go.kr 일반 인증키(Decoding)를 사용한다.
public struct AirKoreaService: AirQualityService {
    private let apiKey: String
    private let coordinate: GeoPoint
    private let fixedStationName: String?
    private let session: URLSession

    private static let baseURL = "https://apis.data.go.kr/B552584"

    public init(
        apiKey: String,
        coordinate: GeoPoint,
        stationName: String? = nil,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.coordinate = coordinate
        self.fixedStationName = stationName
        self.session = session
    }

    public func currentAirQuality() async throws -> AirQualitySnapshot {
        guard !apiKey.isEmpty else {
            throw RemoteServiceError.notConfigured("AirKorea API key is empty.")
        }

        let stationName = try await resolveStationName()
        let measurement = try await fetchMeasurement(stationName: stationName)

        return AirQualitySnapshot(
            pm10: measurement.pm10 ?? 0,
            pm25: measurement.pm25 ?? 0,
            stationName: stationName,
            measuredAt: measurement.measuredAt ?? Date()
        )
    }

    private func resolveStationName() async throws -> String {
        if let fixedStationName {
            return fixedStationName
        }

        let tm = KoreaTMConverter.convert(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        let items: [NearbyStation] = try await fetch(
            path: "MsrstnInfoInqireSvc/getNearbyMsrstnList",
            queryItems: [
                URLQueryItem(name: "returnType", value: "json"),
                URLQueryItem(name: "tmX", value: String(format: "%.4f", tm.x)),
                URLQueryItem(name: "tmY", value: String(format: "%.4f", tm.y)),
                URLQueryItem(name: "ver", value: "1.1"),
                URLQueryItem(name: "numOfRows", value: "1"),
                URLQueryItem(name: "pageNo", value: "1")
            ]
        )

        guard let nearest = items.first?.stationName, !nearest.isEmpty else {
            throw RemoteServiceError.requestFailed("No nearby air-quality station found.")
        }

        return nearest
    }

    private func fetchMeasurement(stationName: String) async throws -> ParsedMeasurement {
        let items: [Measurement] = try await fetch(
            path: "ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty",
            queryItems: [
                URLQueryItem(name: "returnType", value: "json"),
                URLQueryItem(name: "stationName", value: stationName),
                URLQueryItem(name: "dataTerm", value: "DAILY"),
                URLQueryItem(name: "ver", value: "1.3"),
                URLQueryItem(name: "numOfRows", value: "1"),
                URLQueryItem(name: "pageNo", value: "1")
            ]
        )

        guard let latest = items.first else {
            throw RemoteServiceError.requestFailed("No air-quality measurement for \(stationName).")
        }

        return ParsedMeasurement(
            pm10: AirKoreaService.intValue(latest.pm10Value),
            pm25: AirKoreaService.intValue(latest.pm25Value),
            measuredAt: AirKoreaService.parseDate(latest.dataTime)
        )
    }

    private func fetch<Item: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> [Item] {
        var components = URLComponents(string: "\(Self.baseURL)/\(path)")
        components?.queryItems = queryItems

        guard var urlString = components?.url?.absoluteString else {
            throw RemoteServiceError.requestFailed("Failed to build AirKorea URL for \(path).")
        }

        let encodedKey = apiKey.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? apiKey
        urlString += "&serviceKey=\(encodedKey)"

        guard let url = URL(string: urlString) else {
            throw RemoteServiceError.requestFailed("Invalid AirKorea URL for \(path).")
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw RemoteServiceError.requestFailed("AirKorea \(path) HTTP error.")
        }

        let decoded: AirKoreaResponse<Item>
        do {
            decoded = try JSONDecoder().decode(AirKoreaResponse<Item>.self, from: data)
        } catch {
            throw RemoteServiceError.requestFailed("AirKorea \(path) returned non-JSON response.")
        }

        guard decoded.response.header.resultCode == "00" else {
            throw RemoteServiceError.requestFailed(
                "AirKorea \(path) error: \(decoded.response.header.resultMsg)"
            )
        }

        return decoded.response.body?.items ?? []
    }

    private static func intValue(_ raw: String?) -> Int? {
        guard let raw, raw != "-", !raw.isEmpty else { return nil }
        return Int(raw.trimmingCharacters(in: .whitespaces))
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: raw)
    }

    private struct ParsedMeasurement {
        let pm10: Int?
        let pm25: Int?
        let measuredAt: Date?
    }
}

public struct MockAirQualityService: AirQualityService {
    public init() {}

    public func currentAirQuality() async throws -> AirQualitySnapshot {
        AirQualitySnapshot(
            pm10: 32,
            pm25: 14,
            stationName: "성수동",
            measuredAt: Date()
        )
    }
}

// MARK: - AirKorea response model

struct AirKoreaResponse<Item: Decodable>: Decodable {
    let response: Response

    struct Response: Decodable {
        let header: Header
        let body: Body?
    }

    struct Header: Decodable {
        let resultCode: String
        let resultMsg: String
    }

    struct Body: Decodable {
        let items: [Item]
    }
}

struct NearbyStation: Decodable {
    let stationName: String?
    let addr: String?
    let tm: Double?
}

struct Measurement: Decodable {
    let stationName: String?
    let pm10Value: String?
    let pm25Value: String?
    let dataTime: String?
}
