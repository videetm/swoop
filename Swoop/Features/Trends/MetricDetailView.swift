import SwiftUI
import SwiftData
import Charts

struct MetricDetailView: View {

    let metric: TrendMetric
    @State var period: TrendPeriod

    @Query(sort: \DailySnapshot.date, order: .forward) private var allSnapshots: [DailySnapshot]

    init(metric: TrendMetric, initialPeriod: TrendPeriod) {
        self.metric = metric
        _period = State(initialValue: initialPeriod)
    }

    // MARK: - Computed data

    private var periodSnapshots: [DailySnapshot] {
        guard period != .day else { return Array(allSnapshots.suffix(1)) }
        let cutoff = Calendar.current.date(byAdding: .day, value: -period.days, to: Date()) ?? Date()
        return allSnapshots.filter { $0.date >= cutoff }
    }

    private var previousPeriodSnapshots: [DailySnapshot] {
        let end   = Calendar.current.date(byAdding: .day, value: -period.days,     to: Date()) ?? Date()
        let start = Calendar.current.date(byAdding: .day, value: -period.days * 2, to: Date()) ?? Date()
        return allSnapshots.filter { $0.date >= start && $0.date < end }
    }

    private var values: [Double] { periodSnapshots.map { metric.value(from: $0) } }
    private var avg:   Double { values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count) }
    private var peak:  Double { values.max() ?? 0 }
    private var low:   Double { values.min() ?? 0 }
    private var currentVal: Double { values.last ?? 0 }

    private var deltaVsPrevious: Double {
        let prev = previousPeriodSnapshots.map { metric.value(from: $0) }
        let prevAvg = prev.isEmpty ? 0.0 : prev.reduce(0, +) / Double(prev.count)
        guard prevAvg > 0 else { return 0 }
        return (avg - prevAvg) / prevAvg * 100
    }

    private var insight: Insight? {
        InsightEngine.metricInsight(metric: metric, snapshots: periodSnapshots)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppBackground()
                .ambientGlow(leading: metric.color, trailing: .swoopBlue)
            ScrollView {
                VStack(spacing: 12) {
                    heroCard
                    periodSelector
                    chartCard
                    statsRow
                    if let insight { insightCard(insight) }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(metric.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Hero card

    private var heroCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(period.label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(metric.color)
                    .kerning(2)
                Text(metric.formattedValue(currentVal))
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    Text("Avg \(metric.formattedValue(avg))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    deltaChip
                }
            }
            Spacer()
        }
        .padding(20)
        .liquidGlass(cornerRadius: 22)
    }

    private var deltaChip: some View {
        let pos = deltaVsPrevious >= 0
        let color: Color = pos ? .swoopGreen : .swoopPink
        return Text("\(pos ? "↑" : "↓")\(Int(abs(deltaVsPrevious)))% vs \(period.previousLabel)")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.15)))
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
                                .fill(period == p ? metric.color.opacity(0.22) : Color.clear)
                        )
                        .foregroundStyle(period == p ? metric.color : Color.white.opacity(0.4))
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

    // MARK: - Area chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if periodSnapshots.isEmpty {
                Text("No data for this period")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    // Baseline band (±8% of avg)
                    ForEach(periodSnapshots) { snap in
                        AreaMark(
                            x: .value("Date", snap.date),
                            yStart: .value("BandLow",  avg * 0.92),
                            yEnd:   .value("BandHigh", avg * 1.08)
                        )
                        .foregroundStyle(metric.color.opacity(0.07))
                    }
                    // Avg rule
                    RuleMark(y: .value("Avg", avg))
                        .foregroundStyle(metric.color.opacity(0.3))
                        .lineStyle(StrokeStyle(dash: [5, 3]))
                    // Area fill
                    ForEach(periodSnapshots) { snap in
                        AreaMark(
                            x: .value("Date", snap.date),
                            y: .value(metric.label, metric.value(from: snap))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [metric.color.opacity(0.35), metric.color.opacity(0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    // Line
                    ForEach(periodSnapshots) { snap in
                        LineMark(
                            x: .value("Date", snap.date),
                            y: .value(metric.label, metric.value(from: snap))
                        )
                        .foregroundStyle(metric.color)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.07))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: xAxisStride) { _ in
                        AxisGridLine().foregroundStyle(.white.opacity(0.07))
                        AxisValueLabel(format: xAxisFormat, centered: true)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }

    private var xAxisStride: AxisMarkValues {
        switch period {
        case .day:   return .automatic(desiredCount: 4)
        case .week:  return .stride(by: .day, count: 1)
        case .month: return .stride(by: .day, count: 7)
        case .year:  return .stride(by: .month, count: 1)
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch period {
        case .day:   return .dateTime.hour()
        case .week:  return .dateTime.weekday(.narrow)
        case .month: return .dateTime.day()
        case .year:  return .dateTime.month(.abbreviated)
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 8) {
            statChip("AVG",   metric.formattedValue(avg),  metric.color)
            statChip("PEAK",  metric.formattedValue(peak), .swoopGreen)
            statChip("LOW",   metric.formattedValue(low),  .swoopPink)
            statChip("TREND", deltaVsPrevious >= 0 ? "↑" : "↓",
                     deltaVsPrevious >= 0 ? .swoopGreen : .swoopPink)
        }
    }

    private func statChip(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
                .kerning(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 14)
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
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(insight.color.opacity(0.22), lineWidth: 1)
                )
        )
    }
}
