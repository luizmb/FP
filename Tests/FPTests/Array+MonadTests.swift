import XCTest
@testable import FP

final class ArrayMonadTests: XCTestCase {

    func testBind() {
        let array = [1, 2, 3]
        let result = Array.bind({ [$0, $0 * 2] })(array)
        XCTAssertEqual(result, [1, 2, 2, 4, 3, 6])
    }

    func testKleisliComposition() {
        let duplicate: (Int) -> [Int] = { [$0, $0] }
        let double: (Int) -> [Int] = { [$0 * 2] }

        let composed = Array.kleisli(duplicate, double)
        XCTAssertEqual(composed(5), [10, 10])
    }

    func testAlt() {
        let arr1 = [1, 2, 3]
        let arr2 = [4, 5, 6]

        XCTAssertEqual(Array.alt(arr1, arr2), [1, 2, 3, 4, 5, 6])
    }

    func testConcat() {
        let arrays = [[1, 2], [3, 4], [5, 6]]
        let result = Array.concat(arrays)
        XCTAssertEqual(result, [1, 2, 3, 4, 5, 6])
    }

    func testJoin() {
        let nested = [[1, 2], [3, 4], [5, 6]]
        let result = Array.join(nested)
        XCTAssertEqual(result, [1, 2, 3, 4, 5, 6])
    }

    func testMonadLeftIdentityLaw() {
        // return a >>= f = f a
        let a = 5
        let f: (Int) -> [Int] = { [$0 * 2] }

        let left = [a].flatMap(f)
        let right = f(a)

        XCTAssertEqual(left, right)
    }

    func testMonadRightIdentityLaw() {
        // m >>= return = m
        let m = [1, 2, 3]
        let pureFunc: (Int) -> [Int] = { [$0] }

        XCTAssertEqual(m.flatMap(pureFunc), m)
    }

    func testMonadAssociativityLaw() {
        // (m >>= f) >>= g = m >>= (\x -> f x >>= g)
        let m = [1, 2]
        let f: (Int) -> [Int] = { [$0, $0 + 1] }
        let g: (Int) -> [Int] = { [$0 * 2] }

        let left = m.flatMap(f).flatMap(g)
        let right = m.flatMap { x in f(x).flatMap(g) }

        XCTAssertEqual(left, right)
    }
}
