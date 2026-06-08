import Foundation

public protocol WeatherService: Sendable {
    func currentWeather() async throws -> WeatherSnapshot
}

/// 기상청 단기예보 조회 서비스(VilageFcstInfoService_2.0) 연동.
///
/// - 초단기실황(getUltraSrtNcst): 기온/습도/풍속/풍향/강수형태
/// - 단기예보(getVilageFcst): 강수확률(POP)/하늘상태(SKY)
/// - 일몰: 좌표 기반 천문 계산(`SolarCalculator`)
///
/// `apiKey`는 data.go.kr 일반 인증키(Decoding)를 사용한다.
public struct KMAWeatherService: WeatherService {
    private let apiKey: String
    private let coordinate: GeoPoint
    private let locationName: String
    private let session: URLSession

    private static let baseURL = "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0"

    public init(
        apiKey: String,
        coordinate: GeoPoint,
        locationName: String = "현재 위치",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.coordinate = coordinate
        self.locationName = locationName
        self.session = session
    }

    public func currentWeather() async throws -> WeatherSnapshot {
        guard !apiKey.isEmpty else {
            throw RemoteServiceError.notConfigured("KMA API key is empty.")
        }

        let grid = KMAGrid.grid(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let now = Date()

        async let ncstItems = fetchItems(
            path: "getUltraSrtNcst",
            baseDateTime: KMABaseTime.ultraShortNowcast(now: now),
            grid: grid,
            numOfRows: 60
        )
        async let fcstItems = fetchItems(
            path: "getVilageFcst",
            baseDateTime: KMABaseTime.villageForecast(now: now),
            grid: grid,
            numOfRows: 300
        )

        let ncst = try await ncstItems
        let fcst = try await fcstItems

        let temperature = ncst.observation(for: "T1H").flatMap(Double.init) ?? 0
        let humidity = ncst.observation(for: "REH").flatMap(Double.init).map { Int($0) } ?? 0
        let windSpeed = ncst.observation(for: "WSD").flatMap(Double.init) ?? 0
        let windVector = ncst.observation(for: "VEC").flatMap(Double.init) ?? 0
        let ptyCode = ncst.observation(for: "PTY").flatMap(Int.init) ?? 0

        let nearestForecast = fcst.nearestForecastSlot(to: now)
        let precipitationProbability = nearestForecast?.value(for: "POP").flatMap(Int.init) ?? 0
        let skyCode = nearestForecast?.value(for: "SKY").flatMap(Int.init) ?? 1

        let sunset = SolarCalculator.sunset(
            on: now,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ) ?? now

        return WeatherSnapshot(
            observedAt: now,
            locationName: locationName,
            temperatureCelsius: temperature,
            feelsLikeCelsius: WeatherMath.apparentTemperature(
                temperatureCelsius: temperature,
                humidityPercent: Double(humidity),
                windSpeedMps: windSpeed
            ),
            humidityPercent: humidity,
            precipitationProbabilityPercent: precipitationProbability,
            precipitationType: WeatherMath.precipitationType(ptyCode: ptyCode),
            skyCondition: WeatherMath.skyLabel(skyCode: skyCode),
            cloudDescription: WeatherMath.cloudDescription(skyCode: skyCode),
            windSpeedMps: windSpeed,
            windDirection: WeatherMath.windDirection(degrees: windVector),
            sunsetAt: sunset
        )
    }

    private func fetchItems(
        path: String,
        baseDateTime: KMABaseTime.Value,
        grid: KMAGrid.Point,
        numOfRows: Int
    ) async throws -> [KMAItem] {
        var components = URLComponents(string: "\(Self.baseURL)/\(path)")
        components?.queryItems = [
            URLQueryItem(name: "pageNo", value: "1"),
            URLQueryItem(name: "numOfRows", value: String(numOfRows)),
            URLQueryItem(name: "dataType", value: "JSON"),
            URLQueryItem(name: "base_date", value: baseDateTime.date),
            URLQueryItem(name: "base_time", value: baseDateTime.time),
            URLQueryItem(name: "nx", value: String(grid.nx)),
            URLQueryItem(name: "ny", value: String(grid.ny))
        ]

        guard var urlString = components?.url?.absoluteString else {
            throw RemoteServiceError.requestFailed("Failed to build KMA URL for \(path).")
        }

        // 인증키는 예약문자가 많아 직접 인코딩해 덧붙인다.
        let encodedKey = apiKey.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? apiKey
        urlString += "&serviceKey=\(encodedKey)"

        guard let url = URL(string: urlString) else {
            throw RemoteServiceError.requestFailed("Invalid KMA URL for \(path).")
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw RemoteServiceError.requestFailed("KMA \(path) HTTP error.")
        }

        let decoded: KMAResponse
        do {
            decoded = try JSONDecoder().decode(KMAResponse.self, from: data)
        } catch {
            // 인증 실패 등은 XML로 응답한다.
            throw RemoteServiceError.requestFailed("KMA \(path) returned non-JSON response.")
        }

        guard decoded.response.header.resultCode == "00" else {
            throw RemoteServiceError.requestFailed(
                "KMA \(path) error: \(decoded.response.header.resultMsg)"
            )
        }

        return decoded.response.body?.items.item ?? []
    }
}

public struct MockWeatherService: WeatherService {
    public init() {}

