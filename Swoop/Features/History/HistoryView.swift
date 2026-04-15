import SwiftUI
import SwiftData

struct HistoryView: View {

    @Query(sort: \DailySnapshot.date, order: .forward) private var snapshots: [DailySnapshot]
    @State private var period: TrendPeriod = .week

    private var periodSnapshots: [DailySnapshot] {
        guard period != .day else { return Array(snapshots.suffix(1)) }
        let cutoff = Calendar.current.date(byAdding: .day, value: -period.days, to: Date()) ?? Date()
        return snapshots.filter { $0.date >= cutoff }
    }

    private var previousPeriodSnapshots: [DailySnapshot] {
        let end   = Calendar.current.date(byAdding: .day, value: -period.days,     to: Date()) ?? Date()
        let start = Calendar.current.date(byAdding: .day, value: -period.days * 2, to: Date()) ?? Date()
        return snapshots.filter { $0.date >= start && $0.date < end }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.appBackground.ignoresSafeArea()
                    .ambientGlow(leading: .swoopBlue, trailing: .swoopPurple)
                if snapshots.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            periodSelector
                            ForEach(TrendMetric.allCases) { metric in
                                NavigationLink(value: metric) {
                                    metricCard(metric)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: TrendMetric.self) { metric in
                MetricDetailView(metric: metric, initialPeriod: period)
            }
        }
    }

    // MARK: - Period selector

    private var periodSelector: some View {
        HStack(spacing: 3) {
            ForEach(TrendPeriod.allCases, id: \.rawValue) { p in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { period = p }
                } label: {
                    Text(p.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(period == p ? Color.swoopPurple.opacity(0.25) : Color.clear)
                        )
                        .foregroundStyle(period == p ? Color.swoopPurple : Color.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    // MARK: - Metric card

    private func metricCard(_ metric: TrendMetric) -> some View {
        HStack(spacing: 12) {
            Image(systemName: metric.icon)
                .font(.system(size: 16))
                .foregroundStyle(metric.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(metric.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(metric.formattedValue(currentValue(for: metric)))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            miniSparkline(for: metric)
            deltaBadge(for: metric)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }

    private func miniSparkline(for metric: TrendMetric) -> some View {
        let vals = periodSnapshots.suffix(7).map { metric.value(from: $0) }
        let maxV = vals.max() ?? 1
        return HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(vals.enumerated()), id: \.offset) { i, v in
                RoundedRectangle(cornerRadius: 2)
                    .fill(metric.color.opacity(i == vals.count - 1 ? 1.0 : 0.4))
                    .frame(width: 5, height: max(CGFloat(v / maxV) * 24, 2))
            }
        }
        .frame(width: 50, height: 24)
    }

    private func deltaBadge(for metric: TrendMetric) -> some View {
        let cur  = currentValue(for: metric)
        let prev = previousValue(for: metric)
        let pct  = prev > 0 ? (cur - prev) / prev * 100 : 0
        let pos  = pct >= 0
        let color: Color = pos ? .swoopGreen : .swoopPink

        return Text("\(pos ? "↑" : "↓")\(Int(abs(pct)))%")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.15)))
    }

    // MARK: - Helpers

    private func currentValue(for metric: TrendMetric) -> Double {
        guard !periodSnapshots.isEmpty else { return 0 }
        let vals = periodSnapshots.map { metric.value(from: $0) }
        return metric == .sleep
            ? vals.reduce(0, +) / Double(vals.count)
            : (periodSnapshots.last.map { metric.value(from: $0) } ?? 0)
    }

    private func previousValue(for metric: TrendMetric) -> Double {
        guard !previousPeriodSnapshots.isEmpty else { return 0 }
        return metric.value(from: previousPeriodSnapshots.last ?? previousPeriodSnapshots[0])
    }

    // MARK: - Empty state

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
