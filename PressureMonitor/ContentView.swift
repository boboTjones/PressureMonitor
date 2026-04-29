import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var showSettings = false

    private var relativeTime: String {
        guard let d = state.lastUpdated else { return "never" }
        let secs = Int(-d.timeIntervalSinceNow)
        if secs < 60  { return "just now" }
        if secs < 120 { return "1 min ago" }
        return "\(secs / 60) min ago"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ── Header ──────────────────────────────────────────────────
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.locationName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Updated \(relativeTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if state.isLoading {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { Task { await state.refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh now")
                }
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }

            Divider()

            // ── Current reading ─────────────────────────────────────────
            if let r = state.currentReading {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sea level")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text(String(format: "%.2f inHg", r.seaLevelInHg))
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundStyle(pressureColor(r.seaLevelInHg))
                        Text(String(format: "%.1f hPa", r.seaLevelHPa))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Surface")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text(String(format: "%.2f inHg", r.surfaceInHg))
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(pressureColor(r.surfaceInHg))
                        Text(String(format: "%.1f hPa", r.surfaceHPa))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else if let err = state.lastError {
                Label(err, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity)
            }

            // ── 24 h forecast chart ──────────────────────────────────────
            if !state.forecast.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next 24 hours")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ForecastChartView(
                        forecast:    state.forecast,
                        threshold:   state.thresholdInHg,
                        currentInHg: state.currentReading?.seaLevelInHg
                    )
                }
            }

            // ── Threshold callout ────────────────────────────────────────
            if let minEntry = state.forecast.min(by: { $0.seaLevelInHg < $1.seaLevelInHg }),
               minEntry.seaLevelInHg < state.thresholdInHg {
                let timeFmt: DateFormatter = {
                    let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none; return f
                }()
                Label(
                    String(
                        format: "Forecast drops to %.2f inHg at %@",
                        minEntry.seaLevelInHg,
                        timeFmt.string(from: minEntry.date)
                    ),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding(14)
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(state)
        }
    }
}
