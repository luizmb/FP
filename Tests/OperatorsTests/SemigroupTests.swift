import Testing
import Foundation
@testable import FP
@testable import Operators

@Suite struct SemigroupTests {

    @Test func arraySemigroup() {
        let arr1 = [1, 2, 3]
        let arr2 = [4, 5, 6]

        #expect((arr1 <> arr2) == [1, 2, 3, 4, 5, 6])
    }

    @Test func stringSemigroup() {
        #expect(("Hello, " <> "World!") == "Hello, World!")
    }

    @Test func optionalSemigroup() {
        let some: Int? = 5
        let none: Int? = nil

        #expect((some <> none) == 5)
        #expect((none <> some) == 5)
        #expect((some <> 10) == 5)
        #expect((none <> nil) == nil)
    }

    @Test func resultSemigroup() {
        let success1: Result<Int, NSError> = .success(5)
        let success2: Result<Int, NSError> = .success(10)
        let failure: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))

        #expect((try? (success1 <> success2).get()) == 5)
        #expect((try? (failure <> success2).get()) == 10)
        #expect((try? (success1 <> failure).get()) == 5)
    }

    @Test func setSemigroup() {
        let set1: Set<Int> = [1, 2, 3]
        let set2: Set<Int> = [3, 4, 5]

        #expect((set1 <> set2) == [1, 2, 3, 4, 5])
    }

    @Test func dictionarySemigroup() {
        let dict1 = ["a": 1, "b": 2]
        let dict2 = ["b": 3, "c": 4]

        let result = dict1 <> dict2
        #expect(result == ["a": 1, "b": 3, "c": 4])
    }

    @Test func semigroupAssociativity() {
        // (a <> b) <> c = a <> (b <> c)
        let a = [1, 2]
        let b = [3, 4]
        let c = [5, 6]

        let left = (a <> b) <> c
        let right = a <> (b <> c)

        #expect(left == right)
    }

    @Test func functionSemigroupArray() {
        let f: (Int) -> [Int] = { [$0] }
        let g: (Int) -> [Int] = { [$0 * 2] }

        let combined = f <> g
        #expect(combined(5) == [5, 10])
    }

    @Test func functionSemigroupString() {
        let f: (String) -> String = { "Hello, \($0)" }
        let g: (String) -> String = { "! Welcome, \($0)" }

        let combined = f <> g
        #expect(combined("World") == "Hello, World! Welcome, World")
    }

    @Test func functionSemigroupOptional() {
        let f: (Int) -> Int? = { $0 > 0 ? $0 : nil }
        let g: (Int) -> Int? = { $0 * 2 }

        let combined = f <> g
        #expect(combined(5) == 5)
        #expect(combined(-1) == -2)
    }
}
