import Foundation

/// 일출/일몰 시각 계산.
///
/// 기상청 천문 API 의존 없이 좌표만으로 일몰 시각을 추정한다.
/// 표준 sunrise/sunset 알고리즘(천정각 90.833°)을 사용하며 분 단위에서 충분히 정확하다.
public enum SolarCalculator {
    /// 주어진 날짜의 일몰 시각(UTC `Date`). 백야/극야 등으로 계산 불가하면 nil.
    public static func sunset(on date: Date, latitude: Double, longitude: Double) -> Date? {
        event(on: date, latitude: latitude, longitude: longitude, rising: false)
    }

    /// 주어진 날짜의 일출 시각(UTC `Date`).
    public static func sunrise(on date: Date, latitude: Double, longitude: Double) -> Date? {
        event(on: date, latitude: latitude, longitude: longitude, rising: true)
    }

    private static func event(on date: Date, latitude: Double, longitude: Double, rising: Bool) -> Date? {
        var utc = Calendar(identifier: .gregorian)
        guard let timeZone = TimeZone(identifier: "UTC") else { return nil }
        utc.timeZone = timeZone

        let components = utc.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day
        else {
            return nil
        }

        let zenith = 90.833
        let dayOfYear = self.dayOfYear(year: year, month: month, day: day)
        let lngHour = longitude / 15.0

        let approxTime = rising
            ? Double(dayOfYear) + ((6.0 - lngHour) / 24.0)
            : Double(dayOfYear) + ((18.0 - lngHour) / 24.0)

        // 태양 평균 근점이각
        let meanAnomaly = (0.9856 * approxTime) - 3.289

        // 태양 진황경
        var trueLongitude = meanAnomaly
            + (1.916 * sinDeg(meanAnomaly))
            + (0.020 * sinDeg(2 * meanAnomaly))
            + 282.634
        trueLongitude = normalizeDegrees(trueLongitude)

        // 적경
        var rightAscension = atanDeg(0.91764 * tanDeg(trueLongitude))
        rightAscension = normalizeDegrees(rightAscension)
        let longitudeQuadrant = floor(trueLongitude / 90.0) * 90.0
        let rightAscensionQuadrant = floor(rightAscension / 90.0) * 90.0
        rightAscension = (rightAscension + (longitudeQuadrant - rightAscensionQuadrant)) / 15.0

        // 적위
        let sinDeclination = 0.39782 * sinDeg(trueLongitude)
        let cosDeclination = cos(asin(sinDeclination))

        let cosHourAngle = (cosDeg(zenith) - (sinDeclination * sinDeg(latitude)))
            / (cosDeclination * cosDeg(latitude))
        guard cosHourAngle >= -1.0, cosHourAngle <= 1.0 else {
            return nil // 해당 날짜에 일출/일몰 없음
        }

        var hourAngle = rising ? 360.0 - acosDeg(cosHourAngle) : acosDeg(cosHourAngle)
        hourAngle /= 15.0

        let localMeanTime = hourAngle + rightAscension - (0.06571 * approxTime) - 6.622
        let universalTime = normalizeHours(localMeanTime - lngHour)

        var resultComponents = DateComponents()
        resultComponents.year = year
        resultComponents.month = month
        resultComponents.day = day
        resultComponents.hour = Int(universalTime)
        resultComponents.minute = Int((universalTime - Double(Int(universalTime))) * 60.0)
        resultComponents.timeZone = timeZone

        return utc.date(from: resultComponents)
    }

    private static func dayOfYear(year: Int, month: Int, day: Int) -> Int {
        // Almanac for Computers(1990) 표준 공식. N3가 윤년을 보정한다.
        let n1 = floor(275.0 * Double(month) / 9.0)
        let n2 = floor(Double(month + 9) / 12.0)
        let n3 = 1.0 + floor((Double(year) - 4.0 * floor(Double(year) / 4.0) + 2.0) / 3.0)
        let n = n1 - (n2 * n3) + Double(day) - 30.0
        return Int(n)
    }

    private static func normalizeDegrees(_ value: Double) -> Double {
        var result = value.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }

    private static func normalizeHours(_ value: Double) -> Double {
        var result = value.truncatingRemainder(dividingBy: 24.0)
        if result < 0 { result += 24.0 }
        return result
    }

    private static func sinDeg(_ degrees: Double) -> Double { sin(degrees * .pi / 180.0) }
    private static func cosDeg(_ degrees: Double) -> Double { cos(degrees * .pi / 180.0) }
    private static func tanDeg(_ degrees: Double) -> Double { tan(degrees * .pi / 180.0) }
    private static func atanDeg(_ value: Double) -> Double { atan(value) * 180.0 / .pi }
    private static func acosDeg(_ value: Double) -> Double { acos(value) * 180.0 / .pi }
}
