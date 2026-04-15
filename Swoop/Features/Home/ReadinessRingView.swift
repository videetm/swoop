import SwiftUI
import SwiftData

struct ReadinessRingView: View {

    let snapshot: DailySnapshot?
    let isRefreshing: Bool
    let onRefresh: () -> Void

    @Query(sort: \DailySnapshot.date, order: .forward) private var history: [DailySnapshot]
    @State private var showReadinessDetail = false
    @State private var showSleepDetail     = false
    @State private var showLoadDetail      = false
    @State private var showHRVDetail       = false

    private var insight: Insight? {
        guard let snap = snapshot else { return nil }
        return InsightEngine.todayInsight(snapshot: snap, history: history)
    }

    private var last7: [DailySnapshot] { Array(history.suffix(7)) }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.appBackground.ignoresSafeArea()
                    .ambientGlow()
                ScrollView {
                    VStack(spacing: 16) {
                        dateHeader
                        heroCard
                        if let insight { insightStrip(insight) }
                        metricsRow
                        sparklineCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                isRefreshing
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: isRefreshing
                            )
                    }
                    .foregroundStyle(Color.swoopPurple)
                }
            }
            .navigationDestination(isPresented: $showReadinessDetail) {
                ReadinessDetailView(snapshot: snapshot)
            }
            .navigationDestination(isPresented: $showSleepDetail) {
                SleepDetailView(snapshot: snapshot)
            }
            .navigationDestination(isPresented: $showLoadDetail) {
                LoadDetailView(snapshot: snapshot)
            }
            .navigationDestination(isPresented: $showHRVDetail) {
                HRVTrendsView()
            }
        }
    }

    // MARK: - Date header

    private var dateHeader: some View {
        HStack {
            Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))
                .textCase(.uppercase)
                .kerning(1.5)
            Spacer()
        }
    }

    // MARK: - Hero glass card

    private var heroCard: some View {
        Button(action: { showReadinessDetail = true }) {
            HStack(spacing: 20) {
                readinessRing
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S SCORE")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .kerning(1.5)
                    Text(readinessStatus)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle((snapshot?.readinessScore ?? 0).scoreColor)
                    Text("Tap for breakdown →")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.22))
                }
                Spacer()
            }
            .padding(20)
            .liquidGlass(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    private var readinessRing: some View {
        ZStack {
            Circle()
                .stroke(Color.swoopPurple.opacity(0.15), lineWidth: 14)
                .frame(width: 110, height: 110)
            Circle()
                .trim(from: 0, to: CGFloat((snapshot?.readinessScore ?? 0) / 100))
                .stroke(
                    (snapshot?.readinessScore ?? 0).scoreColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 110, height: 110)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: snapshot?.readinessScore)
            VStack(spacing: 0) {
                if let score = snapshot?.readinessScore {
                    Text("\(Int(score))")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("--")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                }
                Text("READINESS")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .kerning(1.5)
            }
        }
    }

    private var readinessStatus: String {
        guard let score = snapshot?.readinessScore else { return "No data yet" }
        switch score {
        case 67...: return "Ready to train"
        case 34..<67: return "Moderate"
        default: return "Recovery needed"
        }
    }

    // MARK: - Insight strip

    private func insightStrip(_ insight: Insight) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(insight.color)
                .frame(width: 6, height: 6)
            Text(insight.text)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(
                    colors: [insight.color.opacity(0.12), insight.color.opacity(0.04)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(insight.color.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - 4-metric row

    private var metricsRow: some View {
        HStack(spacing: 8) {
            metricChip(
                icon: "moon.fill", label: "SLEEP",
                value: snapshot.map { "\(Int($0.sleepScore))" } ?? "--",
                color: .swoopBlue
            ) { showSleepDetail = true }

            metricChip(
                icon: "bolt.fill", label: "LOAD",
                value: snapshot.map { "\(Int($0.loadScore))" } ?? "--",
                color: .swoopPink
            ) { showLoadDetail = true }

            metricChip(
                icon: "waveform.path.ecg", label: "HRV",
                value: snapshot.map { "\(Int($0.hrv))ms" } ?? "--",
                color: .swoopGreen
            ) { showHRVDetail = true }

            metricChip(
                icon: "heart.fill", label: "RHR",
                value: snapshot.map { "\(Int($0.restingHR))" } ?? "--",
                color: .swoopPink.opacity(0.7)
            ) { showReadinessDetail = true }
        }
    }

    private func metricChip(
        icon: String, label: String, value: String,
        color: Color, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
                    .kerning(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .liquidGlass(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 7-day sparkline

    private var sparklineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("7-DAY TREND")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .kerning(2)
            if last7.isEmpty {
                Text("No history yet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(last7) { snap in
                        VStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(snap.readinessScore.scoreColor.gradient)
                                .frame(height: max(CGFloat(snap.readinessScore) / 100 * 44, 4))
                            Text(snap.date.formatted(.dateTime.weekday(.narrow)))
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 60)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }
}
