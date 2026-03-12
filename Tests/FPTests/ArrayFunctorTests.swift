import XCTest
@testable import FP

final class ArrayFunctorTests: XCTestCase {

    func testFmap() {
        let array = [1, 2, 3]
        let result = Array.fmap({ $0 * 2 })(array)
        XCTAssertEqual(result, [2, 4, 6])
    }

    func testMapIsConsistent() {
        let array = [1, 2, 3]
        let transform = { $0 * 2 }

        XCTAssertEqual(array.map(transform), Array.fmap(transform)(array))
    }

    func testFunctorIdentityLaw() {
        // fmap id = id
        let array = [1, 2, 3]
        let identity: (Int) -> Int = { $0 }

        XCTAssertEqual(Array.fmap(identity)(array), array)
    }

    func testFunctorCompositionLaw() {
        // fmap (f . g) = fmap f . fmap g
        let array = [1, 2, 3]
        let f = { $0 * 2 }
        let g = { $0 + 1 }

        let left = Array.fmap({ x in f(g(x)) })(array)
        let right = Array.fmap(f)(Array.fmap(g)(array))

        XCTAssertEqual(left, right)
    }
}
