import SwiftUI

/// Battery Bin's bespoke "home utility" palette. Distinct from Whoseturn's warm cream/marigold
/// look — this app leans into a practical warm graphite background with an electric-yellow
/// accent for low-battery warnings, a teal for healthy status, and a rust red for overdue
/// devices, evoking a hardware-store label rather than a toy.
enum BBColor {
    static let paper = Color(red: 0.95, green: 0.94, blue: 0.91)
    static let graphite = Color(red: 0.16, green: 0.16, blue: 0.17)
    static let card = Color(red: 0.89, green: 0.87, blue: 0.82)
    static let volt = Color(red: 0.98, green: 0.85, blue: 0.10)
    static let teal = Color(red: 0.16, green: 0.45, blue: 0.46)
    static let rust = Color(red: 0.80, green: 0.27, blue: 0.19)
    static let steel = Color(red: 0.40, green: 0.49, blue: 0.55)

    /// Status colors keyed to BatteryLifeEngine.Status.
    static func statusColor(_ status: DeviceStatus.Status) -> Color {
        switch status {
        case .fresh: return teal
        case .checkSoon: return volt
        case .likelyDead: return rust
        }
    }
}

enum BBFont {
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func heading(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .regular, design: .rounded) }
}

/// Flat, utility-label style button shared across the app.
struct BBButtonStyle: ButtonStyle {
    var background: Color = BBColor.graphite
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BBFont.heading(17))
            .foregroundStyle(foreground)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A background view that dismisses the keyboard on tap-outside. Placed behind form content so
/// taps that land anywhere except an active control resign the responder.
struct KeyboardDismissBackground: View {
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
    }
}

extension View {
    /// Wraps the view with a full-size tap-to-dismiss-keyboard background. Use on any screen
    /// with a text field.
    func dismissesKeyboardOnTap() -> some View {
        self.background(KeyboardDismissBackground())
    }
}
