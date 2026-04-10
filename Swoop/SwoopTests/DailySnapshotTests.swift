import XCTest
import SwiftData
@testable import Swoop

final class DailySnapshotTests: XCTestCase {

    var container: ModelContainer!

    override func setUp() {
        super.setUp()
        container = try! ModelContainer(
            for: DailySnapshot.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    func testDateNormalizedToMidnight() {
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let snapshot = DailySnapshot(
            date: noon,
            readinessScore: 75, sleepScore: 80, loadScore: 40,
            hrv: 65, restingHR: 52, sleepHours: 7.5, sleepDebt: 0.5
        )
        let context = ModelContext(container)
        context.insert(snapshot)

        let hour = Calendar.current.component(.hour, from: snapshot.date)
        let minute = Calendar.current.component(.minute, from: snapshot.date)
        XCTAssertEqual(hour, 0)
        XCTAssertEqual(minute, 0)
    }

    func testInsertAndFetch() throws {
        let context = ModelContext(container)
        let snap = DailySnapshot(
            date: Date(),
            readinessScore: 73, sleepScore: 85, loadScore: 55,
            hrv: 68, restingHR: 54, sleepHours: 7.0, sleepDebt: 1.0
        )
        context.insert(snap)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<DailySnapshot>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].readinessScore, 73)
        XCTAssertEqual(fetched[0].hrv, 68)
    }
}
