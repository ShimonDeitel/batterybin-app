import Foundation

/// Common household battery sizes/types. `.other` carries a free-text label for anything
/// unusual (coin cells, camera packs, etc).
public enum BatteryType: Codable, Equatable, Hashable {
    case aa
    case aaa
    case c
    case d
    case nineVolt
    case cr2032
    case other(String)

    public var displayName: String {
        switch self {
        case .aa: return "AA"
        case .aaa: return "AAA"
        case .c: return "C"
        case .d: return "D"
        case .nineVolt: return "9V"
        case .cr2032: return "CR2032"
        case .other(let label): return label.isEmpty ? "Other" : label
        }
    }

    /// Standard cases offered in pickers, in display order. `.other("")` is appended by the
    /// caller when a custom label is needed.
    public static let standardCases: [BatteryType] = [.aa, .aaa, .c, .d, .nineVolt, .cr2032]
}

/// A record of one completed battery change, kept for Pro full change-history.
public struct ChangeRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public let date: Date

    public init(id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.date = date
    }
}

/// A single tracked household device.
public struct Device: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var room: String
    public var batteryType: BatteryType
    /// Expected battery life for this device, in days. User-editable, seeded from a preset.
    public var typicalLifeDays: Int
    public var lastChangedDate: Date
    /// Pro feature: every past change date, oldest first. Free tier only ever sees the single
    /// current `lastChangedDate`.
    public var changeHistory: [ChangeRecord]

    public init(
        id: UUID = UUID(),
        name: String,
        room: String = "",
        batteryType: BatteryType = .aa,
        typicalLifeDays: Int = 180,
        lastChangedDate: Date = Date(),
        changeHistory: [ChangeRecord] = []
    ) {
        self.id = id
        self.name = name
        self.room = room
        self.batteryType = batteryType
        self.typicalLifeDays = typicalLifeDays
        self.lastChangedDate = lastChangedDate
        self.changeHistory = changeHistory
    }
}

/// A common device type with a sensible default battery type + expected life, offered when
/// adding a new device so users don't have to guess a lifespan.
public struct DevicePreset: Identifiable, Equatable, Hashable {
    public var id: String { name }
    public let name: String
    public let batteryType: BatteryType
    public let typicalLifeDays: Int

    public static let all: [DevicePreset] = [
        DevicePreset(name: "Smoke Detector", batteryType: .nineVolt, typicalLifeDays: 270),
        DevicePreset(name: "TV Remote", batteryType: .aaa, typicalLifeDays: 180),
        DevicePreset(name: "Wall Clock", batteryType: .aa, typicalLifeDays: 365),
        DevicePreset(name: "Doorbell", batteryType: .aa, typicalLifeDays: 200),
        DevicePreset(name: "Key Fob", batteryType: .cr2032, typicalLifeDays: 365),
        DevicePreset(name: "Flashlight", batteryType: .d, typicalLifeDays: 120),
        DevicePreset(name: "Thermostat", batteryType: .aa, typicalLifeDays: 365),
        DevicePreset(name: "Game Controller", batteryType: .aa, typicalLifeDays: 60),
        DevicePreset(name: "Weather Station", batteryType: .aaa, typicalLifeDays: 240),
        DevicePreset(name: "Other", batteryType: .aa, typicalLifeDays: 180),
    ]
}

/// Top-level persisted document.
public struct BatteryBinData: Codable, Equatable {
    public var devices: [Device]

    public init(devices: [Device] = []) {
        self.devices = devices
    }
}

public enum FreeTierLimits {
    public static let maxDevices = 5
}
