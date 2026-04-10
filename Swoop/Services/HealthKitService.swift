import HealthKit
import Foundation

// MARK: - Result types

struct SleepData {
    let hoursAsleep: Double
    let hoursInBed: Double
    let date: Date
}

struct HRVSample {
    let value: Double  // ms SDNN
    let date: Date
}

struct WorkoutHRSample {
    let hr: Double
    let durationMinutes: Double
}

// MARK: - Protocol (enables mocking in tests)

protocol HealthKitServiceProtocol {
    func requestPermissions() async throws
    func fetchMorningHRV(for date: Date) async throws -> HRVSample?
    func fetchRestingHR(for date: Date) async throws -> Double?
    func fetchSleepData(for date: Date) async throws -> SleepData?
    func fetchWorkoutHRSamples(for date: Date, maxHR: Double) async throws -> [WorkoutHRSample]
    func fetchHRVHistory(days: Int) async throws -> [HRVSample]
    func fetchSleepHistory(days: Int) async throws -> [SleepData]
    func fetchRHRHistory(days: Int) async throws -> [Double]
}

// MARK: - Real implementation

final class HealthKitService: HealthKitServiceProtocol {

    private let store = HKHealthStore()

    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRate),
        HKCategoryType(.sleepAnalysis),
        HKWorkoutType.workoutType(),
        HKQuantityType(.activeEnergyBurned)
    ]

    func requestPermissions() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - HRV

    func fetchMorningHRV(for date: Date) async throws -> HRVSample? {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .hour, value: 10, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.heartRateVariabilitySDNN),
                                         predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        let results = try await descriptor.result(for: store)
        guard let sample = results.first else { return nil }
        let value = sample.quantity.doubleValue(for: .init(from: "ms"))
        return HRVSample(value: value, date: sample.endDate)
    }

    func fetchHRVHistory(days: Int) async throws -> [HRVSample] {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.heartRateVariabilitySDNN),
                                         predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .forward)]
        )
        let results = try await descriptor.result(for: store)
        return results.map { sample in
            HRVSample(
                value: sample.quantity.doubleValue(for: .init(from: "ms")),
                date: sample.endDate
            )
        }
    }

    // MARK: - Resting HR

    func fetchRestingHR(for date: Date) async throws -> Double? {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.restingHeartRate),
                                         predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        let results = try await descriptor.result(for: store)
        return results.first?.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }

    func fetchRHRHistory(days: Int) async throws -> [Double] {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.restingHeartRate),
                                         predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .forward)]
        )
        let results = try await descriptor.result(for: store)
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        return results.map { $0.quantity.doubleValue(for: bpmUnit) }
    }

    // MARK: - Sleep

    func fetchSleepData(for date: Date) async throws -> SleepData? {
        // Sleep window: noon the day before to noon on date
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
        let start = Calendar.current.date(byAdding: .day, value: -1, to: noon)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: noon)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis),
                                          predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        let results = try await descriptor.result(for: store)

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        var hoursAsleep = 0.0
        var hoursInBed = 0.0

        for sample in results {
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
            if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                hoursInBed += duration
            } else if asleepValues.contains(sample.value) {
                hoursAsleep += duration
            }
        }

        guard hoursInBed > 0 || hoursAsleep > 0 else { return nil }
        return SleepData(hoursAsleep: hoursAsleep, hoursInBed: max(hoursInBed, hoursAsleep), date: date)
    }

    func fetchSleepHistory(days: Int) async throws -> [SleepData] {
        var result: [SleepData] = []
        for dayOffset in 1...days {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            if let data = try await fetchSleepData(for: date) {
                result.append(data)
            }
        }
        return result.reversed()
    }

    // MARK: - Workout HR Samples

    func fetchWorkoutHRSamples(for date: Date, maxHR: Double) async throws -> [WorkoutHRSample] {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let workoutDescriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        let workouts = try await workoutDescriptor.result(for: store)
        guard !workouts.isEmpty else { return [] }

        var samples: [WorkoutHRSample] = []
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())

        for workout in workouts {
            let hrPredicate = HKQuery.predicateForSamples(
                withStart: workout.startDate,
                end: workout.endDate
            )
            let hrDescriptor = HKSampleQueryDescriptor(
                predicates: [.quantitySample(type: HKQuantityType(.heartRate),
                                              predicate: hrPredicate)],
                sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
            )
            let hrResults = try await hrDescriptor.result(for: store)

            for (i, hrSample) in hrResults.enumerated() {
                let nextDate = i + 1 < hrResults.count
                    ? hrResults[i + 1].startDate
                    : hrSample.endDate
                let durationMinutes = nextDate.timeIntervalSince(hrSample.startDate) / 60
                let hr = hrSample.quantity.doubleValue(for: bpmUnit)
                samples.append(WorkoutHRSample(hr: hr, durationMinutes: durationMinutes))
            }
        }
        return samples
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "HealthKit is not available on this device."
        case .permissionDenied: return "Permission to read health data was denied."
        }
    }
}
