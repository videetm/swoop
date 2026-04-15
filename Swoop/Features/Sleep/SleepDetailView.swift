import SwiftUI
import Charts
import SwiftData

struct SleepDetailView: View {

    let snapshot: DailySnapshot?
    @Query(sort: \DailySnapshot.date, order: .forward) private var history: [DailySnapshot]

    private var last14: [DailySnapshot] { Array(history.suffix(14)) }

    private var insight: Insight? {
        InsightEngine.metricInsight(metric: .sleep, snapshots: last14)
    }

    var body: some View {
        ZStack {
            AppBackground()
                .ambientGlow(leading: .swoopBlue, trailing: .swoopPurple)
            ScrollView {
                VStack(spacing: 16) {
                    scoreHero
                    statsRow
                    historyChart
                    if let insight { insightCard(insight) }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Sleep score hero

    private var scoreHero: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SLEEP SCORE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.swoopBlue)
                    .kerning(2)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(snapshot.map { "\(Int($0.sleepScore))" } ?? "--")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("/ 100")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.3))
                }
                Text(sleepLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle((snapshot?.sleepScore ?? 0).scoreColor)
            }
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.swoopBlue.opacity(0.25))
        }
        .padding(20)
        .liquidGlass(cornerRadius: 22)
    }

    private var sleepLabel: String {
        guard let score = snapshot?.sleepScore else { return "No data" }
        switch score {
        case 80...: return "Well rested"
        case 50..<80: return "Adequate"
        default: return "Poor sleep"
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard("SLEPT",
                     snapshot.map { formatHours($0.sleepHours) } ?? "--",
                     .swoopBlue)
            statCard("NEED",
                     formatHours(UserSettings.shared.sleepNeedHours),
                     .white.opacity(0.4))
            statCard("DEBT",
                     snapshot.map { formatHours($0.sleepDebt) } ?? "--",
                     .swoopPink)
        }
    }

    private func statCard(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .liquidGlass(cornerRadius: 16)
    }

    // MARK: - 14-day chart

    private var historyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("14-DAY SLEEP HISTORY")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(2)
            Chart(last14) { snap in
                BarMark(
                    x: .value("Date", snap.date, unit: .day),
                    y: .value("Hours", snap.sleepHours)
                )
                .foregroundStyle(Color.swoopBlue.gradient)
                .cornerRadius(4)
                RuleMark(y: .value("Need", UserSettings.shared.sleepNeedHours))
                    .foregroundStyle(.white.opacity(0.2))
                    .lineStyle(StrokeStyle(dash: [4]))
            }
            .chartYAxis {
                AxisMarks(values: [0, 4, 6, 8, 10]) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.07))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)h")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisValueLabel(format: .dateTime.day(), centered: true)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }

    // MARK: - Insight card

    private func insightCard(_ insight: Insight) -> some View {
        HStack(spacing: 10) {
            Circle().fill(insight.color).frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text("INSIGHT")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(insight.color)
                    .kerning(1.5)
                Text(insight.text)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [insight.color.opacity(0.12), insight.color.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(insight.color.opacity(0.22), lineWidth: 1))
        )
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}
