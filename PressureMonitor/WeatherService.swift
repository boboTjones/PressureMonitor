import Foundation

enum WeatherError: LocalizedError {
    case zipNotFound(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .zipNotFound(let z): return "ZIP code '\(z)' not found."
        case .badResponse:        return "Unexpected response from weather API."
        }
    }
}

actor WeatherService {
    static let shared = WeatherService()

    // MARK: - Geocoding

    func geocodeZip(_ zip: String) async throws -> (lat: Double, lon: Double, name: String) {
        var comps = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        comps.queryItems = [
            .init(name: "name",        value: zip),
            .init(name: "count",       value: "1"),
            .init(name: "language",    value: "en"),
            .init(name: "format",      value: "json"),
            .init(name: "countryCode", value: "US"),
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let response  = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        guard let loc = response.results?.first else { throw WeatherError.zipNotFound(zip) }
        let name = [loc.name, loc.admin1, loc.country_code].compactMap { $0 }.joined(separator: ", ")
        return (loc.latitude, loc.longitude, name)
    }

    // MARK: - Current + 24 h forecast (single request)

    func fetchWeather(lat: Double, lon: Double) async throws -> (current: PressureReading, forecast: [ForecastEntry]) {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude",     value: "\(lat)"),
            .init(name: "longitude",    value: "\(lon)"),
            .init(name: "current",      value: "surface_pressure,pressure_msl"),
            .init(name: "hourly",       value: "pressure_msl"),
            .init(name: "forecast_days",value: "2"),
            .init(name: "timezone",     value: "auto"),
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        let response  = try JSONDecoder().decode(WeatherResponse.self, from: data)

        let current = PressureReading(
            date:         Date(),
            surfaceHPa:   response.current.surface_pressure,
            seaLevelHPa:  response.current.pressure_msl
        )

        // Parse the hourly strings using the location's timezone, then keep only [now, now+24h]
        let localFmt         = DateFormatter()
        localFmt.dateFormat  = "yyyy-MM-dd'T'HH:mm"
        localFmt.timeZone    = TimeZone(identifier: response.timezone) ?? .current

        let now     = Date()
        let cutoff  = now.addingTimeInterval(24 * 3600)

        let forecast: [ForecastEntry] = zip(response.hourly.time, response.hourly.pressure_msl)
            .compactMap { timeStr, hpa -> ForecastEntry? in
                guard let date = localFmt.date(from: timeStr),
                      date >= now, date <= cutoff
                else { return nil }
                return ForecastEntry(date: date, seaLevelHPa: hpa)
            }

        return (current, forecast)
    }
}
