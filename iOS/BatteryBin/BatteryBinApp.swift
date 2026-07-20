import SwiftUI

@main
struct BatteryBinApp: App {
    @StateObject private var entitlements: EntitlementsStore
    @StateObject private var store: BatteryBinStore

    init() {
        let entitlementsStore = EntitlementsStore()
        _entitlements = StateObject(wrappedValue: entitlementsStore)
        _store = StateObject(wrappedValue: BatteryBinStore(entitlements: entitlementsStore))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(entitlements)
                .preferredColorScheme(.light)
        }
    }
}
