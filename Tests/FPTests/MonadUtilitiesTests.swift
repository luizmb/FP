import XCTest
@testable import FP

final class MonadUtilitiesTests: XCTestCase {

    // MARK: - Join Tests

    func testOptionalJoin() {
        let nested: Int?? = .some(.some(5))
        XCTAssertEqual(Optional<Int>.join(nested), 5)

        let nestedNone: Int?? = .some(.none)
        XCTAssertNil(Optional<Int>.join(nestedNone))

        let outerNone: Int?? = .none
        XCTAssertNil(Optional<Int>.join(outerNone))
    }

    // MARK: - Void Tests

    func testOptionalVoid() {
        let some: Int? = 5
        let voided = some.void()
        XCTAssertNotNil(voided)

        let none: Int? = nil
        XCTAssertNil(none.void())
    }

    func testResultVoid() {
        let success: Result<Int, NSError> = .success(5)
        let voided = success.void()
        XCTAssertNoThrow(try voided.get())

        let failure: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))
        XCTAssertThrowsError(try failure.void().get())
    }

    func testArrayVoid() {
        let array = [1, 2, 3]
        let voided = array.void()
        XCTAssertEqual(voided.count, 3)
    }

    // MARK: - Filter Tests

    func testOptionalFilter() {
        let value: Int? = 5
        XCTAssertEqual(value.filter { $0 > 3 }, 5)
        XCTAssertNil(value.filter { $0 > 10 })

        let none: Int? = nil
        XCTAssertNil(none.filter { $0 > 3 })
    }

    func testArrayFilterM() {
        let array = [1, 2, 3, 4, 5]
        let isEven = { $0 % 2 == 0 }

        let result = Array.filterM(isEven)(array)
        XCTAssertEqual(result, [2, 4])
    }

    // MARK: - Sequence Tests

    func testSequenceOptionals() {
        let allSome: [Int?] = [1, 2, 3]
        XCTAssertEqual(sequence(allSome), [1, 2, 3])

        let withNone: [Int?] = [1, nil, 3]
        XCTAssertNil(sequence(withNone))

        let empty: [Int?] = []
        XCTAssertEqual(sequence(empty), [])
    }

    func testSequenceResults() {
        let allSuccess: [Result<Int, NSError>] = [.success(1), .success(2), .success(3)]
        XCTAssertEqual(try? sequence(allSuccess).get(), [1, 2, 3])

        let withFailure: [Result<Int, NSError>] = [
            .success(1),
            .failure(NSError(domain: "test", code: 1)),
            .success(3)
        ]
        XCTAssertThrowsError(try sequence(withFailure).get())

        let empty: [Result<Int, NSError>] = []
        XCTAssertEqual(try? sequence(empty).get(), [])
    }

    // MARK: - Traverse Tests

    func testTraverseOptional() {
        let safeDivide: (Int) -> Int? = { divisor in
            divisor != 0 ? .some(10 / divisor) : .none
        }

        let values = [1, 2, 5]
        XCTAssertEqual(traverse(safeDivide)(values), [10, 5, 2])

        let withZero = [1, 0, 5]
        XCTAssertNil(traverse(safeDivide)(withZero))

        let empty: [Int] = []
        XCTAssertEqual(traverse(safeDivide)(empty), [])
    }

    func testTraverseResult() {
        let safeParse: (String) -> Result<Int, NSError> = { str in
            guard let int = Int(str) else {
                return .failure(NSError(domain: "parse", code: 1))
            }
            return .success(int)
        }

        let validStrings = ["1", "2", "3"]
        XCTAssertEqual(try? traverse(safeParse)(validStrings).get(), [1, 2, 3])

        let withInvalid = ["1", "invalid", "3"]
        XCTAssertThrowsError(try traverse(safeParse)(withInvalid).get())

        let empty: [String] = []
        XCTAssertEqual(try? traverse(safeParse)(empty).get(), [])
    }

    // MARK: - Traverse Identity Law

    func testTraverseIdentityLaw() {
        // traverse pure = pure
        let values = [1, 2, 3]
        let identity: (Int) -> Int? = { .some($0) }

        XCTAssertEqual(traverse(identity)(values), [1, 2, 3])
    }

    // MARK: - Sequence/Traverse Relationship

    func testSequenceTraverseRelationship() {
        // sequence = traverse id
        let optionals: [Int?] = [1, 2, 3]
        let identity: (Int?) -> Int? = { $0 }

        XCTAssertEqual(sequence(optionals), traverse(identity)(optionals))
    }
}
