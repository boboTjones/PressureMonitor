import SwiftUI

@main
struct PressureMonitorApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        // ── Menu bar item ─────────────────────────────────────────────────
        MenuBarExtra {
            ContentView()
                .environmentObject(appState)
        } label: {
            MenuBarLabel()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        // ── Native Settings window (⌘,) ───────────────────────────────────
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Menu bar label (always-visible icon + pressure)

struct MenuBarLabel: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        if let r = state.currentReading {
            HStack(spacing: 3) {
                Image(systemName: "barometer")
                Text(String(format: "%.2f", r.seaLevelInHg))
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(pressureColor(r.seaLevelInHg))
        } else {
            Image(systemName: "barometer")
                .foregroundStyle(.secondary)
        }
    }
}
