import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var entitlements: EntitlementsStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    private let privacyURL = URL(string: "https://shimondeitel.github.io/batterybin-app/privacy.html")!
    private let termsURL = URL(string: "https://shimondeitel.github.io/batterybin-app/terms.html")!

    var body: some View {
        NavigationStack {
            ZStack {
                BBColor.paper.ignoresSafeArea()
                List {
                    Section {
                        HStack {
                            Text("Plan")
                            Spacer()
                            Text(entitlements.isPro ? "Pro" : "Free")
                                .foregroundStyle(entitlements.isPro ? BBColor.teal : BBColor.graphite.opacity(0.6))
                        }
                        if !entitlements.isPro {
                            Button("Upgrade to Pro") { showPaywall = true }
                                .foregroundStyle(BBColor.volt.opacity(0.9))
                        } else {
                            Button("Restore Purchases") {
                                Task { await entitlements.restore() }
                            }
                        }
                    }

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0")
                                .foregroundStyle(BBColor.graphite.opacity(0.6))
                        }
                        Text("Battery Bin keeps every device, battery type, and change date stored only on this device using local file storage. There is no CloudKit sync and no account — nothing is uploaded anywhere.")
                            .font(BBFont.body(13))
                            .foregroundStyle(BBColor.graphite.opacity(0.6))
                        Link("Privacy Policy", destination: privacyURL)
                        Link("Terms of Use", destination: termsURL)
                    }

                    Section("More Apps") {
                        ForEach(MoreApps.others(than: "Battery Bin - Battery Tracker")) { app in
                            Link(app.name, destination: app.url)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}
