import Testing
@testable import CoreFP
@testable import CoreFPOperators

@Suite struct ResultFunctorTests {

    enum TestError: Error, Equatable {
        case test
    }

    // MARK: - Basic Functor Tests

    @Test func fmap() {
        let success: Result<Int, TestError> = .success(5)
        let result = success.map { $0 * 2 }
        #expect((try? result.get()) == 10)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = failure.map { $0 * 2 }
        #expect(throws: (any Error).self) { try failureResult.get() }
    }

    @Test func curriedFmap() {
        let double: (Int) -> Int = { $0 * 2 }
        let fmap = Result<Int, TestError>.fmap(double)

        let success: Result<Int, TestError> = .success(5)
        #expect((try? fmap(success).get()) == 10)

        let failure: Result<Int, TestError> = .failure(.test)
        #expect(throws: (any Error).self) { try fmap(failure).get() }
    }

    // MARK: - Functor Laws

    @Test func functorIdentityLaw() {
        // fmap id == id
        let success: Result<Int, TestError> = .success(5)
        let failure: Result<Int, TestError> = .failure(.test)

        #expect((try? success.map(id).get()) == (try? success.get()))
        #expect(throws: (any Error).self) { try failure.map(id).get() }
    }

    @Test func functorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let value: Result<Int, TestError> = .success(5)

        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        let composed = value.map(compose(f, g))
        let separate = value.map(f).map(g)

        #expect((try? composed.get()) == (try? separate.get()))
    }

    // MARK: - Functor Operators

    @Test func fmapOperator() {
        let success: Result<Int, TestError> = .success(5)
        let result = { $0 * 2 } <£> success
        #expect((try? result.get()) == 10)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = { $0 * 2 } <£> failure
        #expect(throws: (any Error).self) { try failureResult.get() }
    }

    @Test func mapReplaceOperator() {
        let success: Result<Int, TestError> = .success(5)
        let result = success £> 99
        #expect((try? result.get()) == 99)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = failure £> 99
        #expect(throws: (any Error).self) { try failureResult.get() }
    }

    @Test func mapReplaceFlippedOperator() {
        let success: Result<Int, TestError> = .success(5)
        let result = 42 <£ success
        #expect((try? result.get()) == 42)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = 42 <£ failure
        #expect(throws: (any Error).self) { try failureResult.get() }
    }

    @Test func flippedFmapOperator() {
        let success: Result<Int, TestError> = .success(5)
        let result = success <&> { $0 * 2 }
        #expect((try? result.get()) == 10)

        let failure: Result<Int, TestError> = .failure(.test)
        let failureResult = failure <&> { $0 * 2 }
        #expect(throws: (any Error).self) { try failureResult.get() }
    }
}
