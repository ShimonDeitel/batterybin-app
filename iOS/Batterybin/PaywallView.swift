import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var purchases: PurchaseManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundColor(Theme.accent)
                    Text("Batterybin Pro")
                        .font(Theme.titleFont)
                        .foregroundColor(Theme.textPrimary)
                    Text("Bulk reorder list plus smoke detector battery alerts")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("$2.99 one-time")
                        .font(Theme.headingFont)
                        .foregroundColor(Theme.accent)
                    Button {
                        Task {
                            await purchases.purchase()
                            if purchases.isPro { dismiss() }
                        }
                    } label: {
                        Text("Unlock Pro")
                            .font(Theme.headingFont)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .accessibilityIdentifier("purchaseButton")
                    .padding(.horizontal)

                    Button("Restore Purchases") {
                        Task { await purchases.restore() }
                    }
                    .accessibilityIdentifier("restorePaywallButton")
                    .foregroundColor(Theme.textSecondary)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("closePaywallButton")
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
