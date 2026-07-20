import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var entitlements: EntitlementsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BBColor.paper.ignoresSafeArea()
                VStack(spacing: 22) {
                    Image(systemName: "bolt.batteryblock.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(BBColor.volt)
                        .padding(.top, 12)

                    Text("Battery Bin Pro")
                        .font(BBFont.title(26))
                        .foregroundStyle(BBColor.graphite)

                    VStack(alignment: .leading, spacing: 14) {
                        featureRow(icon: "square.stack.3d.up.fill", text: "Unlimited devices")
                        featureRow(icon: "arrow.up.arrow.down.circle.fill", text: "Smart \"change soon\" priority sort")
                        featureRow(icon: "clock.arrow.circlepath", text: "Full battery change history")
                        featureRow(icon: "xmark.circle.fill", text: "No ads")
                    }
                    .padding()
                    .background(BBColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Spacer()

                    Button {
                        Task {
                            let success = await entitlements.purchase()
                            if success { dismiss() }
                        }
                    } label: {
                        Text(entitlements.purchaseInFlight ? "Processing..." : "Subscribe — \(entitlements.displayPrice)/month")
                    }
                    .buttonStyle(BBButtonStyle(background: BBColor.graphite))
                    .disabled(entitlements.purchaseInFlight)

                    Text("Auto-renewable subscription, billed monthly to your Apple ID. Manage or cancel anytime in Settings.")
                        .font(BBFont.body(12))
                        .foregroundStyle(BBColor.graphite.opacity(0.55))
                        .multilineTextAlignment(.center)

                    Button("Restore Purchases") {
                        Task { await entitlements.restore() }
                    }
                    .font(BBFont.body(14))
                    .foregroundStyle(BBColor.teal)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(BBColor.teal)
                .frame(width: 24)
            Text(text)
                .font(BBFont.body(15))
                .foregroundStyle(BBColor.graphite)
        }
    }
}
