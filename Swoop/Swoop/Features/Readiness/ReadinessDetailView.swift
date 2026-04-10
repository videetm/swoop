import SwiftUI
import SwiftData

struct ReadinessDetailView: View {

    let snapshot: DailySnapshot?
    @Query(sort: \DailySnapshot.date, order: .forward) private var history: [DailySnapshot]

    private var recentHRVs: [Double] { history.suffix(7).map(\.hrv) }
    private var baselineRHR: Double { ScoreEngine.trimmedMean(history.suffix(7).map(\.restingHR)) }

    var body: some View {
        ZStack {
            LinearGradient.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    scoreHeader
                    breakdownCards
                    sevenDayHistory
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Readiness")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("READINESS SCORE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.swoopPurple)
                    .kerning(2)
                Text(snapshot.map { "\(Int($0.readinessScore))" } ?? "--")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(20)
        .glassCard()
    }

    private var breakdownCards: some View {
        VStack(spacing: 12) {
            componentRow(
                label: "HRV COMPONENT",
                description: "vs 7-day baseline",
                value: snapshot.map { snap in
                    let baseline = ScoreEngine.trimmedMean(recentHRVs)
                    let component = baseline > 0 ? min((snap.hrv / baseline) * 50, 50) : 25
                    return "\(Int(component)) / 50"
                } ?? "--",
                color: .swoopGreen
            )
            componentRow(
                label: "SLEEP COMPONENT",
                description: "30% of sleep score",
                value: snapshot.map { "\(Int($0.sleepScore * 0.30)) / 30" } ?? "--",
                color: .swoopBlue
            )
            componentRow(
                label: "RESTING HR",
                description: "vs 7-day baseline",
                value: snapshot.map { snap in
                    let ratio = baselineRHR > 0
                        ? (1 - (snap.restingHR - baselineRHR) / baselineRHR)
                        : 1.0
                    let component = min(max(ratio * 20, 0), 20)
                    return "\(Int(component)) / 20"
                } ?? "--",
                color: .swoopPink
            )
        }
    }

    private func componentRow(label: String, description: String, value: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
                    .kerning(1.5)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(16)
        .glassCard()
    }

    private var sevenDayHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-DAY READINESS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .kerning(2)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(history.suffix(7)) { snap in
                    VStack(spacing: 4) {
                        Text("\(Int(snap.readinessScore))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(snap.readinessScore.scoreColor)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(snap.readinessScore.scoreColor.gradient)
                            .frame(height: max(CGFloat(snap.readinessScore) / 100 * 80, 4))
                        Text(snap.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)
        }
        .padding(20)
        .glassCard()
    }
}
