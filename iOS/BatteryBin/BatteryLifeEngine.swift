import Foundation

/// Standalone, UI-independent battery-life prediction for Battery Bin.
///
/// Pure data — no UI, no persistence framework beyond Codable/Equatable — so this type (and the
/// engine below) can be unit tested with plain Swift values and an injected `now`.
public struct DeviceStatus: Identifiable, Equatable {
    public enum Status: String, Equatable {
        case fresh
        case checkSoon
        case likelyDead

        public var label: String {
            switch self {
            case .fresh: return "Fresh"
            case .checkSoon: return "Check soon"
            case .likelyDead: return "Likely dead"
            }
        }
    }

    public let deviceID: UUID
    public let daysSinceChange: Int
    public let percentUsed: Double
    public let status: Status

    public var id: UUID { deviceID }

    public init(deviceID: UUID, daysSinceChange: Int, percentUsed: Double, status: Status) {
        self.deviceID = deviceID
        self.daysSinceChange = daysSinceChange
        self.percentUsed = percentUsed
        self.status = status
    }
}

/// Rules implemented:
/// 1. `daysSinceChange` is the whole number of calendar days between `lastChangedDate` and `now`,
///    clamped to zero if `lastChangedDate` is in the future (e.g. a clock skew or a device just
///    added with "today" as its last-changed date).
/// 2. `percentUsed` = daysSinceChange / typicalLifeDays * 100. A `typicalLifeDays` of zero or
///    less is invalid input (no meaningful lifespan), so it is treated as already fully expired
///    (a very large percentage) rather than crashing on divide-by-zero, unless no days have
///    passed yet, which is defined as 0%.
/// 3. Status thresholds (percent of expected life used), matching the product spec exactly at
///    the boundaries:
///      - Fresh:       percentUsed < 70
///      - Check soon:  70 <= percentUsed <= 100
///      - Likely dead: percentUsed > 100
/// 4. Sorting is highest-percent-used first (most urgent at the top), using a stable sort so
///    devices that tie on percentUsed keep their original relative order.
public enum BatteryLifeEngine {

    /// Whole days between `lastChangedDate` and `now`, clamped to a minimum of 0.
    public static func daysSinceChange(lastChangedDate: Date, now: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: lastChangedDate)
        let end = calendar.startOfDay(for: now)
        let components = calendar.dateComponents([.day], from: start, to: end)
        let days = components.day ?? 0
        return max(0, days)
    }

    /// Percent of expected life used. Guards against a non-positive `typicalLifeDays`.
    public static func percentUsed(daysSinceChange: Int, typicalLifeDays: Int) -> Double {
        guard typicalLifeDays > 0 else {
            return daysSinceChange > 0 ? 999.0 : 0.0
        }
        return (Double(daysSinceChange) / Double(typicalLifeDays)) * 100.0
    }

    /// Status label for a given percent-used value. Boundaries are inclusive as documented above.
    public static func status(forPercentUsed percentUsed: Double) -> DeviceStatus.Status {
        if percentUsed > 100 {
            return .likelyDead
        } else if percentUsed >= 70 {
            return .checkSoon
        } else {
            return .fresh
        }
    }

    /// Evaluates a single device against `now`.
    public static func evaluate(device: Device, now: Date) -> DeviceStatus {
        let days = daysSinceChange(lastChangedDate: device.lastChangedDate, now: now)
        let percent = percentUsed(daysSinceChange: days, typicalLifeDays: device.typicalLifeDays)
        return DeviceStatus(
            deviceID: device.id,
            daysSinceChange: days,
            percentUsed: percent,
            status: status(forPercentUsed: percent)
        )
    }

    /// Evaluates every device and returns them sorted highest-percent-used first (most overdue /
    /// most urgent at the top). Ties keep their original relative order (stable sort). An empty
    /// input returns an empty array.
    public static func sortedByPriority(devices: [Device], now: Date) -> [DeviceStatus] {
        let evaluated = devices.map { evaluate(device: $0, now: now) }
        return evaluated.sorted { $0.percentUsed > $1.percentUsed }
    }
}
