// Excerpt from Mise (private source): the nutrition value type, its consistency checks and the recipe score.

import Foundation

/// Calories and macros. Stored per 100 g on foods, or as absolute amounts on totals.
struct Nutrients: Codable, Hashable, Sendable {
    var kcal: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0

    static let zero = Nutrients()

    static func + (a: Nutrients, b: Nutrients) -> Nutrients {
        Nutrients(kcal: a.kcal + b.kcal, protein: a.protein + b.protein, carbs: a.carbs + b.carbs,
                  fat: a.fat + b.fat, fiber: a.fiber + b.fiber)
    }

    static func * (a: Nutrients, k: Double) -> Nutrients {
        Nutrients(kcal: a.kcal * k, protein: a.protein * k, carbs: a.carbs * k, fat: a.fat * k, fiber: a.fiber * k)
    }

    static func / (a: Nutrients, k: Double) -> Nutrients { k > 0 ? a * (1 / k) : .zero }

    /// Per-100 g values scaled to a weight in grams. Unrounded.
    func scaled(toGrams grams: Double) -> Nutrients {
        guard grams > 0 else { return .zero }
        return self * (grams / 100)
    }

    /// Atwater consistency check: 4 kcal/g protein and net carbs, 9 kcal/g fat.
    /// Use on label readings and estimates to catch misreads. USDA data for citrus,
    /// vinegar and some vegetables legitimately falls outside this range.
    var atwaterRatio: Double {
        let expected = 4 * protein + 4 * max(0, carbs - 0.5 * fiber) + 9 * fat
        if expected < 5 && kcal < 5 { return 1 }
        return expected > 0 ? kcal / expected : .infinity
    }

    var isConsistent: Bool { (0.8...1.2).contains(atwaterRatio) }

    /// Sanity bounds for per-100 g values from an untrusted source.
    var isPlausiblePer100: Bool {
        (0...902).contains(kcal) && protein >= 0 && carbs >= 0 && fat >= 0 && fiber >= 0
            && protein + carbs + fat <= 101
    }
}

extension Nutrients {
    /// Stored inside every saved food, so a value written before a nutrient was added must still
    /// read, with the missing nutrient as 0. A new nutrient needs a line here too.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kcal = try c.decodeIfPresent(Double.self, forKey: .kcal) ?? 0
        protein = try c.decodeIfPresent(Double.self, forKey: .protein) ?? 0
        carbs = try c.decodeIfPresent(Double.self, forKey: .carbs) ?? 0
        fat = try c.decodeIfPresent(Double.self, forKey: .fat) ?? 0
        fiber = try c.decodeIfPresent(Double.self, forKey: .fiber) ?? 0
    }
}

extension Sequence where Element == Nutrients {
    func total() -> Nutrients { reduce(.zero, +) }
}

// MARK: - Display formatting

enum Fmt {
    /// " · 2 with no amount weren't added", or nothing: lines set to nothing are left out at
    /// save, and the message says so instead of counting them.
    static func noAmount(_ n: Int, _ verb: String) -> String {
        n <= 0 ? "" : " · \(n) with no amount \(n == 1 ? "wasn't" : "weren't") \(verb)"
    }

    /// Calories rounded to a whole number with grouping ("1,240").
    static func kcal(_ v: Double) -> String {
        Int(v.rounded()).formatted(.number)
    }

    /// Grams: one decimal under 10 g, whole number above.
    static func grams(_ v: Double) -> String {
        guard v > 0 else { return "0" }
        if v < 10 { return String(format: "%.1f", (v * 10).rounded() / 10) }
        return String(Int(v.rounded()))
    }

    static func qty(_ v: Double) -> String {
        let r = (v * 100).rounded() / 100
        return r == r.rounded() ? String(Int(r)) : String(r)
    }

    /// What an amount field's text sets the amount to, or nil to leave it. Text that reads the
    /// same as the amount already shows is left alone: the field is filled with the rounded
    /// amount when it opens, and writing that back turned 2.6667 slices into 2.67 just by looking.
    static func typedQty(_ text: String, was: Double) -> Double? {
        guard text != qty(was) else { return nil }
        if text.isEmpty { return 0 }
        guard let v = Double(text.replacingOccurrences(of: ",", with: ".")), v >= 0 else { return nil }
        return v
    }
}

// MARK: - Macro score

/// 0–100 ranking for recipes. Transparent by design; the recipe screen shows each part.
/// - 60 pts: share of calories from protein (40%+ = full marks)
/// - 25 pts: fits the meal budget (40% of calories left today, at least 400 kcal)
/// - 15 pts: fiber (8 g+ per serving = full marks)
struct MacroScore: Hashable, Sendable {
    let score: Int
    let proteinShare: Double
    let proteinPoints: Double
    let fitPoints: Double
    let fiberPoints: Double
    let budget: Double

    init(perServing n: Nutrients, remainingKcal: Double) {
        let budget = max(400, max(0, remainingKcal) * 0.4)
        self.budget = budget
        guard n.kcal > 0 else {
            score = 0; proteinShare = 0; proteinPoints = 0; fitPoints = 0; fiberPoints = 0
            return
        }
        proteinShare = n.protein * 4 / n.kcal
        proteinPoints = min(proteinShare / 0.4, 1) * 60
        let fit = n.kcal <= budget ? 1 : max(0, 1 - (n.kcal - budget) / budget)
        fitPoints = fit * 25
        fiberPoints = min(n.fiber / 8, 1) * 15
        score = Int((proteinPoints + fitPoints + fiberPoints).rounded())
    }
}
