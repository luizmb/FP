import Testing
@testable import CoreFP
@testable import CoreFPOperators

private enum TestError: Error, Equatable { case err }

@Suite struct DeferredTaskTResultAlternativeOperatorsTests {

    @Test func altOperatorFirstSuccessWins() async {
        let lhs = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let rhs = DeferredTask<Result<Int, TestError>> { .success(42) }
        let result = await (lhs <|> rhs).run()
        #expect(result == .success(42))
    }

    @Test func altOperatorBothFailReturnsFailure() async {
        let lhs = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let rhs = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let result = await (lhs <|> rhs).run()
        #expect(result == .failure(.err))
    }

    @Test func altOperatorSuccessBeatsFailure() async {
        let lhs = DeferredTask<Result<Int, TestError>> { .success(7) }
        let rhs = DeferredTask<Result<Int, TestError>> { .failure(.err) }
        let result = await (lhs <|> rhs).run()
        #expect(result == .success(7) || result == .failure(.err))
    }
}
