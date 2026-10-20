// Excerpt from Mise (private source). Shared to show the design system; not buildable on its own.

import SwiftUI
import UIKit
import CoreText

// MARK: - Colors ("Oat and Sage"; adapts to light and dark)

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { t in
            let v = t.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                           blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        })
    }
}

enum Theme {
    static let bg = Color(light: 0xF3F0E8, dark: 0x1B201D)
    static let surface = Color(light: 0xFFFDF9, dark: 0x252C28)
    static let surface2 = Color(light: 0xEAE5DA, dark: 0x2F3732)
    static let ink = Color(light: 0x26302B, dark: 0xEDE9E0)
    static let muted = Color(light: 0x5F6862, dark: 0xA9B0AA)
    static let line = Color(light: 0xE2DDD2, dark: 0x37403A)
    /// Links, the app tint and database-backed numbers.
    static let accent = Color(light: 0x3F7A57, dark: 0x9CC3A4)
    /// The one "do this next" control on a screen: the log button, Log dinner, Continue.
    static let action = Color(light: 0xC6DDB4, dark: 0xC6DDB4)
    static let onAction = Color(light: 0x26302B, dark: 0x26302B)
    /// Dark ground for onboarding and goal summaries, in both appearances. Lighter than `surface`
    /// in dark mode, so a night card or pill still stands off the page.
    static let night = Color(light: 0x2B3530, dark: 0x34413A)
    static let onNight = Color(light: 0xF6F3EC, dark: 0xF6F3EC)

    // Macros share the logo's "Market" family, so the plate on Today matches the brand.
    static let protein = Color(light: 0x7FA98A, dark: 0xA9C9A4)
    static let carbs = Color(light: 0xE2B15A, dark: 0xE9C077)
    static let fat = Color(light: 0xE39A73, dark: 0xF2B596)
    static let fiber = Color(light: 0x6E9E5A, dark: 0x9CC27F)

    // Sources other than USDA (which uses `accent`).
    static let label = Color(light: 0x7C8DB0, dark: 0xA3B1CF)
    static let fatsecret = Color(light: 0xA68BB0, dark: 0xC6AFCF)

    /// Estimates and warnings. `warn` is dark enough to read as text; `warnDot` is for marks.
    static let warn = Color(light: 0x9A4A22, dark: 0xE8A07A)
    static let warnDot = Color(light: 0xC27748, dark: 0xE8A07A)
    static let warnSoft = Color(light: 0xF7E6DA, dark: 0x3A2A20)

    // Logo ("Market"): sage, apricot, honey.
    static let sage = Color(light: 0xC6DDB4, dark: 0xC6DDB4)
    static let apricot = Color(light: 0xF2C9A8, dark: 0xF2C9A8)
    static let honey = Color(light: 0xE9C077, dark: 0xE9C077)

    /// Numbers and titles, in Bricolage Grotesque.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        if let f = BundledFonts.families.display { return .custom(f, size: size).weight(weight).monospacedDigit() }
        return .system(size: size, weight: weight, design: .rounded)
    }

    /// Everything you read, in Geist. Sized and scaled like the system style it stands in for,
    /// so Dynamic Type still works.
    static func text(_ style: Font.TextStyle) -> Font {
        let headline = style == .headline
        guard let f = BundledFonts.families.text else { return .system(style) }
        let font = Font.custom(f, size: textSize(style), relativeTo: style)
        return headline ? font.weight(.semibold) : font
    }

    private static func textSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }

    /// Amounts, sources and other data, in Geist Mono.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if let f = BundledFonts.families.mono { return .custom(f, size: size).weight(weight).monospacedDigit() }
        return .system(size: size, weight: weight, design: .monospaced)
    }

    static let data = mono(12)

    /// Details about a food (how much, what's left, how long), in the reading font. Mono stays
    /// for numbers in tables and the developer screens.
    static var meta: Font { text(.caption) }
}

// MARK: - Fonts

/// Registers the fonts shipped in the app bundle. Done in code so no Info.plist list is needed;
/// if a font is missing, `Theme` falls back to system fonts.
enum BundledFonts {
    static let families: (display: String?, text: String?, mono: String?) = {
        var display: String?, text: String?, mono: String?
        for url in Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            guard let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
                  let family = descs.first.flatMap({ CTFontDescriptorCopyAttribute($0, kCTFontFamilyNameAttribute) as? String })
            else { continue }
            if family.localizedCaseInsensitiveContains("mono") { mono = family }
            else if family.localizedCaseInsensitiveContains("bricolage") { display = family }
            else if family.localizedCaseInsensitiveContains("geist") { text = family }
        }
        return (display, text, mono)
    }()
}

// MARK: - Liquid Glass

extension View {
    /// Liquid Glass on iOS 26, and a frosted material with a light rim before it. Use it for
    /// controls that float over content (tab bar, log button, toolbars), never for content.
    @ViewBuilder
    func glass<S: Shape>(_ shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(Self.glassStyle(tint: tint, interactive: interactive), in: shape)
        } else {
            glassFallback(shape, tint: tint)
        }
        #else
        glassFallback(shape, tint: tint)
        #endif
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private static func glassStyle(tint: Color?, interactive: Bool) -> Glass {
        var g = Glass.regular
        if let tint { g = g.tint(tint) }
        if interactive { g = g.interactive() }
        return g
    }
    #endif

