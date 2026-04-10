import BackgroundTasks
import SwiftData
import Foundation

final class BackgroundRefreshService {

    static let taskIdentifier = "com.swoop.refresh"

    // Call this once at app launch
    static func registerTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            Self.handleRefresh(task: task as! BGAppRefreshTask)
        }
    }

    static func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        // Schedule for ~6am tomorrow
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 6
        components.minute = 0
        request.earliestBeginDate = Calendar.current.date(from: components)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleRefresh(task: BGAppRefreshTask) {
        scheduleNext()  // always reschedule first

        let container: ModelContainer
        do {
            container = try ModelContainer(for: DailySnapshot.self)
        } catch {
            task.setTaskCompleted(success: false)
            return
        }

        task.expirationHandler = { task.setTaskCompleted(success: false) }

        Task {
            do {
                try await refresh(container: container, date: Date())
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }

    // Also called on foreground launch as fallback
    @MainActor
    static func refresh(container: ModelContainer, date: Date) async throws {
        let hk = HealthKitService()
        let settings = UserSettings.shared
        let context = container.mainContext

        // Fetch raw data
        async let hrvSample = hk.fetchMorningHRV(for: date)
        async let restingHR = hk.fetchRestingHR(for: date)
        async let sleepData = hk.fetchSleepData(for: date)
        async let workoutSamples = hk.fetchWorkoutHRSamples(for: date, maxHR: settings.maxHR)
        async let hrvHistory = hk.fetchHRVHistory(days: 7)
        async let sleepHistory = hk.fetchSleepHistory(days: 7)
        async let rhrHistory = hk.fetchRHRHistory(days: 7)

        let (hrv, rhr, sleep, workout, hrvHist, sleepHist, rhrHist) = try await (
            hrvSample, restingHR, sleepData, workoutSamples, hrvHistory, sleepHistory, rhrHistory
        )

        // Compute scores
        let sleepScore = sleep.map {
            ScoreEngine.sleepScore(hoursAsleep: $0.hoursAsleep, hoursInBed: $0.hoursInBed)
        } ?? 0

        let workoutTuples = workout.map { (hr: $0.hr, durationMinutes: $0.durationMinutes) }
        let trimp = ScoreEngine.trimpPoints(heartRateSamples: workoutTuples, maxHR: settings.maxHR)
        let loadScore = ScoreEngine.loadScore(trimpPoints: trimp)

        let recentHRVs = hrvHist.map(\.value)
        let baselineRHR = ScoreEngine.trimmedMean(rhrHist)
        let readinessScore = ScoreEngine.readinessScore(
            todayHRV: hrv?.value ?? 0,
            recentHRVs: recentHRVs,
            sleepScore: sleepScore,
            todayRHR: rhr ?? baselineRHR,
            baselineRHR: baselineRHR
        )

        let last7Sleep = sleepHist.map(\.hoursAsleep)
        let sleepDebt = ScoreEngine.sleepDebt(last7DaysSleepHours: last7Sleep)

        // Upsert snapshot
        let today = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == today }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.readinessScore = readinessScore
            existing.sleepScore = sleepScore
            existing.loadScore = loadScore
            existing.hrv = hrv?.value ?? existing.hrv
            existing.restingHR = rhr ?? existing.restingHR
            existing.sleepHours = sleep?.hoursAsleep ?? existing.sleepHours
            existing.sleepDebt = sleepDebt
        } else {
            let snapshot = DailySnapshot(
                date: date,
                readinessScore: readinessScore,
                sleepScore: sleepScore,
                loadScore: loadScore,
                hrv: hrv?.value ?? 0,
                restingHR: rhr ?? 0,
                sleepHours: sleep?.hoursAsleep ?? 0,
                sleepDebt: sleepDebt
            )
            context.insert(snapshot)
        }
        try context.save()

        // Sync to Watch
        if let latest = try context.fetch(descriptor).first {
            WatchSyncService.shared.send(snapshot: latest)
        }
    }
}
