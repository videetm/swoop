import SwiftData
import Foundation

@Model
final class DailySnapshot {
    var date: Date
    var readinessScore: Double
    var sleepScore: Double
    var loadScore: Double
    var hrv: Double
    var restingHR: Double
    var sleepHours: Double
    var sleepDebt: Double

    init(date: Date,
         readinessScore: Double,
         sleepScore: Double,
         loadScore: Double,
         hrv: Double,
         restingHR: Double,
         sleepHours: Double,
         sleepDebt: Double) {
        self.date = Calendar.current.startOfDay(for: date)
        self.readinessScore = readinessScore
        self.sleepScore = sleepScore
        self.loadScore = loadScore
        self.hrv = hrv
        self.restingHR = restingHR
        self.sleepHours = sleepHours
        self.sleepDebt = sleepDebt
    }
}
