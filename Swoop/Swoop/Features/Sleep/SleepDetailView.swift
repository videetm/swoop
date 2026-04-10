import SwiftUI
import Charts
import SwiftData

struct SleepDetailView: View {

    let snapshot: DailySnapshot?
    @Query(sort: \DailySnapshot.date, order: .forward) private var history: [DailySnapshot]

    var last14: [DailySnapshot] {
        Array(history.suffix(14))
    }

    var body: some View {
        ZStack {
            LinearGradient.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    scoreHeader
                    statsCards
                    historyChart
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SLEEP SCORE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.swoopBlue)
                    .kerning(2)
                Text(snapshot.map { "\(Int($0.sleepScore))" } ?? "--")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: "moon.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.swoopBlue.opacity(0.3))
        }
        .padding(20)
        .glassCard()
    }

    private var statsCards: some View {
        HStack(spacing: 12) {
            statCard(label: "SLEPT", value: snapshot.map { formatHours($0.sleepHours) } ?? "--", color: .swoopBlue)
            statCard(label: "NEED", value: formatHours(UserSettings.shared.sleepNeedHours), color: .white.opacity(0.4))
            statCard(label: "DEBT", value: snapshot.map { formatHours($0.sleepDebt) } ?? "--", color: .swoopPink)
        }
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
    }

    private var historyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("14-DAY SLEEP HISTORY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
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
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)h")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisValueLabel(format: .dateTime.day(), centered: true)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(height: 160)
        }
        .padding(20)
        .glassCard()
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}
