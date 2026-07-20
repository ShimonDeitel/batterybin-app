import Foundation
import Combine

/// Local-only persistence for Battery Bin: Codable JSON written to the app's Documents directory
/// via FileManager. No network calls, no CloudKit, no iCloud entitlements — everything lives on
/// this device only.
@MainActor
final class BatteryBinStore: ObservableObject {
    @Published private(set) var data: BatteryBinData

    private let fileURL: URL
    private let entitlements: EntitlementsStore

    init(entitlements: EntitlementsStore, fileURL: URL? = nil) {
        self.entitlements = entitlements
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("batterybin_data.json")
        }
        self.data = BatteryBinStore.load(from: self.fileURL) ?? BatteryBinData()
        #if DEBUG
        if ProcessInfo.processInfo.environment["BATTERYBIN_SEED_SCREENSHOTS"] == "1", data.devices.isEmpty {
            seedScreenshotData()
        }
        #endif
    }

    #if DEBUG
    private func seedScreenshotData() {
        let calendar = Calendar(identifier: .gregorian)
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
        data.devices = [
            Device(name: "Smoke Detector", room: "Hallway", batteryType: .nineVolt,
                   typicalLifeDays: 270, lastChangedDate: daysAgo(280)),
            Device(name: "Living Room Remote", room: "Living Room", batteryType: .aaa,
                   typicalLifeDays: 180, lastChangedDate: daysAgo(140)),
            Device(name: "Wall Clock", room: "Kitchen", batteryType: .aa,
                   typicalLifeDays: 365, lastChangedDate: daysAgo(30)),
            Device(name: "Key Fob", room: "Garage", batteryType: .cr2032,
                   typicalLifeDays: 365, lastChangedDate: daysAgo(400)),
        ]
        persist()
    }
    #endif

    // MARK: Loading / saving

    private static func load(from url: URL) -> BatteryBinData? {
        guard let raw = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(BatteryBinData.self, from: raw)
    }

    private func persist() {
        guard let raw = try? JSONEncoder().encode(data) else { return }
        try? raw.write(to: fileURL, options: .atomic)
    }

    // MARK: Limits

    var canAddDevice: Bool {
        entitlements.isPro || data.devices.count < FreeTierLimits.maxDevices
    }

    // MARK: Devices

    @discardableResult
    func addDevice(_ device: Device) -> Bool {
        guard canAddDevice else { return false }
        data.devices.append(device)
        persist()
        return true
    }

    func deleteDevice(_ device: Device) {
        data.devices.removeAll { $0.id == device.id }
        persist()
    }

    func updateDevice(_ device: Device) {
        guard let index = data.devices.firstIndex(where: { $0.id == device.id }) else { return }
        data.devices[index] = device
        persist()
    }

    /// Marks a device as freshly changed (resets its last-changed date to now). Full change
    /// history is a Pro feature: the record is only appended when the user is Pro, matching the
    /// free-tier limits described in Settings and the paywall.
    func markChanged(_ device: Device, now: Date = Date()) {
        guard let index = data.devices.firstIndex(where: { $0.id == device.id }) else { return }
        data.devices[index].lastChangedDate = now
        if entitlements.isPro {
            data.devices[index].changeHistory.append(ChangeRecord(date: now))
        }
        persist()
    }
}
