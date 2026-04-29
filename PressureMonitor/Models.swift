import Foundation

struct PressureReading {
    let date: Date
    let surfaceHPa: Double
    let seaLevelHPa: Double

    var surfaceInHg: Double { surfaceHPa * 0.02953 }
    var seaLevelInHg: Double { seaLevelHPa * 0.02953 }
}

struct ForecastEntry: Identifiable {
    let id = UUID()
    let date: Date
    let seaLevelHPa: Double

    var seaLevelInHg: Double { seaLevelHPa * 0.02953 }
}

// MARK: - Open-Meteo API response shapes

struct WeatherResponse: Decodable {
    struct Current: Decodable {
        let surface_pressure: Double
        let pressure_msl: Double
    }
    struct Hourly: Decodable {
        let time: [String]
        let pressure_msl: [Double]
    }
    let current: Current
    let hourly: Hourly
    let timezone: String
}

struct GeocodingResponse: Decodable {
    struct Location: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
        let admin1: String?
        let country_code: String?
    }
    let results: [Location]?
}
