import XCTest
@testable import FP
@testable import Operators

final class FunctionCompositionTests: XCTestCase {

    // MARK: - Composition Operators

    func testForwardComposition() {
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }

        let composed = addOne >>> double
        XCTAssertEqual(composed(5), 12) // (5 + 1) * 2 = 12
    }

    func testBackwardComposition() {
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }

        let composed = double <<< addOne
        XCTAssertEqual(composed(5), 12) // (5 + 1) * 2 = 12
    }

    func testBackwardCompositionAlternativeSymbol() {
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }

        let composed = double • addOne
        XCTAssertEqual(composed(5), 12)
    }

    func testCompositionAssociativity() {
        let f: (Int) -> Int = { $0 + 1 }
        let g: (Int) -> Int = { $0 * 2 }
        let h: (Int) -> Int = { $0 - 3 }

        let left = (f >>> g) >>> h
        let right = f >>> (g >>> h)

        XCTAssertEqual(left(5), right(5))
    }

    // MARK: - Application Operators

    func testFunctionApplicationPound() {
        let addOne: (Int) -> Int = { $0 + 1 }

        XCTAssertEqual(addOne £ 5, 6)
    }

    func testFunctionApplicationAngle() {
        let addOne: (Int) -> Int = { $0 + 1 }

        XCTAssertEqual(addOne <| 5, 6)
    }

    func testFlippedFunctionApplication() {
        let addOne: (Int) -> Int = { $0 + 1 }

        XCTAssertEqual(5 |> addOne, 6)
    }

    func testPipeChaining() {
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }
        let triple: (Int) -> Int = { $0 * 3 }

        let result = 5 |> addOne |> double |> triple
        XCTAssertEqual(result, 36) // ((5 + 1) * 2) * 3 = 36
    }

    func testFunctionApplicationVsComposition() {
        let addOne: (Int) -> Int = { $0 + 1 }
        let double: (Int) -> Int = { $0 * 2 }

        // Using composition
        let composed = addOne >>> double
        XCTAssertEqual(composed(5), 12)

        // Using pipe
        let piped = 5 |> addOne |> double
        XCTAssertEqual(piped, 12)

        // They should be equivalent
        XCTAssertEqual(composed(5), piped)
    }

    func testCompositionIdentity() {
        let f: (Int) -> Int = { $0 * 2 }
        let id: (Int) -> Int = { $0 }

        // f >>> id = f
        XCTAssertEqual((f >>> id)(5), f(5))

        // id >>> f = f
        XCTAssertEqual((id >>> f)(5), f(5))
    }
}
