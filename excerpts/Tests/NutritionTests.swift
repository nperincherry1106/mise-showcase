// Excerpt from Mise (private source): the first accuracy tests. Expected values are USDA household portions.

import XCTest
@testable import Mise

/// Accuracy tests. Expected values are USDA FoodData Central (SR Legacy) household portions.
final class NutritionTests: XCTestCase {

    private func food(_ id: String) -> Food { USDAFoods.byId[id]! }

    func testTwoLargeEggs() {
        let n = LineItem(food: food("egg"), qty: 2, unit: "large egg").nutrition
        XCTAssertEqual(n.kcal, 143, accuracy: 0.5)        // 100 g × 143 kcal
        XCTAssertEqual(n.protein, 12.56, accuracy: 0.01)
    }

    func testCupCookedWhiteRice() {
        let n = LineItem(food: food("rice_white_cooked"), qty: 1, unit: "cup").nutrition
        XCTAssertEqual(n.kcal, 205, accuracy: 1)          // USDA: 1 cup (158 g) = 205 kcal
    }

    func testTablespoonOliveOil() {
        let n = LineItem(food: food("olive_oil"), qty: 1, unit: "tbsp").nutrition
        XCTAssertEqual(n.kcal, 119, accuracy: 1)          // USDA: 1 tbsp (13.5 g) = 119 kcal
    }

    func testUnitSwitchKeepsWeight() {
        var l = LineItem(food: food("egg"), qty: 3, unit: "large egg")
        l.setUnit("g")
        XCTAssertEqual(l.grams, 150, accuracy: 0.01)
        l.setUnit("oz")
        XCTAssertEqual(l.grams, 150, accuracy: 0.5)
    }

    func testRecipePerServing() {
        let r = Recipe(title: "Test", minutes: 10, servings: 2, ingredients: [
            LineItem(food: food("chicken_breast_raw"), grams: 340),
            LineItem(food: food("broccoli"), grams: 182),
            LineItem(food: food("olive_oil"), grams: 13.5),
        ], steps: [])
        XCTAssertEqual(r.total.kcal, 408 + 61.88 + 119.34, accuracy: 0.1)
        XCTAssertEqual(r.perServing.kcal, r.total.kcal / 2, accuracy: 0.001)
        XCTAssertEqual(r.coverage, 1, accuracy: 0.0001)
    }

    func testLabelConsistencyCheck() {
        XCTAssertTrue(Nutrients(kcal: 140, protein: 6, carbs: 22, fat: 3, fiber: 3).isConsistent)
        XCTAssertFalse(Nutrients(kcal: 40, protein: 6, carbs: 22, fat: 3, fiber: 3).isConsistent)   // misread "140"
    }

    func testMacroScoreFavorsProtein() {
        let lean = MacroScore(perServing: Nutrients(kcal: 400, protein: 45, carbs: 30, fat: 10, fiber: 6), remainingKcal: 1500)
        let carby = MacroScore(perServing: Nutrients(kcal: 400, protein: 8, carbs: 75, fat: 8, fiber: 2), remainingKcal: 1500)
        XCTAssertGreaterThan(lean.score, carby.score)
    }
    // ... several hundred more tests in the full suite
}
