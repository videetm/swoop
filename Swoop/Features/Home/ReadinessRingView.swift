import SwiftUI

struct ReadinessRingView: View {

    let snapshot: DailySnapshot?
    let isRefreshing: Bool
    let onRefresh: () -> Void

    @State private var showReadinessDetail = false
    @State private var showSleepDetail = false
    @State private var showLoadDetail = false
    @State private var showHRVDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        dateHeader
                        ringHero
                        metricsRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                       value: isRefreshing)
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

    // MARK: - Subviews

    private var dateHeader: some View {
        HStack {
            Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .kerning(1.5)
            Spacer()
        }
    }

    private var ringHero: some View {
        Button(action: { showReadinessDetail = true }) {
            VStack(spacing: 8) {
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.swoopPurple.opacity(0.15), lineWidth: 18)
                        .frame(width: 180, height: 180)

                    // Score ring
                    Circle()
                        .trim(from: 0, to: CGFloat((snapshot?.readinessScore ?? 0) / 100))
                        .stroke(
                            (snapshot?.readinessScore ?? 0).scoreColor,
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.0), value: snapshot?.readinessScore)

                    VStack(spacing: 2) {
                        if let score = snapshot?.readinessScore {
                            Text("\(Int(score))")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        } else {
                            Text("--")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        Text("READINESS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .kerning(2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            metricChip(
                icon: "moon.fill",
                label: "SLEEP",
                value: snapshot.map { "\(Int($0.sleepScore))" } ?? "--",
                color: .swoopBlue,
                action: { showSleepDetail = true }
            )
            metricChip(
                icon: "bolt.fill",
                label: "LOAD",
                value: snapshot.map { "\(Int($0.loadScore))" } ?? "--",
                color: .swoopPink,
                action: { showLoadDetail = true }
            )
            metricChip(
                icon: "waveform.path.ecg",
                label: "HRV",
                value: snapshot.map { "\(Int($0.hrv))ms" } ?? "--",
                color: .swoopGreen,
                action: { showHRVDetail = true }
            )
        }
    }

    private func metricChip(icon: String, label: String, value: String,
                              color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .kerning(1.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}
