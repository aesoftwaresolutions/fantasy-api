import SwiftUI

// "Chalk & Turf" — a visual identity drawn from the world of NFL fantasy:
// field-night navy, turf green, end-zone gold, chalk-white lettering, and
// scoreboard numerals. Centralized here so every screen stays consistent.
enum Theme {

    // MARK: Palette
    enum Palette {
        static let fieldNight = Color(hex: 0x0B1420)   // deep background
        static let fieldNight2 = Color(hex: 0x121E2E)  // raised surface
        static let turf = Color(hex: 0x1E7A46)         // primary
        static let turfBright = Color(hex: 0x2FA65F)   // primary highlight
        static let endZoneGold = Color(hex: 0xF4B740)  // accent / points
        static let chalk = Color(hex: 0xEDF1F5)        // primary text
        static let chalkDim = Color(hex: 0xB6C2D0)     // secondary text
        static let slate = Color(hex: 0x8A99AB)        // muted / captions
        static let hashLine = Color(hex: 0x24344A)     // dividers, borders
        static let jerseyRed = Color(hex: 0xE23D4C)    // destructive / errors
    }

    // MARK: Fonts — scoreboard display + clean body
    enum Fonts {
        // Display: uppercase, heavy, tightly tracked — a jersey/scoreboard voice.
        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .heavy, design: .default)
        }
        // Numerals that should line up like a scoreboard.
        static func score(_ size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
        }
    }

    // MARK: Metrics
    enum Metric {
        static let corner: CGFloat = 14
        static let cardPadding: CGFloat = 16
        static let spine: CGFloat = 4
    }
}

// MARK: - Color from hex (supports optional alpha in the low byte via 0xRRGGBBAA)
extension Color {
    init(hex: UInt32) {
        // If the value fits in 24 bits, treat it as RRGGBB (opaque);
        // otherwise treat it as RRGGBBAA.
        if hex <= 0xFFFFFF {
            let r = Double((hex >> 16) & 0xFF) / 255
            let g = Double((hex >> 8) & 0xFF) / 255
            let b = Double(hex & 0xFF) / 255
            self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
        } else {
            let r = Double((hex >> 24) & 0xFF) / 255
            let g = Double((hex >> 16) & 0xFF) / 255
            let b = Double((hex >> 8) & 0xFF) / 255
            let a = Double(hex & 0xFF) / 255
            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
        }
    }
}

// MARK: - Uppercase, tracked display text (the scoreboard voice)
struct DisplayText: View {
    let text: String
    var size: CGFloat = 28
    var color: Color = Theme.Palette.chalk

    init(_ text: String, size: CGFloat = 28, color: Color = Theme.Palette.chalk) {
        self.text = text
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.Fonts.display(size))
            .tracking(1.5)
            .foregroundColor(color)
    }
}

// MARK: - Eyebrow label (small, tracked, muted — a locker-room stencil)
struct Eyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(2)
            .foregroundColor(Theme.Palette.slate)
    }
}

// MARK: - Format / status chip (a jersey patch)
struct Chip: View {
    let text: String
    var tint: Color = Theme.Palette.turf

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(1)
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.16))
            .overlay(
                Capsule().strokeBorder(tint.opacity(0.4), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

// MARK: - Yard-line divider (evenly spaced hash marks, like field chalk)
struct YardLine: View {
    var body: some View {
        GeometryReader { geo in
            let count = max(Int(geo.size.width / 14), 1)
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { _ in
                    Rectangle()
                        .fill(Theme.Palette.hashLine)
                        .frame(width: 1, height: 6)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

// MARK: - The signature card: a jersey-stripe spine on a dark field surface
struct FieldCard<Content: View>: View {
    var spineColor: Color = Theme.Palette.turf
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(spineColor)
                .frame(width: Theme.Metric.spine)
            content
                .padding(Theme.Metric.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.Palette.fieldNight2)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metric.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metric.corner, style: .continuous)
                .strokeBorder(Theme.Palette.hashLine, lineWidth: 1)
        )
    }
}

// MARK: - Field background (night sky over turf, with a faint 50-yard glow)
struct FieldBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.Palette.fieldNight, Color(hex: 0x0E1A2A)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Theme.Palette.turf.opacity(0.18), .clear],
                center: .bottom,
                startRadius: 20,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Primary action button (turf, full-width, heavy)
struct KickoffButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .heavy))
            .tracking(1)
            .foregroundColor(Theme.Palette.chalk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [Theme.Palette.turfBright, Theme.Palette.turf],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - An inline error banner in the interface's own voice
struct ErrorBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Theme.Palette.endZoneGold)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Palette.chalk)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.Palette.jerseyRed.opacity(0.14))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Theme.Palette.jerseyRed.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Dark field-styled text field
struct FieldTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .never

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(title)
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(autocap)
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Theme.Palette.chalk)
            .tint(Theme.Palette.endZoneGold)
            .padding(.vertical, 11)
            .padding(.horizontal, 12)
            .background(Theme.Palette.fieldNight)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Theme.Palette.hashLine, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
