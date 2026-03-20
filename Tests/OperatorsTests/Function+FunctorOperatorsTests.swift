import XCTest
@testable import FP
@testable import Operators

final class FunctionFunctorTests: XCTestCase {

    // MARK: - Basic Functor Tests

    func testFmap() {
        let f: (Int) -> Int = { $0 + 1 }
        let g: (Int) -> String = { "\($0)" }

        let composed = fmap(g, f)

        XCTAssertEqual(composed(5), "6")
        XCTAssertEqual(composed(10), "11")
    }

    func testCurriedFmap() {
        let f: (Int) -> Int = { $0 * 2 }
        let toString: (Int) -> String = { "\($0)" }

        // Use the curried version explicitly with type annotation
        let fmapToString: (@escaping (Int) -> Int) -> (Int) -> String = fmap(toString)
        let composed = fmapToString(f)

        XCTAssertEqual(composed(5), "10")
    }

    // MARK: - Functor Laws

    func testFunctorIdentityLaw() {
        // fmap id == id
        let f: (Int) -> Int = { $0 * 2 }
        let identity: (Int) -> Int = { $0 }

        let mapped = fmap(identity, f)

        // Both should produce the same results
        XCTAssertEqual(f(5), mapped(5))
        XCTAssertEqual(f(10), mapped(10))
    }

    func testFunctorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let base: (Int) -> Int = { $0 + 1 }
        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        // Left side: fmap (g . f)
        let left = fmap(compose(f, g), base)

        // Right side: (fmap g) . (fmap f)
        // fmap f applied to base gives us (Int) -> Int
        // then we need to apply fmap g to that
        let step1 = fmap(f, base)  // (Int) -> Int
        let right = fmap(g, step1)  // (Int) -> String

        XCTAssertEqual(left(5), right(5))
        XCTAssertEqual(left(10), right(10))
    }

    // MARK: - Functor Operators

    func testFmapOperator() {
        let f: (Int) -> Int = { $0 + 1 }
        let g: (Int) -> String = { "\($0)" }

        let composed = g <£> f

        XCTAssertEqual(composed(5), "6")
        XCTAssertEqual(composed(10), "11")
    }

    func testFmapOperatorComposition() {
        // Test multiple compositions using the operator
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }
        let toString: (Int) -> String = { "\($0)" }

        let composed = toString <£> double <£> addOne

        XCTAssertEqual(composed(5), "12")  // (5 + 1) * 2 = 12
    }

    func testMapReplaceOperator() {
        let f: (Int) -> String = { "\($0)" }

        let constant = f £> 99

        XCTAssertEqual(constant(1), 99)
        XCTAssertEqual(constant(100), 99)
    }

    func testMapReplaceFlippedOperator() {
        let f: (Int) -> String = { "\($0)" }

        let constant = 42 <£ f

        XCTAssertEqual(constant(1), 42)
        XCTAssertEqual(constant(100), 42)
    }

    // MARK: - Practical Examples

    func testPracticalExample() {
        // Compose string operations
        let trimWhitespace: (String) -> String = { $0.trimmingCharacters(in: .whitespaces) }
        let uppercase: (String) -> String = { $0.uppercased() }

        // We can use fmap to compose these
        let trimAndUpper = fmap(uppercase, trimWhitespace)

        XCTAssertEqual(trimAndUpper("  hello  "), "HELLO")
        XCTAssertEqual(trimAndUpper("world"), "WORLD")
    }

    func testEquivalenceWithComposition() {
        // fmap should be equivalent to function composition
        let f: (Int) -> Int = { $0 + 1 }
        let g: (Int) -> String = { "\($0)" }

        let viaFmap = fmap(g, f)
        let viaCompose = compose(f, g)

        XCTAssertEqual(viaFmap(5), viaCompose(5))
        XCTAssertEqual(viaFmap(10), viaCompose(10))
    }
}
