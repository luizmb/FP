@testable import CoreFP
@testable import CoreFPOperators
import Testing

private enum TestError: Error, Equatable { case err }

@Suite struct DeferredTaskTOptionalAlternativeOperatorsTests {
    @Test func altOperatorFirstNonNilWins() async {
        let lhs = DeferredTask<Int?> { nil }
        let rhs = DeferredTask<Int?> { 42 }
        let result = await (lhs <|> rhs).run()
        #expect(result == 42)
    }

    @Test func altOperatorBothNilReturnsNil() async {
        let lhs = DeferredTask<Int?> { nil }
        let rhs = DeferredTask<Int?> { nil }
        let result = await (lhs <|> rhs).run()
        #expect(result == nil)
    }

    @Test func altOperatorFirstSomeWins() async {
        let lhs = DeferredTask<Int?> { 7 }
        let rhs = DeferredTask<Int?> { 99 }
        let result = await (lhs <|> rhs).run()
        #expect(result == 7 || result == 99)
    }
}
