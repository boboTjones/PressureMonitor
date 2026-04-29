import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Fires a local notification if the 24 h forecast dips below `threshold`.
    /// Returns the notification date so the caller can store it for debouncing.
    /// Returns nil if no notification was sent (still debouncing, or no dip detected).
    @discardableResult
    func checkAndNotify(
        forecast: [ForecastEntry],
        threshold: Double,
        locationName: String,
        lastNotified: Date?,
        debounceHours: Double = 6
    ) -> Date? {
        // Respect debounce window
        if let last = lastNotified,
           Date().timeIntervalSince(last) < debounceHours * 3_600 {
            return nil
        }

        // Find the lowest expected pressure and whether it breaches the threshold
        guard let worst = forecast.min(by: { $0.seaLevelInHg < $1.seaLevelInHg }),
              worst.seaLevelInHg < threshold
        else { return nil }

        let timeFmt        = DateFormatter()
        timeFmt.timeStyle  = .short
        timeFmt.dateStyle  = .none

        let content        = UNMutableNotificationContent()
        content.title      = "⚠️ Low Pressure Warning"
        content.body       = String(
            format: "Pressure in %@ forecast to drop to %.2f inHg (at %@). Threshold: %.2f inHg.",
            locationName,
            worst.seaLevelInHg,
            timeFmt.string(from: worst.date),
            threshold
        )
        content.sound      = .default

        let request = UNNotificationRequest(
            identifier: "pressure-warning-\(Int(worst.date.timeIntervalSince1970))",
            content:    content,
            trigger:    nil          // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
        return Date()
    }
}
