import SwiftUI
import SwiftData

struct HistoryView: View {

    @Query(sort: \DailySnapshot.date, order: .reverse) private var snapshots: [DailySnapshot]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.appBackground.ignoresSafeArea()
                if snapshots.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var list: some View {
        List {
            ForEach(snapshots) { snap in
                historyRow(snap)
                    .listRowBackground(Color.cardSurface)
                    .listRowSeparatorTint(Color.cardBorder)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func historyRow(_ snap: DailySnapshot) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snap.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(readinessLabel(snap.readinessScore))
                    .font(.caption)
                    .foregroundStyle(snap.readinessScore.scoreColor)
            }

            Spacer()

            sparkline(values: [snap.sleepScore, snap.loadScore, snap.readinessScore],
                      colors: [.swoopBlue, .swoopPink, .swoopPurple])

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(snap.readinessScore))")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(snap.readinessScore.scoreColor)
                Text("readiness")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.vertical, 8)
    }

    private func sparkline(values: [Double], colors: [Color]) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(zip(values, colors)), id: \.0) { value, color in
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.gradient)
                        .frame(width: 6, height: max(CGFloat(value) / 100 * 28, 2))
                }
            }
        }
        .frame(height: 32)
    }

    private func readinessLabel(_ score: Double) -> String {
        switch score {
        case 67...: return "Ready"
        case 34..<67: return "Moderate"
        default: return "Recovery needed"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(Color.swoopPurple.opacity(0.4))
            Text("No history yet")
                .font(.title3.bold())
                .foregroundStyle(.white.opacity(0.6))
            Text("Data will appear here after your first refresh.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
    }
}
