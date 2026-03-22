import Testing
import Foundation
@testable import CoreFP
@testable import CoreFPOperators

@Suite struct ResultMonadTests {

    @Test func bind() {
        let value: Result<Int, NSError> = .success(5)
        let result = value >>- { x in .success(x * 2) }
        #expect((try? result.get()) == 10)

        let error: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))
        let errorResult = error >>- { x in .success(x * 2) }
        #expect(throws: (any Error).self) { try errorResult.get() }
    }

    @Test func flippedBind() {
        let double: (Int) -> Result<Int, NSError> = { .success($0 * 2) }
        let value: Result<Int, NSError> = .success(5)
        let result = double -<< value
        #expect((try? result.get()) == 10)
    }

    @Test func kleisliComposition() {
        let safe: (Int) -> Result<Int, NSError> = { $0 > 0 ? .success($0) : .failure(NSError(domain: "test", code: 1)) }
        let double: (Int) -> Result<Int, NSError> = { .success($0 * 2) }

        let composed = safe >=> double
        #expect((try? composed(5).get()) == 10)
        #expect(throws: (any Error).self) { try composed(-1).get() }
    }

    @Test func flippedFmap() {
        let value: Result<Int, NSError> = .success(5)
        let result = value <&> { $0 * 2 }
        #expect((try? result.get()) == 10)
    }

    @Test func alternative() {
        let success: Result<Int, NSError> = .success(5)
        let failure: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))
        let alternative: Result<Int, NSError> = .success(10)

        #expect((try? (success <|> alternative).get()) == 5)
        #expect((try? (failure <|> alternative).get()) == 10)
    }

    @Test func void() {
        let success: Result<Int, NSError> = .success(5)
        let voided = success.void()
        #expect(throws: Never.self) { try voided.get() }
    }
}
