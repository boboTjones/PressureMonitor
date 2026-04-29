import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {

    // MARK: - Live data

    @Published var currentReading:  PressureReading?
    @Published var forecast:        [ForecastEntry] = []
    @Published var isLoading        = false
    @Published var lastError:       String?
    @Published var lastUpdated:     Date?

    // MARK: - Persisted settings

    @Published var latitude:              Double  { didSet { persist() } }
    @Published var longitude:             Double  { didSet { persist() } }
    @Published var locationName:          String  { didSet { persist() } }
    @Published var thresholdInHg:         Double  { didSet { persist() } }
    @Published var pollingIntervalMins:   Int     { didSet { persist(); startPolling() } }
    @Published var notificationsEnabled:  Bool    { didSet { persist() } }

    // MARK: - Private

    private var timer:        Timer?
    private var lastNotified: Date?

    private enum Key {
        static let lat      = "latitude"
        static let lon      = "longitude"
        static let locName  = "locationName"
        static let thresh   = "thresholdInHg"
        static let interval = "pollingIntervalMins"
        static let notifs   = "notificationsEnabled"
    }

    // MARK: - Init

    init() {
        let ud = UserDefaults.standard
        latitude             = ud.object(forKey: Key.lat)      as? Double ?? 41.8850
        longitude            = ud.object(forKey: Key.lon)      as? Double ?? -87.7845
        locationName         = ud.string(forKey: Key.locName)             ?? "Oak Park, Illinois"
        thresholdInHg        = ud.object(forKey: Key.thresh)   as? Double ?? 29.70
        pollingIntervalMins  = ud.object(forKey: Key.interval) as? Int    ?? 15
        notificationsEnabled = ud.object(forKey: Key.notifs)   as? Bool   ?? true

        NotificationManager.shared.requestPermission()
        Task { await refresh() }
        startPolling()
    }

    // MARK: - Polling

    func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: Double(pollingIntervalMins) * 60,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
    }

    // MARK: - Fetch

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let (reading, entries) = try await WeatherService.shared.fetchWeather(
                lat: latitude, lon: longitude
            )
            currentReading = reading
            forecast       = entries
            lastUpdated    = Date()

            if notificationsEnabled,
               let fired = NotificationManager.shared.checkAndNotify(
                   forecast:      entries,
                   threshold:     thresholdInHg,
                   locationName:  locationName,
                   lastNotified:  lastNotified
               ) {
                lastNotified = fired
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Location helpers

    func applyZip(_ zip: String) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            let (lat, lon, name) = try await WeatherService.shared.geocodeZip(zip)
            latitude    = lat
            longitude   = lon
            locationName = name
            await refresh()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func applyCoords(lat: Double, lon: Double) async {
        latitude  = lat
        longitude = lon
        locationName = String(format: "%.4f, %.4f", lat, lon)
        await refresh()
    }

    // MARK: - Persistence

    private func persist() {
        let ud = UserDefaults.standard
        ud.set(latitude,            forKey: Key.lat)
        ud.set(longitude,           forKey: Key.lon)
        ud.set(locationName,        forKey: Key.locName)
        ud.set(thresholdInHg,       forKey: Key.thresh)
        ud.set(pollingIntervalMins, forKey: Key.interval)
        ud.set(notificationsEnabled,forKey: Key.notifs)
    }
}
