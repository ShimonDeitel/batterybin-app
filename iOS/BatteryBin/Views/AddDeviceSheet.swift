import SwiftUI

struct AddDeviceSheet: View {
    @EnvironmentObject private var store: BatteryBinStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var room = ""
    @State private var selectedPreset: DevicePreset?
    @State private var batteryType: BatteryType = .aa
    @State private var typicalLifeDays = 180
    @State private var lastChangedDate = Date()
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                BBColor.paper.ignoresSafeArea()
                Form {
                    Section("Device") {
                        TextField("Name, e.g. Living Room Remote", text: $name)
                            .focused($nameFieldFocused)
                        TextField("Room (optional)", text: $room)
                    }

                    Section("Common device presets") {
                        Picker("Preset", selection: $selectedPreset) {
                            Text("Custom").tag(Optional<DevicePreset>.none)
                            ForEach(DevicePreset.all) { preset in
                                Text(preset.name).tag(Optional(preset))
                            }
                        }
                        .onChange(of: selectedPreset) { _, newValue in
                            guard let newValue else { return }
                            batteryType = newValue.batteryType
                            typicalLifeDays = newValue.typicalLifeDays
                            if name.isEmpty { name = newValue.name }
                        }
                    }

                    Section("Battery") {
                        Picker("Battery type", selection: $batteryType) {
                            ForEach(BatteryType.standardCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        Stepper("Expected life: \(typicalLifeDays) days", value: $typicalLifeDays, in: 1...1000)
                    }

                    Section("Last changed") {
                        DatePicker("Last changed", selection: $lastChangedDate, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            // Real tap-outside-to-dismiss-keyboard: a full-size background beneath the form
            // content that resigns first responder on tap, independent of scroll-based dismissal.
            .dismissesKeyboardOnTap()
            .navigationTitle("New Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        let device = Device(
                            name: trimmedName,
                            room: room.trimmingCharacters(in: .whitespacesAndNewlines),
                            batteryType: batteryType,
                            typicalLifeDays: typicalLifeDays,
                            lastChangedDate: lastChangedDate
                        )
                        store.addDevice(device)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