    public func currentWeather() async throws -> WeatherSnapshot {
        let now = Date()
        let sunset = Calendar.current.date(bySettingHour: 19, minute: 42, second: 0, of: now) ?? now

        return WeatherSnapshot(
            observedAt: now,
            locationName: "서울 성동구",
            temperatureCelsius: 23,
            feelsLikeCelsius: 22,
            humidityPercent: 58,
            precipitationProbabilityPercent: 20,
            precipitationType: .none,
            skyCondition: "맑음",
            cloudDescription: "구름 조금",
            windSpeedMps: 3.2,
            windDirection: "서풍",
            sunsetAt: sunset
        )
    }
}

public enum RemoteServiceError: Error, Sendable {
    case notImplemented(String)
    case notConfigured(String)
    case requestFailed(String)
}

// MARK: - KMA response model

struct KMAResponse: Decodable {
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
        let items: Items
    }

    struct Items: Decodable {
        let item: [KMAItem]
    }
}

struct KMAItem: Decodable {
    let category: String
    let obsrValue: String?
    let fcstValue: String?
    let fcstDate: String?
    let fcstTime: String?
}

extension Array where Element == KMAItem {
    /// 초단기실황 관측값.
    func observation(for category: String) -> String? {
        first { $0.category == category }?.obsrValue
    }

    /// 현재 시각에 가장 가까운(미래 우선) 예보 시간대의 항목들.
    func nearestForecastSlot(to now: Date) -> ForecastSlot? {
        var calendar = Calendar(identifier: .gregorian)
        guard let kst = TimeZone(identifier: "Asia/Seoul") else { return nil }
        calendar.timeZone = kst

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = kst
        formatter.dateFormat = "yyyyMMddHHmm"
        let nowKey = formatter.string(from: now)

        let slotKeys = Set(compactMap { item -> String? in
            guard let date = item.fcstDate, let time = item.fcstTime else { return nil }
            return date + time
        })
        guard !slotKeys.isEmpty else { return nil }

        let sorted = slotKeys.sorted()
        let chosen = sorted.first { $0 >= nowKey } ?? sorted.first
        guard let chosenKey = chosen else { return nil }

        let slotItems = filter { ($0.fcstDate ?? "") + ($0.fcstTime ?? "") == chosenKey }
        return ForecastSlot(items: slotItems)
    }

    struct ForecastSlot {
        let items: [KMAItem]

        func value(for category: String) -> String? {
            items.first { $0.category == category }?.fcstValue
        }
    }
}

// MARK: - KMA base time helpers

enum KMABaseTime {
    struct Value {
        let date: String
        let time: String
    }

    private static var kstCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let kst = TimeZone(identifier: "Asia/Seoul") {
            calendar.timeZone = kst
        }
        return calendar
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = kstCalendar.timeZone
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }

    /// 초단기실황: 매시 40분 이후 제공. 40분 이전이면 직전 시각 사용.
    static func ultraShortNowcast(now: Date) -> Value {
        let calendar = kstCalendar
        let minute = calendar.component(.minute, from: now)
        let effective = minute < 45 ? calendar.date(byAdding: .hour, value: -1, to: now) ?? now : now
        let hour = calendar.component(.hour, from: effective)
        return Value(date: dateString(effective), time: String(format: "%02d00", hour))
    }

    /// 단기예보: 02,05,08,11,14,17,20,23시 (+10분) 발표.
    static func villageForecast(now: Date) -> Value {
        let calendar = kstCalendar
        let availableHours = [2, 5, 8, 11, 14, 17, 20, 23]
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let nowMinutes = hour * 60 + minute

        if let latest = availableHours.last(where: { $0 * 60 + 10 <= nowMinutes }) {
            return Value(date: dateString(now), time: String(format: "%02d00", latest))
        }

        // 02:10 이전이면 전날 23시 발표 사용.
        let previousDay = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        return Value(date: dateString(previousDay), time: "2300")
    }
}

// MARK: - Weather math

public enum WeatherMath {
    /// 호주 체감온도(Apparent Temperature). 기온/습도/풍속 기반.
    public static func apparentTemperature(
        temperatureCelsius: Double,
        humidityPercent: Double,
        windSpeedMps: Double
    ) -> Double {
        let vaporPressure = (humidityPercent / 100.0) * 6.105
            * exp(17.27 * temperatureCelsius / (237.7 + temperatureCelsius))
        let apparent = temperatureCelsius + 0.33 * vaporPressure - 0.70 * windSpeedMps - 4.0
        return (apparent * 10).rounded() / 10
    }

    public static func precipitationType(ptyCode: Int) -> PrecipitationType {
        switch ptyCode {
        case 1, 5:
            return .rain
        case 2, 6:
            return .rainAndSnow
        case 3, 7:
            return .snow
        case 4:
            return .shower
        default:
            return .none
        }
    }

    public static func skyLabel(skyCode: Int) -> String {
        switch skyCode {
        case 1:
            return "맑음"
        case 3:
            return "구름많음"
        case 4:
            return "흐림"
        default:
            return "맑음"
        }
    }

    public static func cloudDescription(skyCode: Int) -> String {
        switch skyCode {
        case 1:
            return "구름 조금"
        case 3:
            return "구름 많음"
        case 4:
            return "흐림"
        default:
            return "구름 조금"
        }
    }

    /// 풍향 각도(deg) -> 16방위 한글.
    public static func windDirection(degrees: Double) -> String {
        let directions = [
            "북풍", "북북동풍", "북동풍", "동북동풍",
            "동풍", "동남동풍", "남동풍", "남남동풍",
            "남풍", "남남서풍", "남서풍", "서남서풍",
            "서풍", "서북서풍", "북서풍", "북북서풍"
        ]
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let index = Int((positive + 11.25) / 22.5) % 16
        return directions[index]
    }
}
