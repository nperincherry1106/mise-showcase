// Excerpt from Mise (private source): a few of the shared SwiftUI components.
// `NutritionSource` (USDA, label, FatSecret, estimate, unmatched) is defined elsewhere in the app.

import SwiftUI
import UIKit

// MARK: - Small pieces

struct SourceChip: View {
    let source: NutritionSource
    /// White with a hairline, for chips sitting on the page rather than inside a card.
    var onCard = false
    /// A line whose check never ran (a dropped connection): it isn't "No match", it's unknown.
    var unchecked = false
    var body: some View {
        DotChip(text: Self.title(source, unchecked: unchecked), dot: dot,
                foreground: source.isDatabase && !unchecked ? Theme.ink : Theme.warn,
                background: source.isDatabase && !unchecked ? (onCard ? Theme.surface : Theme.surface2) : Theme.warnSoft)
            .overlay {
                if onCard && source.isDatabase && !unchecked { RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1) }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(unchecked ? "Not checked yet" : spoken)
    }

    /// Whether a closed row shows its chip. Only lines that need a look (an estimate, no match, a
    /// check that never ran) say so up front; a confirmed source shows once the line is opened.
    static func onClosedRow(_ source: NutritionSource, unchecked: Bool) -> Bool {
        unchecked || !source.isDatabase
    }

    static func title(_ source: NutritionSource, unchecked: Bool) -> String { unchecked ? "Not checked" : source.title }

    private var dot: Color { source.dot }

    private var spoken: String {
        switch source {
        case .usda: "From USDA data"
        case .label: "From package label"
        case .fatsecret: "From FatSecret data"
        case .estimate: "AI estimate"
        case .unmatched: "No database match, no numbers yet"
        }
    }
}

extension NutritionSource {
    /// Each source's colour, for the dot on its chip.
    var dot: Color {
        switch self {
        case .usda: Theme.accent
        case .label: Theme.label
        case .fatsecret: Theme.fatsecret
        case .estimate, .unmatched: Theme.warnDot
        }
    }
}

struct MacroLine: View {
    let n: Nutrients
    var body: some View {
        HStack(spacing: 8) {
            dot(Theme.protein, "\(Fmt.grams(n.protein))P")
            dot(Theme.carbs, "\(Fmt.grams(n.carbs))C")
            dot(Theme.fat, "\(Fmt.grams(n.fat))F")
        }
        .font(Theme.data)
        .foregroundStyle(Theme.muted)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Fmt.grams(n.protein)) grams protein, \(Fmt.grams(n.carbs)) carbs, \(Fmt.grams(n.fat)) fat")
    }
    private func dot(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 3) { Circle().fill(c).frame(width: 7, height: 7); Text(t) }
    }
}

struct ProgressBar: View {
    let value: Double
    var color: Color = Theme.accent
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface2)
                Capsule().fill(value > 1.05 ? Theme.warn : color)
                    .frame(width: g.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: height)
    }
}

struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 46
    var body: some View {
        let c: Color = score >= 75 ? Theme.accent : score >= 50 ? Theme.carbs : Theme.warn
        ZStack {
            Circle().stroke(Theme.surface2, lineWidth: 4)
            Circle().trim(from: 0, to: CGFloat(score) / 100)
                .stroke(c, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)").font(Theme.display(16))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Macro score \(score)")
    }
}

/// A screen title with its controls beside it, or below it when the two don't fit on one line,
/// as at the largest text sizes or on a small phone. Side by side, the title only got what the
/// controls left over, and at the largest sizes that was nothing: the title vanished and its
/// subtitle wrapped a letter per line down a blank screen.
struct TitleRow<Title: View, Controls: View>: View {
    @ViewBuilder var title: Title
    @ViewBuilder var controls: Controls

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) {
                title
                Spacer(minLength: 12)
                // Its full width beside the title: squeezed, its labels broke mid-word.
                controls.fixedSize()
            }
            VStack(alignment: .leading, spacing: 12) {
                title
                controls
            }
        }
    }
}

