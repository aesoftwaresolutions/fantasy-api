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

    // MARK: Motion — one spring for the whole app so movement feels consistent.
    enum Motion {
        static let spring = Animation.spring(response: 0.42, dampingFraction: 0.82)
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.9)
    }
}

// MARK: - Liquid Glass surface (iOS 26) with a material fallback for iOS 17–25.
// Used for surfaces that float over scrolling content (toolbars, floating bars).
// Glass cannot sample other glass, so wrap grouped glass in GlassEffectContainer.
extension View {
    @ViewBuilder
    func glassSurface(cornerRadius: CGFloat = Theme.Metric.corner) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
}

// MARK: - Light haptic tap, used to confirm discrete actions (copy, add).
enum Haptics {
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
            .shadow(color: Theme.Palette.turf.opacity(configuration.isPressed ? 0.15 : 0.35), radius: configuration.isPressed ? 4 : 12, y: configuration.isPressed ? 2 : 6)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.Motion.snappy, value: configuration.isPressed)
    }
}

// Position color coding — a quick visual read of the roster, like a depth chart.
func positionTint(_ position: String?) -> Color {
    switch position {
    case "QB": return Theme.Palette.endZoneGold
    case "RB": return Theme.Palette.turfBright
    case "WR": return Color(hex: 0x4FA3E3)
    case "TE": return Color(hex: 0xB98CE0)
    case "K": return Theme.Palette.slate
    case "DEF": return Color(hex: 0xE07B4F)
    default: return Theme.Palette.slate
    }
}

// MARK: - Player headshot with skeleton loading and a position-colored fallback
struct PlayerHeadshot: View {
    let url: String?
    let position: String
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL, transaction: Transaction(animation: Theme.Motion.spring)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .empty:
                        placeholder.overlay(ProgressView().tint(Theme.Palette.slate).scaleEffect(0.6))
                    case .failure:
                        fallback
                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .background(Theme.Palette.fieldNight)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(positionTint(position).opacity(0.6), lineWidth: 2))
    }

    private var placeholder: some View {
        Circle().fill(Theme.Palette.fieldNight2)
    }

    // Initials on a position-tinted disc when there's no photo.
    private var fallback: some View {
        ZStack {
            Circle().fill(positionTint(position).opacity(0.22))
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(positionTint(position))
        }
    }
}

// MARK: - Skeleton placeholder rows for list loading states
struct SkeletonRows: View {
    var count: Int = 6
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle().fill(Theme.Palette.fieldNight2).frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4).fill(Theme.Palette.fieldNight2).frame(width: 140, height: 12)
                        RoundedRectangle(cornerRadius: 4).fill(Theme.Palette.fieldNight2).frame(width: 70, height: 10)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Theme.Palette.fieldNight2.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .shimmering()
        .accessibilityHidden(true)
    }
}

// MARK: - Shimmer effect for skeletons
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.12), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * phase)
                }
                .allowsHitTesting(false)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1.6
                }
            }
    }
}

extension View {
    func shimmering() -> some View { modifier(Shimmer()) }
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
