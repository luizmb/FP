// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

@Suite struct ArrayApplicativeTests {
    @Test func liftA2() {
        let arr1 = [1, 2]
        let arr2 = [10, 20]
        let add: @Sendable (Int, Int) -> Int = { a, b in a + b }

        let result = Array.liftA2(add)(arr1, arr2)
        #expect(result == [11, 21, 12, 22])
    }

    @Test func apply() {
        let functions: [@Sendable (Int) -> Int] = [{ $0 * 2 }, { $0 + 10 }]
        let values = [1, 2, 3]

        let result = Array.apply(functions, values)
        #expect(result == [2, 4, 6, 11, 12, 13])
    }

    @Test func zip() {
        let arr1 = [1, 2, 3]
        let arr2 = ["a", "b", "c"]

        let result = Array.zip(arr1, arr2)
        #expect(result.count == 3)
        #expect(result[0].0 == 1)
        #expect(result[0].1 == "a")
        #expect(result[2].0 == 3)
        #expect(result[2].1 == "c")
    }

    @Test func applicativeIdentityLaw() {
        // pure id <*> v = v
        let array = [1, 2, 3]
        let identityArr: [@Sendable (Int) -> Int] = [id]

        #expect(Array.apply(identityArr, array) == array)
    }

    @Test func applicativeCompositionLaw() {
        // Simplified composition law test: u <*> (v <*> w) should work
        let u: [@Sendable (Int) -> Int] = [{ $0 * 2 }]
        let v: [@Sendable (Int) -> Int] = [{ $0 + 1 }]
        let w = [5]

        // First apply v to w, then apply u to the result
        let vw = Array.apply(v, w) // [6]
        let result = Array.apply(u, vw) // [12]

        #expect(result == [12])
    }

    // MARK: - pure

    @Test func pureLiftsIntoSingletonArray() {
        #expect(Array.pure(42) == [42])
    }

    @Test func pureIsLeftIdentityForApply() {
        // pure id <*> v == v
        let array = [1, 2, 3]
        let identityArr = [@Sendable (Int) -> Int].pure(id)
        #expect(Array.apply(identityArr, array) == array)
    }

    // MARK: - zip3 / zip4

    @Test func zip3SameLength() {
        let a1 = [1, 2, 3]
        let a2 = ["a", "b", "c"]
        let a3 = [true, false, true]

        let result = Array.zip3(a1, a2, a3)
        #expect(result.count == 3)
        #expect(result[0] == (1, "a", true))
        #expect(result[2] == (3, "c", true))
    }

    @Test func zip3MismatchedLengths_truncatesToShortest() {
        let a1 = [1, 2, 3, 4]
        let a2 = ["a", "b"]
        let a3 = [true, false, true]

        let result = Array.zip3(a1, a2, a3)
        #expect(result.count == 2)
        #expect(result[0] == (1, "a", true))
        #expect(result[1] == (2, "b", false))
    }

    @Test func zip4SameLength() {
        let a1 = [1, 2]
        let a2 = ["a", "b"]
        let a3 = [true, false]
        let a4 = [1.0, 2.0]

        let result = Array.zip4(a1, a2, a3, a4)
        #expect(result.count == 2)
        #expect(result[0] == (1, "a", true, 1.0))
        #expect(result[1] == (2, "b", false, 2.0))
    }

    @Test func zip4MismatchedLengths_truncatesToShortest() {
        let a1 = [1, 2, 3]
        let a2 = ["a", "b", "c"]
        let a3 = [true, false]
        let a4 = [1.0, 2.0, 3.0]

        let result = Array.zip4(a1, a2, a3, a4)
        #expect(result.count == 2)
        #expect(result[0] == (1, "a", true, 1.0))
        #expect(result[1] == (2, "b", false, 2.0))
    }
}
