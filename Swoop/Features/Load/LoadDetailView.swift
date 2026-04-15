import SwiftUI
import Charts
import SwiftData

struct LoadDetailView: View {

    let snapshot: DailySnapshot?
    @Query(sort: \DailySnapshot.date, order: .forward) private var history: [DailySnapshot]

    private let zones = [
        (label: "Z1", color: Color.swoopBlue,           range: "< 60%"),
        (label: "Z2", color: Color.swoopGreen,          range: "60–70%"),
        (label: "Z3", color: Color(hex: "#fbbf24"),     range: "70–80%"),
        (label: "Z4", color: Color(hex: "#fb923c"),     range: "80–90%"),
        (label: "Z5", color: Color.swoopPink,           range: "> 90%"),
    ]

    private var last14: [DailySnapshot] { Array(history.suffix(14)) }

    private var insight: Insight? {
        InsightEngine.metricInsight(metric: .load, snapshots: last14)
    }

    var body: some View {
        ZStack {
            LinearGradient.appBackground.ignoresSafeArea()
                .ambientGlow(leading: .swoopPink, trailing: .swoopPurple)
            ScrollView {
                VStack(spacing: 16) {
                    scoreHeader
                    zoneKey
                    historyChart
                    if let insight { insightCard(insight) }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Load")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("DAILY LOAD")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.swoopPink)
                    .kerning(2)
                Text(snapshot.map { "\(Int($0.loadScore))" } ?? "--")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("out of 100")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.swoopPink.opacity(0.25))
        }
        .padding(20)
        .liquidGlass(cornerRadius: 22)
    }

    private var zoneKey: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HEART RATE ZONES")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(2)
            HStack(spacing: 6) {
                ForEach(zones, id: \.label) { zone in
                    VStack(spacing: 4) {
                        Text(zone.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(zone.color)
                        Text(zone.range)
                            .font(.system(size: 7))
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(zone.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(zone.color.opacity(0.2), lineWidth: 1))
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }

    private var historyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("14-DAY LOAD HISTORY")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(2)
            Chart(last14) { snap in
                BarMark(
                    x: .value("Date", snap.date, unit: .day),
                    y: .value("Load", snap.loadScore)
                )
                .foregroundStyle(snap.loadScore.scoreColor.gradient)
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.07))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
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
