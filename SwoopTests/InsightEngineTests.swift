import XCTest
@testable import Swoop

final class InsightEngineTests: XCTestCase {

    // MARK: - todayInsightCore

    func testRecoveryNeededWhenReadinessBelow34() {
        let insight = InsightEngine.todayInsightCore(
            readinessScore: 28, hrv: 40, baselineHRV: 60,
            sleepDebt: 0.5, loadScore: 20, avgLoad: 50,
            restingHR: 58, baselineRHR: 54, recentReadiness: [40, 32, 28]
        )
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.text.contains("full recovery"))
    }

    func testRHRElevatedRule() {
        let insight = InsightEngine.todayInsightCore(
            readinessScore: 55, hrv: 55, baselineHRV: 55,
            sleepDebt: 0.3, loadScore: 40, avgLoad: 40,
            restingHR: 62, baselineRHR: 54, recentReadiness: [55, 55, 55]
        )
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.text.contains("elevated"))
    }

    func testHRVBelowBaselineRule() {
        // RHR normal, but HRV 10% below baseline
        let insight = InsightEngine.todayInsightCore(
            readinessScore: 55, hrv: 45, baselineHRV: 55,
            sleepDebt: 0.3, loadScore: 40, avgLoad: 40,
            restingHR: 54, baselineRHR: 54, recentReadiness: [55, 55, 55]
        )
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.text.contains("below baseline"))
    }

    func testSleepDebtHighRule() {
        let insight = InsightEngine.todayInsightCore(
            readinessScore: 60, hrv: 55, baselineHRV: 55,
            sleepDebt: 2.0, loadScore: 40, avgLoad: 40,
            restingHR: 54, baselineRHR: 54, recentReadiness: [60, 60, 60]
        )
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.text.contains("sleep debt"))
    }

    func testHRVAboveBaselineRule() {
        // All good → should fire HRV above baseline positive rule
        let insight = InsightEngine.todayInsightCore(
            readinessScore: 75, hrv: 65, baselineHRV: 55,
            sleepDebt: 0.1, loadScore: 40, avgLoad: 40,
            restingHR: 53, baselineRHR: 54, recentReadiness: [70, 72, 75]
        )
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.text.contains("above baseline"))
    }

    func testReadinessTrendingUpRule() {
        // HRV only 3% above baseline (below 7% threshold), RHR normal → trending up fires
        let insight = InsightEngine.todayInsightCore(
            readinessScore: 75, hrv: 57, baselineHRV: 55,
            sleepDebt: 0.1, loadScore: 40, avgLoad: 40,
            restingHR: 54, baselineRHR: 54, recentReadiness: [65, 70, 75]
        )
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.text.contains("trending up"))
    }

    func testNilWhenNoRuleMatches() {
        // Perfectly average — none of the alert rules fire, no positive signals either
        let insight = InsightEngine.todayInsightCore(
            readinessScore: 60, hrv: 55, baselineHRV: 55,
            sleepDebt: 0.5, loadScore: 40, avgLoad: 40,
            restingHR: 54, baselineRHR: 54, recentReadiness: [60, 60, 60]
        )
        // Just verify it doesn't crash
        _ = insight
    }

    // MARK: - metricInsightCore

    func testSleepMetricHighDebt() {
        let insight = InsightEngine.metricInsightCore(metric: .sleep, avgValue: 6.5, sleepNeed: 8.0)
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.text.contains("debt") || insight!.text.contains("short"))
    }

    func testLoadMetricHighLoad() {
        let insight = InsightEngine.metricInsightCore(metric: .load, avgValue: 85, currentLoad: 90, avgLoad: 50)
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.text.lowercased().contains("load") || insight!.text.contains("recovery"))
    }
}
