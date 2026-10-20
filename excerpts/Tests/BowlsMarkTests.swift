// Excerpt from Mise (private source).

import XCTest
@testable import Mise

/// The prep-bowls logo fits its square at every size it's drawn.
final class BowlsMarkTests: XCTestCase {
    func testEveryBowlFitsTheSquareWithItsWellInside() {
        XCTAssertEqual(BowlsMark.bowls.count, 3)
        for b in BowlsMark.bowls {
            XCTAssertGreaterThanOrEqual(b.x - b.rim, 0); XCTAssertLessThanOrEqual(b.x + b.rim, 100)
            XCTAssertGreaterThanOrEqual(b.y - b.rim, 0); XCTAssertLessThanOrEqual(b.y + b.rim, 100)
            XCTAssertLessThan(b.well, b.rim)
        }
    }
}
