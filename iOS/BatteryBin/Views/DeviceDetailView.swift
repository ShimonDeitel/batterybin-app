import SwiftUI

struct DeviceDetailView: View {
    let deviceID: UUID

    @EnvironmentObject private var store: BatteryBinStore
    @EnvironmentObject private var entitlements: EntitlementsStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    private var device: Device? {
        store.data.devices.first { $0.id == deviceID }
    }

    private var status: DeviceStatus? {
        guard let device else { return nil }
        return BatteryLifeEngine.evaluate(device: device, now: Date())
    }

    var body: some View {
        ZStack {
            BBColor.paper.ignoresSafeArea()
            if let device, let status {
                Form {
                    Section {
                        HStack {
                            Circle()
                                .fill(BBColor.statusColor(status.status))
                                .frame(width: 14, height: 14)
                            Text(status.status.label)
                                .font(BBFont.heading(17))
                                .foregroundStyle(BBColor.statusColor(status.status))
                            Spacer()
                            Text("\(Int(status.percentUsed.rounded()))% used")
                                .font(BBFont.body(14))
                                .foregroundStyle(BBColor.graphite.opacity(0.6))
                        }
                        HStack {
                            Text("Days since change")
                            Spacer()
                            Text("\(status.daysSinceChange)")
                                .foregroundStyle(BBColor.graphite.opacity(0.6))
                        }
                    }

                    Section("Device") {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(device.name).foregroundStyle(BBColor.graphite.opacity(0.6))
                        }
                        if !device.room.isEmpty {
                            HStack {
                                Text("Room")
                                Spacer()
                                Text(device.room).foregroundStyle(BBColor.graphite.opacity(0.6))
                            }
                        }
                        HStack {
                            Text("Battery type")
                            Spacer()
                            Text(device.batteryType.displayName).foregroundStyle(BBColor.graphite.opacity(0.6))
                        }
                        HStack {
                            Text("Expected life")
                            Spacer()
                            Text("\(device.typicalLifeDays) days").foregroundStyle(BBColor.graphite.opacity(0.6))
                        }
                    }

                    Section {
                        Button {
                            store.markChanged(device)
                        } label: {
                            Label("Mark battery just changed", systemImage: "checkmark.circle.fill")
                        }
                        .foregroundStyle(BBColor.teal)
                    }

                    Section("Change history") {
                        if entitlements.isPro {
                            if device.changeHistory.isEmpty {
                                Text("No recorded changes yet. Tap \"Mark battery just changed\" above to start a history.")
                                    .font(BBFont.body(13))
                                    .foregroundStyle(BBColor.graphite.opacity(0.6))
                            } else {
                                ForEach(device.changeHistory.sorted { $0.date > $1.date }) { record in
                                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                }
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                Label("Unlock full change history with Pro", systemImage: "lock.fill")
                            }
                            .foregroundStyle(BBColor.volt)
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete device", systemImage: "trash")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            } else {
                Text("Device not found").foregroundStyle(BBColor.graphite.opacity(0.6))
            }
        }
        .navigationTitle(device?.name ?? "Device")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .confirmationDialog("Delete this device?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let device {
                    store.deleteDevice(device)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
