import XCTest
@testable import FP
@testable import Operators

final class SemigroupTests: XCTestCase {

    func testArraySemigroup() {
        let arr1 = [1, 2, 3]
        let arr2 = [4, 5, 6]

        XCTAssertEqual(arr1 <> arr2, [1, 2, 3, 4, 5, 6])
    }

    func testStringSemigroup() {
        XCTAssertEqual("Hello, " <> "World!", "Hello, World!")
    }

    func testOptionalSemigroup() {
        let some: Int? = 5
        let none: Int? = nil

        XCTAssertEqual(some <> none, 5)
        XCTAssertEqual(none <> some, 5)
        XCTAssertEqual(some <> 10, 5)
        XCTAssertNil(none <> nil)
    }

    func testResultSemigroup() {
        let success1: Result<Int, NSError> = .success(5)
        let success2: Result<Int, NSError> = .success(10)
        let failure: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))

        XCTAssertEqual(try? (success1 <> success2).get(), 5)
        XCTAssertEqual(try? (failure <> success2).get(), 10)
        XCTAssertEqual(try? (success1 <> failure).get(), 5)
    }

    func testSetSemigroup() {
        let set1: Set<Int> = [1, 2, 3]
        let set2: Set<Int> = [3, 4, 5]

        XCTAssertEqual(set1 <> set2, [1, 2, 3, 4, 5])
    }

    func testDictionarySemigroup() {
        let dict1 = ["a": 1, "b": 2]
        let dict2 = ["b": 3, "c": 4]

        let result = dict1 <> dict2
        XCTAssertEqual(result, ["a": 1, "b": 3, "c": 4])
    }

    func testSemigroupAssociativity() {
        // (a <> b) <> c = a <> (b <> c)
        let a = [1, 2]
        let b = [3, 4]
        let c = [5, 6]

        let left = (a <> b) <> c
        let right = a <> (b <> c)

        XCTAssertEqual(left, right)
    }

    func testFunctionSemigroupArray() {
        let f: (Int) -> [Int] = { [$0] }
        let g: (Int) -> [Int] = { [$0 * 2] }

        let combined = f <> g
        XCTAssertEqual(combined(5), [5, 10])
    }

    func testFunctionSemigroupString() {
        let f: (String) -> String = { "Hello, \($0)" }
        let g: (String) -> String = { "! Welcome, \($0)" }

        let combined = f <> g
        XCTAssertEqual(combined("World"), "Hello, World! Welcome, World")
    }

    func testFunctionSemigroupOptional() {
        let f: (Int) -> Int? = { $0 > 0 ? $0 : nil }
        let g: (Int) -> Int? = { $0 * 2 }

        let combined = f <> g
        XCTAssertEqual(combined(5), 5)
        XCTAssertEqual(combined(-1), -2)
    }
}
