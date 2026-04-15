import XCTest
@testable import Swoop

final class ScoreEngineTests: XCTestCase {

    // MARK: - Sleep Score

    func testSleepScorePerfectNight() {
        // 8h asleep, 8h in bed = efficiency 1.0, duration 1.0 → 100
        let score = ScoreEngine.sleepScore(hoursAsleep: 8.0, hoursInBed: 8.0)
        XCTAssertEqual(score, 100.0, accuracy: 0.1)
    }

    func testSleepScoreShortNight() {
        // 6h asleep, 8h in bed: efficiency=0.75, duration=0.75
        // (0.75*0.6 + 0.75*0.4)*100 = 75.0
        let score = ScoreEngine.sleepScore(hoursAsleep: 6.0, hoursInBed: 8.0)
        XCTAssertEqual(score, 75.0, accuracy: 0.1)
    }

    func testSleepScoreZeroInBed() {
        let score = ScoreEngine.sleepScore(hoursAsleep: 0, hoursInBed: 0)
        XCTAssertEqual(score, 0.0)
    }

    // MARK: - Trimmed Mean

    func testTrimmedMeanDropsOutliers() {
        // [20, 60, 65, 70, 100] → drop 20 and 100 → mean(60,65,70) = 65
        let result = ScoreEngine.trimmedMean([20, 60, 65, 70, 100])
        XCTAssertEqual(result, 65.0, accuracy: 0.1)
    }

    func testTrimmedMeanFewValues() {
        // <3 values: plain mean
        let result = ScoreEngine.trimmedMean([60.0, 80.0])
        XCTAssertEqual(result, 70.0, accuracy: 0.1)
    }

    // MARK: - HR Zone

    func testHRZoneZone1() {
        // 55% of 180 = 99 bpm → zone 1
        XCTAssertEqual(ScoreEngine.heartRateZone(hr: 99, maxHR: 180), 1)
    }

    func testHRZoneZone3() {
        // 75% of 180 = 135 bpm → zone 3
        XCTAssertEqual(ScoreEngine.heartRateZone(hr: 135, maxHR: 180), 3)
    }

    func testHRZoneZone5() {
        // 92% of 180 = 165 bpm → zone 5
        XCTAssertEqual(ScoreEngine.heartRateZone(hr: 165, maxHR: 180), 5)
    }

    // MARK: - Load Score

    func testLoadScoreZeroActivity() {
        let score = ScoreEngine.loadScore(trimpPoints: 0)
        XCTAssertEqual(score, 0.0)
    }

    func testLoadScoreMaxActivity() {
        // 300 trimp = 100
        let score = ScoreEngine.loadScore(trimpPoints: 300)
        XCTAssertEqual(score, 100.0, accuracy: 0.1)
    }

    func testLoadScoreCapAt100() {
        // Over max trimp is capped at 100
        let score = ScoreEngine.loadScore(trimpPoints: 600)
        XCTAssertEqual(score, 100.0)
    }

    func testTrimpPointsFromSamples() {
        // 130/180 = 72.2% → zone 3 (×3.0); 153/180 = 85% → zone 4 (×4.5)
        // 30 min × 3.0 + 15 min × 4.5 = 90 + 67.5 = 157.5
        let samples: [(hr: Double, durationMinutes: Double)] = [
            (hr: 130, durationMinutes: 30), // zone 3 at maxHR=180
            (hr: 153, durationMinutes: 15), // zone 4 at maxHR=180
        ]
        let trimp = ScoreEngine.trimpPoints(heartRateSamples: samples, maxHR: 180)
        XCTAssertEqual(trimp, 157.5, accuracy: 0.1)
    }

    // MARK: - Readiness Score

    func testReadinessScoreNormalDay() {
        // today HRV == baseline → hrv_component = 50
        // sleep 80 → sleep_component = 24
        // today RHR == baseline → rhr_component = 20
        // total = 94
        let score = ScoreEngine.readinessScore(
            todayHRV: 65,
            recentHRVs: [60, 63, 65, 67, 70, 65, 65],
            sleepScore: 80,
            todayRHR: 54,
            baselineRHR: 54
        )
        XCTAssertGreaterThan(score, 85)
        XCTAssertLessThanOrEqual(score, 100)
    }

    func testReadinessScoreLowHRV() {
        // HRV half of baseline → hrv_component = 25
        let score = ScoreEngine.readinessScore(
            todayHRV: 30,
            recentHRVs: [60, 62, 64, 60, 62, 60, 60],
            sleepScore: 70,
            todayRHR: 56,
            baselineRHR: 54
        )
        XCTAssertLessThan(score, 70)
    }

    // MARK: - Sleep Debt

    func testSleepDebtPerfectWeek() {
        let debt = ScoreEngine.sleepDebt(last7DaysSleepHours: [8, 8, 8, 8, 8, 8, 8])
        XCTAssertEqual(debt, 0.0, accuracy: 0.01)
    }

    func testSleepDebtOneHourShortEachNight() {
        let debt = ScoreEngine.sleepDebt(last7DaysSleepHours: [7, 7, 7, 7, 7, 7, 7])
        XCTAssertEqual(debt, 1.0, accuracy: 0.01)
    }
}
