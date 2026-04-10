import SwiftUI
import Charts
import SwiftData

struct HRVTrendsView: View {

    @Query(sort: \DailySnapshot.date, order: .forward) private var history: [DailySnapshot]

    var last30: [DailySnapshot] { Array(history.suffix(30)) }

    var baseline: Double {
        let values = last30.suffix(7).map(\.hrv)
        return ScoreEngine.trimmedMean(values)
    }

    var body: some View {
        ZStack {
            LinearGradient.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    baselineHeader
                    trendChart
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationTitle("HRV Trends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var baselineHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("7-DAY BASELINE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.swoopGreen)
                    .kerning(2)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(baseline))")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("ms")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundStyle(Color.swoopGreen.opacity(0.3))
        }
        .padding(20)
        .glassCard()
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("30-DAY HRV")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .kerning(2)

            Chart {
                // Baseline band (±15% of baseline)
                ForEach(last30) { snap in
                    AreaMark(
                        x: .value("Date", snap.date),
                        yStart: .value("Low", baseline * 0.85),
                        yEnd: .value("High", baseline * 1.15)
                    )
                    .foregroundStyle(Color.swoopGreen.opacity(0.08))
                }

                // Baseline line
                RuleMark(y: .value("Baseline", baseline))
                    .foregroundStyle(Color.swoopGreen.opacity(0.4))
                    .lineStyle(StrokeStyle(dash: [6, 3]))

                // HRV line
                ForEach(last30) { snap in
                    LineMark(
                        x: .value("Date", snap.date),
                        y: .value("HRV", snap.hrv)
                    )
                    .foregroundStyle(Color.swoopGreen)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", snap.date),
                        y: .value("HRV", snap.hrv)
                    )
                    .foregroundStyle(snap.hrv >= baseline ? Color.swoopGreen : Color.swoopPink)
                    .symbolSize(30)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)ms")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(height: 200)
        }
        .padding(20)
        .glassCard()
    }
}
