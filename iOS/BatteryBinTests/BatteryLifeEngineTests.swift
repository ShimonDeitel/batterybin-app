import XCTest
@testable import BatteryBin

/// Deterministic core-logic tests for BatteryLifeEngine: no UI, no persistence, no network —
/// every expected value below was hand-verified against the formulas
/// `daysSinceChange = max(0, days between lastChangedDate and now)` and
/// `percentUsed = daysSinceChange / typicalLifeDays * 100`, with status boundaries
/// fresh (<70), checkSoon (70...100), likelyDead (>100).
final class BatteryLifeEngineTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private let referenceNow = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 7, day: 20))!

    private func daysAgo(_ days: Int, from now: Date? = nil) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now ?? referenceNow)!
    }

    private func device(
        typicalLifeDays: Int,
        lastChangedDaysAgo: Int
    ) -> Device {
        Device(name: "Test Device", typicalLifeDays: typicalLifeDays, lastChangedDate: daysAgo(lastChangedDaysAgo))
    }

    // MARK: daysSinceChange

    func testDaysSinceChangeZeroWhenChangedToday() {
        let days = BatteryLifeEngine.daysSinceChange(lastChangedDate: referenceNow, now: referenceNow)
        XCTAssertEqual(days, 0)
    }

    func testDaysSinceChangeClampsToZeroForFutureDate() {
        let futureDate = calendar.date(byAdding: .day, value: 5, to: referenceNow)!
        let days = BatteryLifeEngine.daysSinceChange(lastChangedDate: futureDate, now: referenceNow)
        XCTAssertEqual(days, 0)
    }

    func testDaysSinceChangeCountsWholeDays() {
        let days = BatteryLifeEngine.daysSinceChange(lastChangedDate: daysAgo(42), now: referenceNow)
        XCTAssertEqual(days, 42)
    }

    // MARK: percentUsed

    func testPercentUsedZeroWhenNoDaysHavePassed() {
        XCTAssertEqual(BatteryLifeEngine.percentUsed(daysSinceChange: 0, typicalLifeDays: 180), 0.0)
    }

    func testPercentUsedExactHalf() {
        // 90 / 180 * 100 = 50
        XCTAssertEqual(BatteryLifeEngine.percentUsed(daysSinceChange: 90, typicalLifeDays: 180), 50.0, accuracy: 0.0001)
    }

    func testPercentUsedGuardsNonPositiveLifespanWithDaysPassed() {
        // typicalLifeDays <= 0 is invalid input; treated as already expired when any days passed.
        XCTAssertEqual(BatteryLifeEngine.percentUsed(daysSinceChange: 10, typicalLifeDays: 0), 999.0)
        XCTAssertEqual(BatteryLifeEngine.percentUsed(daysSinceChange: 10, typicalLifeDays: -5), 999.0)
    }

    func testPercentUsedGuardsNonPositiveLifespanWithZeroDays() {
        XCTAssertEqual(BatteryLifeEngine.percentUsed(daysSinceChange: 0, typicalLifeDays: 0), 0.0)
    }

    func testPercentUsedVeryOldDeviceFarExceeds100() {
        // 3650 days (10 years) / 180 * 100 ≈ 2027.8
        let percent = BatteryLifeEngine.percentUsed(daysSinceChange: 3650, typicalLifeDays: 180)
        XCTAssertEqual(percent, 2027.777_78, accuracy: 0.01)
    }

    // MARK: status boundaries

    func testStatusFreshBelow70() {
        XCTAssertEqual(BatteryLifeEngine.status(forPercentUsed: 0), .fresh)
        XCTAssertEqual(BatteryLifeEngine.status(forPercentUsed: 69.999), .fresh)
    }

    func testStatusExactly70IsCheckSoon() {
        XCTAssertEqual(BatteryLifeEngine.status(forPercentUsed: 70.0), .checkSoon)
    }

    func testStatusExactly100IsCheckSoon() {
        XCTAssertEqual(BatteryLifeEngine.status(forPercentUsed: 100.0), .checkSoon)
    }

    func testStatusJustOver100IsLikelyDead() {
        XCTAssertEqual(BatteryLifeEngine.status(forPercentUsed: 100.001), .likelyDead)
    }

    func testStatusFarOver100IsLikelyDead() {
        XCTAssertEqual(BatteryLifeEngine.status(forPercentUsed: 500), .likelyDead)
    }

    // MARK: evaluate — end-to-end single device

    func testEvaluateZeroDaysSinceChangeIsFresh() {
        let d = device(typicalLifeDays: 180, lastChangedDaysAgo: 0)
        let result = BatteryLifeEngine.evaluate(device: d, now: referenceNow)
        XCTAssertEqual(result.daysSinceChange, 0)
        XCTAssertEqual(result.percentUsed, 0.0)
        XCTAssertEqual(result.status, .fresh)
    }

    func testEvaluateAtExactly70PercentBoundary() {
        // typicalLifeDays 100, 70 days since change -> exactly 70%.
        let d = device(typicalLifeDays: 100, lastChangedDaysAgo: 70)
        let result = BatteryLifeEngine.evaluate(device: d, now: referenceNow)
        XCTAssertEqual(result.percentUsed, 70.0, accuracy: 0.0001)
        XCTAssertEqual(result.status, .checkSoon)
    }

    func testEvaluateAtExactly100PercentBoundary() {
        let d = device(typicalLifeDays: 100, lastChangedDaysAgo: 100)
        let result = BatteryLifeEngine.evaluate(device: d, now: referenceNow)
        XCTAssertEqual(result.percentUsed, 100.0, accuracy: 0.0001)
        XCTAssertEqual(result.status, .checkSoon)
    }

    func testEvaluateJustOver100PercentIsLikelyDead() {
        let d = device(typicalLifeDays: 100, lastChangedDaysAgo: 101)
        let result = BatteryLifeEngine.evaluate(device: d, now: referenceNow)
        XCTAssertGreaterThan(result.percentUsed, 100.0)
        XCTAssertEqual(result.status, .likelyDead)
    }

    func testEvaluateVeryOldDeviceIsLikelyDead() {
        let d = device(typicalLifeDays: 90, lastChangedDaysAgo: 3000)
        let result = BatteryLifeEngine.evaluate(device: d, now: referenceNow)
        XCTAssertEqual(result.status, .likelyDead)
        XCTAssertGreaterThan(result.percentUsed, 1000)
    }

    // MARK: sortedByPriority

    func testSortedByPriorityEmptyListReturnsEmpty() {
        let result = BatteryLifeEngine.sortedByPriority(devices: [], now: referenceNow)
        XCTAssertTrue(result.isEmpty)
    }

    func testSortedByPriorityOrdersHighestPercentFirst() {
        // A: 30/180 = 16.67%, B: 170/180 = 94.44%, C: 200/180 = 111.11% (likely dead)
        var a = device(typicalLifeDays: 180, lastChangedDaysAgo: 30); a.name = "A"
        var b = device(typicalLifeDays: 180, lastChangedDaysAgo: 170); b.name = "B"
        var c = device(typicalLifeDays: 180, lastChangedDaysAgo: 200); c.name = "C"

        let result = BatteryLifeEngine.sortedByPriority(devices: [a, b, c], now: referenceNow)

        XCTAssertEqual(result.map(\.deviceID), [c.id, b.id, a.id])
        XCTAssertEqual(result[0].status, .likelyDead)
        XCTAssertEqual(result[1].status, .checkSoon)
        XCTAssertEqual(result[2].status, .fresh)
    }

    func testSortedByPriorityTiesKeepOriginalOrder() {
        // Both devices have identical percentUsed (50%), so the stable sort must preserve the
        // order they were passed in: A before B.
        var a = device(typicalLifeDays: 180, lastChangedDaysAgo: 90); a.name = "A"
        var b = device(typicalLifeDays: 200, lastChangedDaysAgo: 100); b.name = "B"

        XCTAssertEqual(
            BatteryLifeEngine.percentUsed(daysSinceChange: 90, typicalLifeDays: 180),
            BatteryLifeEngine.percentUsed(daysSinceChange: 100, typicalLifeDays: 200),
            accuracy: 0.0001
        )

        let result = BatteryLifeEngine.sortedByPriority(devices: [a, b], now: referenceNow)
        XCTAssertEqual(result.map(\.deviceID), [a.id, b.id])
    }
}
