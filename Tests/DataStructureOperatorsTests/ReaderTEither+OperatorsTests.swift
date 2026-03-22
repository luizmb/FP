import DataStructureOperators
import DataStructure
import Testing
@testable import CoreFPOperators
import CoreFP

@Suite struct ReaderEitherOperatorsTests {

    struct Environment {
        let multiplier: Int
    }

    // MARK: - Functor Operators

    @Test func functorOperatorFmap() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let mapped = { $0 * 2 } <£^> reader

        let env = Environment(multiplier: 5)
        #expect(mapped(env) == .right(10))
    }

    @Test func functorOperatorReplace() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let replaced = reader £> 42

        let env = Environment(multiplier: 5)
        #expect(replaced(env) == .right(42))
    }

    // MARK: - Applicative Operators

    @Test func applicativeOperatorApply() {
        let readerFn = Reader<Environment, Either<String, (Int) -> Int>> { env in
            .right({ $0 + env.multiplier })
        }

        let readerValue = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let result = readerFn <*> readerValue

        let env = Environment(multiplier: 5)
        #expect(result(env) == .right(15))
    }

    @Test func applicativeOperatorSequenceRight() {
        let reader1 = Reader<Environment, Either<String, Int>> { _ in
            .right(5)
        }

        let reader2 = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let result = reader1 *> reader2

        let env = Environment(multiplier: 1)
        #expect(result(env) == .right(10))
    }

    @Test func applicativeOperatorSequenceLeft() {
        let reader1 = Reader<Environment, Either<String, Int>> { _ in
            .right(5)
        }

        let reader2 = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let result = reader1 <* reader2

        let env = Environment(multiplier: 1)
        #expect(result(env) == .right(5))
    }
}
