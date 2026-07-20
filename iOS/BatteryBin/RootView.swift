import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: BatteryBinStore
    @State private var showSettings = false
    #if DEBUG
    @State private var path: [UUID] = []
    #endif

    var body: some View {
        #if DEBUG
        NavigationStack(path: $path) {
            DeviceListView()
                .navigationTitle("Battery Bin")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(BBColor.graphite)
                        }
                        .accessibilityLabel("Settings")
                    }
                }
                .navigationDestination(for: UUID.self) { deviceID in
                    DeviceDetailView(deviceID: deviceID)
                }
        }
        .tint(BBColor.graphite)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear {
            if ProcessInfo.processInfo.environment["BATTERYBIN_SCREENSHOT_DETAIL"] == "1",
               let first = store.data.devices.first {
                path = [first.id]
            }
        }
        #else
        NavigationStack {
            DeviceListView()
                .navigationTitle("Battery Bin")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(BBColor.graphite)
                        }
                        .accessibilityLabel("Settings")
                    }
                }
        }
        .tint(BBColor.graphite)
        .sheet(isPresented: $showSettings) { SettingsView() }
        #endif
    }
}
