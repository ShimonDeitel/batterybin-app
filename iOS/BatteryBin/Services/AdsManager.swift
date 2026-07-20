import SwiftUI

/// Ad layer. Real network (AdMob) requires the GoogleMobileAds SDK + an
/// AdMob account, which needs an owner login — so v1 ships with a
/// self-promo house-ad banner (cross-promotes the portfolio, fully
/// App-Store-legal) shown only to free-tier users. Swapping in AdMob later
/// means replacing `HouseBannerView` with a `GADBannerView` wrapper; the
/// `adsEnabled` gate and placement stay the same.
enum AdsManager {
    static func adsEnabled(isPro: Bool) -> Bool { !isPro }
}

/// House banner shown at the top of the device list for free users.
struct HouseBannerView: View {
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(BBColor.volt.opacity(0.25))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "bolt.fill").foregroundStyle(BBColor.graphite))
            VStack(alignment: .leading, spacing: 2) {
                Text("Ad").font(BBFont.body(11)).foregroundStyle(BBColor.graphite.opacity(0.5))
                Text("Remove ads with Battery Bin Pro").font(BBFont.heading(14)).foregroundStyle(BBColor.graphite)
            }
            Spacer()
        }
        .padding(12)
        .background(BBColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }
}
