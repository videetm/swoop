import SwiftUI
import Charts
import SwiftData

struct HRVTrendsView: View {

    @Query(sort: \DailySnapshot.date, order: .forward) private var history: [DailySnapshot]

    private var last30: [DailySnapshot] { Array(history.suffix(30)) }

    private var baseline: Double {
        ScoreEngine.trimmedMean(last30.suffix(7).map(\.hrv))
    }

    private var insight: Insight? {
        InsightEngine.metricInsight(metric: .hrv, snapshots: last30)
    }

    var body: some View {
        ZStack {
            AppBackground()
                .ambientGlow(leading: .swoopGreen, trailing: .swoopBlue)
            ScrollView {
                VStack(spacing: 16) {
                    baselineHeader
                    trendChart
                    if let insight { insightCard(insight) }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
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
                .foregroundStyle(Color.swoopGreen.opacity(0.25))
        }
        .padding(20)
        .liquidGlass(cornerRadius: 22)
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("30-DAY HRV")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(2)
            Chart {
                ForEach(last30) { snap in
                    AreaMark(
                        x: .value("Date", snap.date),
                        yStart: .value("Low",  baseline * 0.85),
                        yEnd:   .value("High", baseline * 1.15)
                    )
                    .foregroundStyle(Color.swoopGreen.opacity(0.07))
                }
                RuleMark(y: .value("Baseline", baseline))
                    .foregroundStyle(Color.swoopGreen.opacity(0.4))
                    .lineStyle(StrokeStyle(dash: [6, 3]))
                ForEach(last30) { snap in
                    AreaMark(
                        x: .value("Date", snap.date),
                        y: .value("HRV", snap.hrv)
                    )
                    .foregroundStyle(LinearGradient(colors: [Color.swoopGreen.opacity(0.3), Color.swoopGreen.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                }
                ForEach(last30) { snap in
                    LineMark(
                        x: .value("Date", snap.date),
                        y: .value("HRV", snap.hrv)
                    )
                    .foregroundStyle(Color.swoopGreen)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                ForEach(last30) { snap in
                    PointMark(
                        x: .value("Date", snap.date),
                        y: .value("HRV", snap.hrv)
                    )
                    .foregroundStyle(snap.hrv >= baseline ? Color.swoopGreen : Color.swoopPink)
                    .symbolSize(25)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.07))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)ms")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine().foregroundStyle(.white.opacity(0.07))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .frame(height: 200)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }

    private func insightCard(_ insight: Insight) -> some View {
        HStack(spacing: 10) {
            Circle().fill(insight.color).frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text("INSIGHT").font(.system(size: 8, weight: .semibold)).foregroundStyle(insight.color).kerning(1.5)
                Text(insight.text).font(.system(size: 13)).foregroundStyle(.white.opacity(0.75)).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [insight.color.opacity(0.12), insight.color.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(insight.color.opacity(0.22), lineWidth: 1))
        )
    }
}
