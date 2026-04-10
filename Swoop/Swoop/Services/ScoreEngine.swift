import Foundation

enum ScoreEngine {

    // MARK: - Sleep Score (0–100)

    static func sleepScore(hoursAsleep: Double, hoursInBed: Double) -> Double {
        guard hoursInBed > 0 else { return 0 }
        let efficiency = hoursAsleep / hoursInBed
        let durationRatio = min(hoursAsleep / 8.0, 1.0)
        return (efficiency * 0.6 + durationRatio * 0.4) * 100.0
    }

    // MARK: - Load Score (0–100)

    static func loadScore(trimpPoints: Double) -> Double {
        return min(trimpPoints / 300.0 * 100.0, 100.0)
    }

    static func trimpPoints(heartRateSamples: [(hr: Double, durationMinutes: Double)],
                             maxHR: Double) -> Double {
        heartRateSamples.reduce(0.0) { total, sample in
            let zone = heartRateZone(hr: sample.hr, maxHR: maxHR)
            return total + sample.durationMinutes * zoneMultiplier(zone)
        }
    }

    static func heartRateZone(hr: Double, maxHR: Double) -> Int {
        let pct = hr / maxHR
        switch pct {
        case ..<0.60: return 1
        case 0.60..<0.70: return 2
        case 0.70..<0.80: return 3
        case 0.80..<0.90: return 4
        default: return 5
        }
    }

    static func zoneMultiplier(_ zone: Int) -> Double {
        switch zone {
        case 1: return 1.0
        case 2: return 2.0
        case 3: return 3.0
        case 4: return 4.5
        default: return 6.0
        }
    }

    // MARK: - Readiness Score (0–100)

    static func readinessScore(todayHRV: Double,
                                recentHRVs: [Double],
                                sleepScore: Double,
                                todayRHR: Double,
                                baselineRHR: Double) -> Double {
        let baseline = trimmedMean(recentHRVs)
        let hrvComponent = baseline > 0 ? min((todayHRV / baseline) * 50.0, 50.0) : 25.0
        let sleepComponent = sleepScore * 0.30
        let rhrRatio = baselineRHR > 0
            ? (1.0 - (todayRHR - baselineRHR) / baselineRHR)
            : 1.0
        let rhrComponent = min(max(rhrRatio * 20.0, 0.0), 20.0)
        return min(hrvComponent + sleepComponent + rhrComponent, 100.0)
    }

    // MARK: - HRV Baseline

    static func trimmedMean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        guard values.count >= 3 else {
            return values.reduce(0, +) / Double(values.count)
        }
        let sorted = values.sorted()
        let trimmed = sorted.dropFirst().dropLast()
        return trimmed.reduce(0, +) / Double(trimmed.count)
    }

    // MARK: - Sleep Debt (rolling 7-day average nightly deficit)

    static func sleepDebt(last7DaysSleepHours: [Double]) -> Double {
        guard !last7DaysSleepHours.isEmpty else { return 0 }
        let deficits = last7DaysSleepHours.map { max(8.0 - $0, 0) }
        return deficits.reduce(0, +) / Double(last7DaysSleepHours.count)
    }
}
