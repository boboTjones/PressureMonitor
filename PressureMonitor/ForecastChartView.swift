import SwiftUI
import Charts

struct ForecastChartView: View {
    let forecast:     [ForecastEntry]
    let threshold:    Double          // inHg
    let currentInHg:  Double?

    // Compute a y-axis range that comfortably frames both the data and the threshold
    private var yDomain: ClosedRange<Double> {
        let values  = forecast.map(\.seaLevelInHg) + [threshold] + [currentInHg].compactMap { $0 }
        let lo      = (values.min() ?? 29.5) - 0.15
        let hi      = (values.max() ?? 30.5) + 0.15
        return lo...hi
    }

    private var timeDomain: ClosedRange<Date> {
        let now     = Date()
        let end     = now.addingTimeInterval(24 * 3_600)
        return now...end
    }

    var body: some View {
        Chart {
            // ── Threshold rule ───────────────────────────────────────────────
            RuleMark(y: .value("Threshold", threshold))
                .foregroundStyle(.red.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text(String(format: "%.2f threshold", threshold))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(.trailing, 4)
                }

            // ── Area fill ────────────────────────────────────────────────────
            ForEach(forecast) { entry in
                AreaMark(
                    x:    .value("Time",     entry.date),
                    yMin: .value("Floor",    yDomain.lowerBound),
                    yMax: .value("Pressure", entry.seaLevelInHg)
                )
                .foregroundStyle(
                    .linearGradient(
                        Gradient(colors: [pressureColor(entry.seaLevelInHg).opacity(0.35), .clear]),
                        startPoint: .top,
                        endPoint:   .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // ── Pressure line ─────────────────────────────────────────────
            ForEach(forecast) { entry in
                LineMark(
                    x: .value("Time",     entry.date),
                    y: .value("Pressure", entry.seaLevelInHg)
                )
                .foregroundStyle(pressureColor(entry.seaLevelInHg))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }

            // ── "Now" marker ─────────────────────────────────────────────
            if let inhg = currentInHg {
                PointMark(
                    x: .value("Time",     Date()),
                    y: .value("Pressure", inhg)
                )
                .foregroundStyle(pressureColor(inhg))
                .symbolSize(40)
                .annotation(position: .top) {
                    Text(String(format: "%.2f", inhg))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(pressureColor(inhg))
                }
            }
        }
        .chartXScale(domain: timeDomain)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisTick().foregroundStyle(.white.opacity(0.3))
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: .dateTime.hour())
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                if let v = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.2f", v))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(height: 120)
    }
}
