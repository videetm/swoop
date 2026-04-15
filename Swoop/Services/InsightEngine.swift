import SwiftUI

// MARK: - Insight model

struct Insight {
    let text: String
    let color: Color
}

// MARK: - InsightEngine

enum InsightEngine {

    // MARK: - Today insight (pure — no SwiftData dependency)

    /// Evaluates rules in priority order and returns the most relevant insight.
    /// All parameters are pre-extracted plain values so this is unit-testable.
    static func todayInsightCore(
        readinessScore: Double,
        hrv: Double,
        baselineHRV: Double,
        sleepDebt: Double,
        loadScore: Double,
        avgLoad: Double,
        restingHR: Double,
        baselineRHR: Double,
        recentReadiness: [Double]   // last 3, chronological order
    ) -> Insight? {
        // 1. Recovery needed
        if readinessScore < 34 {
            return Insight(text: "Body signalling full recovery — avoid intensity today.", color: .swoopPink)
        }
        // 2. RHR elevated
        if baselineRHR > 0 && restingHR > baselineRHR + 4 {
            let diff = Int(restingHR - baselineRHR)
            return Insight(text: "Resting HR elevated by \(diff) bpm — signs of accumulated fatigue.", color: .swoopPink)
        }
        // 3. HRV below baseline
        if baselineHRV > 0 && hrv < baselineHRV * 0.93 {
            return Insight(text: "HRV below baseline — favour easy effort today.", color: .swoopPurple)
        }
        // 4. Sleep debt high
        if sleepDebt > 1.5 {
            let s = String(format: "%.1f", sleepDebt)
            return Insight(text: "Carrying \(s)h sleep debt — prioritise 8h+ tonight.", color: .swoopBlue)
        }
        // 5. Load spike
        if avgLoad > 0 && loadScore > avgLoad * 1.4 {
            return Insight(text: "High load day — schedule easy effort tomorrow.", color: .swoopPink)
        }
        // 6. HRV above baseline (positive)
        if baselineHRV > 0 && hrv > baselineHRV * 1.07 {
            let pct = Int((hrv / baselineHRV - 1) * 100)
            return Insight(text: "HRV \(pct)% above baseline — prime window for high intensity.", color: .swoopGreen)
        }
        // 7. Readiness trending up (3 consecutive increases)
        if recentReadiness.count >= 3 {
            let last3 = Array(recentReadiness.suffix(3))
            if last3[0] < last3[1] && last3[1] < last3[2] {
                return Insight(text: "Readiness trending up 3 days straight — momentum is building.", color: .swoopGreen)
            }
        }
        // 8. Sleep debt clear
        if sleepDebt < 0.25 {
            return Insight(text: "Sleep debt cleared — recovery is on track.", color: .swoopGreen)
        }
        // 9. RHR normal
        if baselineRHR > 0 && restingHR <= baselineRHR + 1 {
            return Insight(text: "Resting HR normal — cardiovascular recovery looks good.", color: .swoopGreen)
        }
        return nil
    }

    /// Convenience wrapper that extracts values from SwiftData objects.
    static func todayInsight(snapshot: DailySnapshot, history: [DailySnapshot]) -> Insight? {
        let recent7 = Array(history.suffix(7))
        let baselineHRV = ScoreEngine.trimmedMean(recent7.map(\.hrv))
        let loads = recent7.map(\.loadScore)
        let avgLoad = loads.isEmpty ? 0.0 : loads.reduce(0, +) / Double(loads.count)
        let baselineRHR = ScoreEngine.trimmedMean(recent7.map(\.restingHR))
        let recentReadiness = history.suffix(3).map(\.readinessScore)

        return todayInsightCore(
            readinessScore: snapshot.readinessScore,
            hrv: snapshot.hrv,
            baselineHRV: baselineHRV,
            sleepDebt: snapshot.sleepDebt,
            loadScore: snapshot.loadScore,
            avgLoad: avgLoad,
            restingHR: snapshot.restingHR,
            baselineRHR: baselineRHR,
            recentReadiness: Array(recentReadiness)
        )
    }

    // MARK: - Metric insight (for Trends deep-dive)

    /// Pure function for metric-specific insights.
    static func metricInsightCore(
        metric: TrendMetric,
        avgValue: Double,
        currentLoad: Double = 0,
        avgLoad: Double = 0,
        avgSleepDebt: Double = 0,
        sleepNeed: Double = 8.0
    ) -> Insight? {
        switch metric {
        case .readiness:
            if avgValue >= 67 { return Insight(text: "Strong readiness period — your recovery routine is working.", color: .swoopGreen) }
            if avgValue < 34  { return Insight(text: "Low readiness trend — consider reducing training load.", color: .swoopPink) }
            return Insight(text: "Moderate readiness average — small sleep improvements will lift this.", color: .swoopPurple)

        case .hrv:
            if avgValue > 0 { return Insight(text: "Track HRV trends over 4+ weeks for your true baseline to emerge.", color: .swoopGreen) }
            return nil

        case .sleep:
            if avgValue < sleepNeed - 1 {
                let deficit = String(format: "%.1f", sleepNeed - avgValue)
                return Insight(text: "Averaging \(deficit)h short of your \(Int(sleepNeed))h need — cumulative debt adds up.", color: .swoopBlue)
            }
            if avgSleepDebt > 1.5 {
                return Insight(text: "Sleep debt elevated — consistent bedtime will accelerate recovery.", color: .swoopBlue)
            }
            return Insight(text: "Sleep duration on target — consistency matters as much as quantity.", color: .swoopGreen)

        case .load:
            if currentLoad > avgLoad * 1.4 {
                return Insight(text: "Load spike detected — follow with 1–2 easy days for full absorption.", color: .swoopPink)
            }
            if avgValue < 20 {
                return Insight(text: "Low training load period — body is well rested and ready to build.", color: .swoopGreen)
            }
            return Insight(text: "Consistent load pattern — keep alternating hard and easy days.", color: .swoopPurple)
        }
    }

    /// Convenience wrapper that extracts values from a snapshot array.
    static func metricInsight(metric: TrendMetric, snapshots: [DailySnapshot]) -> Insight? {
        let values = snapshots.map { metric.value(from: $0) }
        let avg = values.isEmpty ? 0.0 : values.reduce(0, +) / Double(values.count)
        let currentLoad = snapshots.last?.loadScore ?? 0
        let avgLoad = snapshots.map(\.loadScore).reduce(0, +) / max(Double(snapshots.count), 1)
        let avgDebt = snapshots.map(\.sleepDebt).reduce(0, +) / max(Double(snapshots.count), 1)

        return metricInsightCore(
            metric: metric,
            avgValue: avg,
            currentLoad: currentLoad,
            avgLoad: avgLoad,
            avgSleepDebt: avgDebt,
            sleepNeed: UserSettings.shared.sleepNeedHours
        )
    }
}
