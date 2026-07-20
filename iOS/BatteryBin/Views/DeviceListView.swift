import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject private var store: BatteryBinStore
    @EnvironmentObject private var entitlements: EntitlementsStore
    @State private var showAddDevice = false
    @State private var showPaywall = false

    /// Smart "change soon" priority sort is a Pro feature. Free users see devices in the order
    /// they were added; Pro users see the most urgent device first, computed by
    /// BatteryLifeEngine.
    private var sortedStatuses: [DeviceStatus] {
        if entitlements.isPro {
            return BatteryLifeEngine.sortedByPriority(devices: store.data.devices, now: Date())
        } else {
            return store.data.devices.map { BatteryLifeEngine.evaluate(device: $0, now: Date()) }
        }
    }

    private func device(for status: DeviceStatus) -> Device? {
        store.data.devices.first { $0.id == status.deviceID }
    }

    var body: some View {
        ZStack {
            BBColor.paper.ignoresSafeArea()

            if store.data.devices.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    if AdsManager.adsEnabled(isPro: entitlements.isPro) {
                        HouseBannerView()
                            .padding(.top, 8)
                    }
                    List {
                        ForEach(sortedStatuses) { status in
                            if let device = device(for: status) {
                                NavigationLink {
                                    DeviceDetailView(deviceID: device.id)
                                } label: {
                                    deviceRow(device: device, status: status)
                                }
                                .listRowBackground(BBColor.paper)
                            }
                        }
                        .onDelete { offsets in
                            let statuses = sortedStatuses
                            for index in offsets {
                                if let device = device(for: statuses[index]) {
                                    store.deleteDevice(device)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                if store.canAddDevice {
                    showAddDevice = true
                } else {
                    showPaywall = true
                }
            } label: {
                Label("New Device", systemImage: "plus.circle.fill")
            }
            .buttonStyle(BBButtonStyle(background: BBColor.graphite))
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showAddDevice) { AddDeviceSheet() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func deviceRow(device: Device, status: DeviceStatus) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(BBColor.statusColor(status.status))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .font(BBFont.heading(18))
                    .foregroundStyle(BBColor.graphite)
                Text("\(device.room.isEmpty ? device.batteryType.displayName : "\(device.room) · \(device.batteryType.displayName)")")
                    .font(BBFont.body(13))
                    .foregroundStyle(BBColor.graphite.opacity(0.6))
            }
            Spacer()
            Text(status.status.label)
                .font(BBFont.body(13))
                .foregroundStyle(BBColor.statusColor(status.status))
        }
        .padding(.vertical, 6)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.batteryblock.fill")
                .font(.system(size: 64))
                .foregroundStyle(BBColor.volt)
            Text("No devices yet")
                .font(BBFont.title(22))
                .foregroundStyle(BBColor.graphite)
            Text("Add every battery-powered device in your home so Battery Bin can tell you when it's time to change them.")
                .font(BBFont.body(15))
                .foregroundStyle(BBColor.graphite.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 60)
    }
}