    /// A bright rim in light mode, a faint one in dark mode.
    private static var glassEdge: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.14) : UIColor(white: 1, alpha: 0.55) })
    }

    private func glassFallback<S: Shape>(_ shape: S, tint: Color?) -> some View {
        self
            .background { if let tint { shape.fill(tint) } else { shape.fill(.ultraThinMaterial) } }
            .overlay { shape.stroke(Self.glassEdge, lineWidth: 0.75) }
            .shadow(color: Color.black.opacity(0.12), radius: 14, y: 6)
    }
}

/// A round glass button for toolbars and headers.
struct GlassCircleButton: View {
    let systemImage: String
    let label: String
    var size: CGFloat = 44
    /// Shown in place of the symbol when set, like the initial on the You button.
    var text: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let text {
                    Text(text).font(Theme.text(.callout).weight(.bold))
                } else {
                    Image(systemName: systemImage).font(.system(size: size * 0.38, weight: .semibold))
                }
            }
            .foregroundStyle(Theme.ink)
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glass(Circle(), interactive: true)
        .accessibilityLabel(label)
    }
}

// MARK: - The logo

/// The Mise logo: three prep bowls seen from above, set out before cooking ("mise en place").
/// Drawn on a 100-point square in the app icon's proportions, for night-green backgrounds.
struct BowlsMark: View {
    struct Bowl {
        let x, y, rim, well: CGFloat
        let color, inside: Color
    }

    /// Sage, apricot and honey, each with a deeper well.
    static let bowls = [
        Bowl(x: 40, y: 58, rim: 25, well: 17, color: Theme.sage, inside: Color(light: 0xA9C99A, dark: 0xA9C99A)),
        Bowl(x: 70, y: 34, rim: 15, well: 9.5, color: Theme.apricot, inside: Color(light: 0xE8B48D, dark: 0xE8B48D)),
        Bowl(x: 74, y: 70, rim: 11, well: 6.5, color: Theme.honey, inside: Color(light: 0xDDA955, dark: 0xDDA955)),
    ]

    var body: some View {
        Canvas { context, size in
            let u = min(size.width, size.height) / 100
            for b in Self.bowls {
                for (r, c) in [(b.rim, b.color), (b.well, b.inside)] {
                    let rect = CGRect(x: (b.x - r) * u, y: (b.y - r) * u, width: 2 * r * u, height: 2 * r * u)
                    context.fill(Path(ellipseIn: rect), with: .color(c))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// A small dot-and-label tag, the base of the source chips.
struct DotChip: View {
    let text: String
    let dot: Color
    var foreground: Color = Theme.ink
    var background: Color = Theme.surface2

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(dot).frame(width: 7, height: 7)
            Text(text)
        }
        .font(Theme.mono(11))
        .foregroundStyle(foreground)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(background, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Segments

/// The design's segmented control: a soft track with the chosen segment raised in white.
struct SegmentTrack<Value: Hashable>: View {
    var name = ""
    let options: [Value]
    @Binding var selection: Value
    /// A small second line under a segment's title, like "mostly sitting".
    var detail: (Value) -> String? = { _ in nil }
    let title: (Value) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { o in
                let on = selection == o
                Button { withAnimation(.easeOut(duration: 0.15)) { selection = o } } label: {
                    VStack(spacing: 1) {
                        Text(title(o)).font(Theme.text(.subheadline).weight(.semibold))
                        if let d = detail(o) { Text(d).font(Theme.text(.caption2)).foregroundStyle(Theme.muted) }
                    }
                    .foregroundStyle(on ? Theme.ink : Theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background {
                        if on {
                            RoundedRectangle(cornerRadius: 19, style: .continuous).fill(Self.raised)
                                .shadow(color: Color.black.opacity(0.14), radius: 1.5, y: 1)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Theme.ink.opacity(0.07), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(name)
    }

    /// Lighter than the track in both appearances, so the choice reads without the text colour.
    private static var raised: Color { Color(light: 0xFFFDF9, dark: 0x3A433D) }
}

// MARK: - Buttons

/// The "do this next" button: a sage capsule with dark text.
struct ActionButtonStyle: ButtonStyle {
    var fullWidth = false
    /// Dark instead of sage, for a confirm inside a card (Agree and continue).
    var night = false

    func makeBody(configuration: Configuration) -> some View {
        ActionButtonBody(label: configuration.label, pressed: configuration.isPressed, fullWidth: fullWidth, night: night)
    }

    private struct ActionButtonBody<Content: View>: View {
        let label: Content
        let pressed: Bool
        let fullWidth: Bool
        let night: Bool
        @Environment(\.isEnabled) private var enabled

        var body: some View {
            label
                .font(Theme.text(.body).weight(.semibold))
                .foregroundStyle(night ? Theme.onNight : Theme.onAction)
                .padding(.horizontal, 22)
                .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 52)
                .background(night ? Theme.night : Theme.action, in: Capsule())
                .opacity(enabled ? (pressed ? 0.8 : 1) : 0.45)
                .contentShape(Capsule())
        }
    }
}

extension ButtonStyle where Self == ActionButtonStyle {
    static var action: ActionButtonStyle { ActionButtonStyle() }
    static var actionWide: ActionButtonStyle { ActionButtonStyle(fullWidth: true) }
    static var nightWide: ActionButtonStyle { ActionButtonStyle(fullWidth: true, night: true) }
}
