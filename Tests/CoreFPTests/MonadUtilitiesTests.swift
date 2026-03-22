import Testing
import Foundation
@testable import CoreFP

@Suite struct MonadUtilitiesTests {

    // MARK: - Join Tests

    @Test func optionalJoin() {
        let nested: Int?? = .some(.some(5))
        #expect(Optional<Int>.join(nested) == 5)

        let nestedNone: Int?? = .some(.none)
        #expect(Optional<Int>.join(nestedNone) == nil)

        let outerNone: Int?? = .none
        #expect(Optional<Int>.join(outerNone) == nil)
    }

    // MARK: - Void Tests

    @Test func optionalVoid() {
        let some: Int? = 5
        let voided = some.void()
        #expect(voided != nil)

        let none: Int? = nil
        #expect(none.void() == nil)
    }

    @Test func resultVoid() {
        let success: Result<Int, NSError> = .success(5)
        let voided = success.void()
        #expect(throws: Never.self) { try voided.get() }

        let failure: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))
        #expect(throws: (any Error).self) { try failure.void().get() }
    }

    @Test func arrayVoid() {
        let array = [1, 2, 3]
        let voided = array.void()
        #expect(voided.count == 3)
    }

    // MARK: - Filter Tests

    @Test func optionalFilter() {
        let value: Int? = 5
        #expect(value.filter { $0 > 3 } == 5)
        #expect(value.filter { $0 > 10 } == nil)

        let none: Int? = nil
        #expect(none.filter { $0 > 3 } == nil)
    }

    @Test func arrayFilterM() {
        let array = [1, 2, 3, 4, 5]
        let isEven = { $0 % 2 == 0 }

        let result = Array.filterM(isEven)(array)
        #expect(result == [2, 4])
    }

    // MARK: - Sequence Tests

    @Test func sequenceOptionals() {
        let allSome: [Int?] = [1, 2, 3]
        #expect(sequence(allSome) == [1, 2, 3])

        let withNone: [Int?] = [1, nil, 3]
        #expect(sequence(withNone) == nil)

        let empty: [Int?] = []
        #expect(sequence(empty) == [])
    }

    @Test func sequenceResults() {
        let allSuccess: [Result<Int, NSError>] = [.success(1), .success(2), .success(3)]
        #expect((try? sequence(allSuccess).get()) == [1, 2, 3])

        let withFailure: [Result<Int, NSError>] = [
            .success(1),
            .failure(NSError(domain: "test", code: 1)),
            .success(3)
        ]
        #expect(throws: (any Error).self) { try sequence(withFailure).get() }

        let empty: [Result<Int, NSError>] = []
        #expect((try? sequence(empty).get()) == [])
    }

    // MARK: - Traverse Tests

    @Test func traverseOptional() {
        let safeDivide: (Int) -> Int? = { divisor in
            divisor != 0 ? .some(10 / divisor) : .none
        }

        let values = [1, 2, 5]
        #expect(traverse(safeDivide)(values) == [10, 5, 2])

        let withZero = [1, 0, 5]
        #expect(traverse(safeDivide)(withZero) == nil)

        let empty: [Int] = []
        #expect(traverse(safeDivide)(empty) == [])
    }

    @Test func traverseResult() {
        let safeParse: (String) -> Result<Int, NSError> = { str in
            guard let int = Int(str) else {
                return .failure(NSError(domain: "parse", code: 1))
            }
            return .success(int)
        }

        let validStrings = ["1", "2", "3"]
        #expect((try? traverse(safeParse)(validStrings).get()) == [1, 2, 3])

        let withInvalid = ["1", "invalid", "3"]
        #expect(throws: (any Error).self) { try traverse(safeParse)(withInvalid).get() }

        let empty: [String] = []
        #expect((try? traverse(safeParse)(empty).get()) == [])
    }

    // MARK: - Traverse Identity Law

    @Test func traverseIdentityLaw() {
        // traverse pure = pure
        let values = [1, 2, 3]
        let identity: (Int) -> Int? = { .some($0) }

        #expect(traverse(id)(values) == [1, 2, 3])
    }

    // MARK: - Sequence/Traverse Relationship

    @Test func sequenceTraverseRelationship() {
        // sequence = traverse id
        let optionals: [Int?] = [1, 2, 3]
        let identity: (Int?) -> Int? = id

        #expect(sequence(optionals) == traverse(identity)(optionals))
    }
}
