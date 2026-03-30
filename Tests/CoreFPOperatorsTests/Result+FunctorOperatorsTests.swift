@testable import CoreFP
@testable import CoreFPOperators
import Testing

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

    // MARK: - Bifunctor

    @Test func bimapSuccess() {
        let success: Result<Int, TestError> = .success(5)
        let result: Result<Int, TestError> = success.bimap({ $0 * 2 }, id)
        #expect((try? result.get()) == 10)
    }

    @Test func bimapFailure() {
        let failure: Result<Int, TestError> = .failure(.test)
        let result: Result<Int, TestError> = failure.bimap({ $0 * 2 }, id)
        #expect(throws: (any Error).self) { try result.get() }
    }

    @Test func bimapCurried() {
        let transform = Result<Int, TestError>.bimap({ $0 * 3 }, id)
        #expect((try? transform(.success(4)).get()) == 12)
        #expect(throws: (any Error).self) { try transform(.failure(.test)).get() }
    }

    @Test func bimapPointFree() {
        let values: [Result<Int, TestError>] = [.success(2), .failure(.test), .success(5)]
        let results = values.map(Result<Int, TestError>.bimap({ $0 * 2 }, id))
        #expect((try? results[0].get()) == 4)
        #expect(throws: (any Error).self) { try results[1].get() }
        #expect((try? results[2].get()) == 10)
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
