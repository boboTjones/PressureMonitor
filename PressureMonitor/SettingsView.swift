import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    // Local edit buffers so we only commit on Save
    @State private var zipInput       = ""
    @State private var latInput       = ""
    @State private var lonInput       = ""
    @State private var useZip         = true
    @State private var threshold      = ""
    @State private var intervalMins   = ""
    @State private var notifEnabled   = true
    @State private var validationMsg  = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            Text("Settings")
                .font(.title3).bold()

            // ── Location ────────────────────────────────────────────────
            GroupBox("Location") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Input method", selection: $useZip) {
                        Text("ZIP code").tag(true)
                        Text("Coordinates").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    if useZip {
                        LabeledContent("ZIP code") {
                            TextField("e.g. 60302", text: $zipInput)
                                .frame(width: 100)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else {
                        LabeledContent("Latitude") {
                            TextField("e.g. 41.8850", text: $latInput)
                                .frame(width: 100)
                                .textFieldStyle(.roundedBorder)
                        }
                        LabeledContent("Longitude") {
                            TextField("e.g. -87.7845", text: $lonInput)
                                .frame(width: 100)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    if !state.locationName.isEmpty {
                        Text("Current: \(state.locationName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(4)
            }

            // ── Notifications ────────────────────────────────────────────
            GroupBox("Notifications") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable low-pressure alerts", isOn: $notifEnabled)

                    LabeledContent("Alert threshold (inHg)") {
                        TextField("e.g. 29.70", text: $threshold)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                    }
                    .disabled(!notifEnabled)
                    .opacity(notifEnabled ? 1 : 0.4)

                    Text("A notification fires when the 24 h forecast predicts sea-level pressure will drop below this value.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(4)
            }

            // ── Polling ──────────────────────────────────────────────────
            GroupBox("Polling") {
                LabeledContent("Interval (minutes)") {
                    TextField("e.g. 15", text: $intervalMins)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(4)
            }

            // ── Validation error ─────────────────────────────────────────
            if !validationMsg.isEmpty {
                Label(validationMsg, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            // ── Buttons ──────────────────────────────────────────────────
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 360, height: 480)
        .onAppear { populate() }
    }

    // MARK: - Helpers

    private func populate() {
        latInput      = String(format: "%.4f", state.latitude)
        lonInput      = String(format: "%.4f", state.longitude)
        threshold     = String(format: "%.2f", state.thresholdInHg)
        intervalMins  = "\(state.pollingIntervalMins)"
        notifEnabled  = state.notificationsEnabled
    }

    private func save() {
        validationMsg = ""

        // Validate threshold
        guard let thresh = Double(threshold), thresh > 0 else {
            validationMsg = "Threshold must be a positive number (e.g. 29.70)."
            return
        }

        // Validate interval
        guard let mins = Int(intervalMins), mins >= 1 else {
            validationMsg = "Interval must be a whole number ≥ 1."
            return
        }

        // Commit simple settings immediately
        state.thresholdInHg       = thresh
        state.pollingIntervalMins = mins
        state.notificationsEnabled = notifEnabled

        // Handle location
        if useZip {
            guard !zipInput.trimmingCharacters(in: .whitespaces).isEmpty else {
                validationMsg = "Please enter a ZIP code."
                return
            }
            Task {
                await state.applyZip(zipInput.trimmingCharacters(in: .whitespaces))
                dismiss()
            }
        } else {
            guard let lat = Double(latInput), let lon = Double(lonInput) else {
                validationMsg = "Latitude and longitude must be valid numbers."
                return
            }
            guard (-90...90).contains(lat) else {
                validationMsg = "Latitude must be between -90 and 90."
                return
            }
            guard (-180...180).contains(lon) else {
                validationMsg = "Longitude must be between -180 and 180."
                return
            }
            Task {
                await state.applyCoords(lat: lat, lon: lon)
                dismiss()
            }
        }
    }
}
