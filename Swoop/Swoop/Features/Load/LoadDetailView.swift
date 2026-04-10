import SwiftUI
import Charts
import SwiftData

struct LoadDetailView: View {

    let snapshot: DailySnapshot?
    @Query(sort: \DailySnapshot.date, order: .forward) private var history: [DailySnapshot]

    private let zones = [
        (label: "Z1", color: Color.swoopBlue, range: "< 60%"),
        (label: "Z2", color: Color.swoopGreen, range: "60–70%"),
        (label: "Z3", color: Color(hex: "#fbbf24"), range: "70–80%"),
        (label: "Z4", color: Color(hex: "#fb923c"), range: "80–90%"),
        (label: "Z5", color: Color.swoopPink, range: "> 90%"),
    ]

    var last14: [DailySnapshot] { Array(history.suffix(14)) }

    var body: some View {
        ZStack {
            LinearGradient.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    scoreHeader
                    zoneKey
                    historyChart
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
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
                .foregroundStyle(Color.swoopPink.opacity(0.3))
        }
        .padding(20)
        .glassCard()
    }

    private var zoneKey: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HEART RATE ZONES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .kerning(2)
            HStack(spacing: 8) {
                ForEach(zones, id: \.label) { zone in
                    VStack(spacing: 4) {
                        Text(zone.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(zone.color)
                        Text(zone.range)
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(zone.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(20)
        .glassCard()
    }

    private var historyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("14-DAY LOAD HISTORY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
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
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
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
}
