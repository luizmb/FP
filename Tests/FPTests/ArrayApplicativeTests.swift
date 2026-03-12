import XCTest
@testable import FP

final class ArrayApplicativeTests: XCTestCase {

    func testLiftA2() {
        let arr1 = [1, 2]
        let arr2 = [10, 20]
        let add = { (a: Int, b: Int) in a + b }

        let result = Array.liftA2(add)(arr1, arr2)
        XCTAssertEqual(result, [11, 21, 12, 22])
    }

    func testApply() {
        let functions: [(Int) -> Int] = [{ $0 * 2 }, { $0 + 10 }]
        let values = [1, 2, 3]

        let result = Array.apply(functions, values)
        XCTAssertEqual(result, [2, 4, 6, 11, 12, 13])
    }

    func testZip() {
        let arr1 = [1, 2, 3]
        let arr2 = ["a", "b", "c"]

        let result = Array.zip(arr1, arr2)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].0, 1)
        XCTAssertEqual(result[0].1, "a")
        XCTAssertEqual(result[2].0, 3)
        XCTAssertEqual(result[2].1, "c")
    }

    func testApplicativeIdentityLaw() {
        // pure id <*> v = v
        let array = [1, 2, 3]
        let identity: [(Int) -> Int] = [{ $0 }]

        XCTAssertEqual(Array.apply(identity, array), array)
    }

    func testApplicativeCompositionLaw() {
        // Simplified composition law test: u <*> (v <*> w) should work
        let u: [(Int) -> Int] = [{ $0 * 2 }]
        let v: [(Int) -> Int] = [{ $0 + 1 }]
        let w = [5]

        // First apply v to w, then apply u to the result
        let vw = Array.apply(v, w)  // [6]
        let result = Array.apply(u, vw)  // [12]

        XCTAssertEqual(result, [12])
    }
}
