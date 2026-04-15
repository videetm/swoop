import SwiftUI

// MARK: - TrendPeriod

enum TrendPeriod: String, CaseIterable {
    case day   = "D"
    case week  = "W"
    case month = "M"
    case year  = "Y"

    var days: Int {
        switch self {
        case .day:   return 1
        case .week:  return 7
        case .month: return 30
        case .year:  return 365
        }
    }

    var label: String {
        switch self {
        case .day:   return "Today"
        case .week:  return "This Week"
        case .month: return "This Month"
        case .year:  return "This Year"
        }
    }

    var previousLabel: String {
        switch self {
        case .day:   return "yesterday"
        case .week:  return "last week"
        case .month: return "last month"
        case .year:  return "last year"
        }
    }
}

// MARK: - TrendMetric

enum TrendMetric: String, CaseIterable, Identifiable, Hashable {
    case readiness, hrv, sleep, load

    var id: String { rawValue }

    var label: String {
        switch self {
        case .readiness: return "Readiness"
        case .hrv:       return "HRV"
        case .sleep:     return "Sleep"
        case .load:      return "Load"
        }
    }

    var color: Color {
        switch self {
        case .readiness: return .swoopPurple
        case .hrv:       return .swoopGreen
        case .sleep:     return .swoopBlue
        case .load:      return .swoopPink
        }
    }

    var unit: String {
        switch self {
        case .readiness: return ""
        case .hrv:       return "ms"
        case .sleep:     return "h"
        case .load:      return ""
        }
    }

    var icon: String {
        switch self {
        case .readiness: return "circle.fill"
        case .hrv:       return "waveform.path.ecg"
        case .sleep:     return "moon.fill"
        case .load:      return "bolt.fill"
        }
    }

    func value(from snapshot: DailySnapshot) -> Double {
        switch self {
        case .readiness: return snapshot.readinessScore
        case .hrv:       return snapshot.hrv
        case .sleep:     return snapshot.sleepHours
        case .load:      return snapshot.loadScore
        }
    }

    func formattedValue(_ value: Double) -> String {
        switch self {
        case .readiness: return "\(Int(value))"
        case .hrv:       return "\(Int(value))ms"
        case .sleep:
            let h = Int(value)
            let m = Int((value - Double(h)) * 60)
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        case .load:      return "\(Int(value))"
        }
    }
}
