// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ReaderEitherOperatorsTests {
    struct Environment {
        let multiplier: Int
    }

    // MARK: - Functor Operators

    @Test func replaceOperatorIsBaseReaderReplace() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .left("ignored \(env.multiplier)")
        }

        // No transformer overload: `£>` replaces the whole Reader output, not the inner Right.
        let replaced: Reader<Environment, Int> = reader £> 42

        let env = Environment(multiplier: 5)
        #expect(replaced(env) == 42)
    }

    // MARK: - Applicative Operators

    @Test func applicativeOperatorApply() {
        let readerFn = Reader<Environment, Either<String, @Sendable (Int) -> Int>> { env in
            .right { $0 + env.multiplier }
        }

        let readerValue = Reader<Environment, Either<String, Int>>(const(.right(10)))

        let result = (readerFn.readerT <*> readerValue.readerT).rawValue

        let env = Environment(multiplier: 5)
        #expect(result(env) == .right(15))
    }

    @Test func applicativeOperatorSequenceRight() {
        let reader1 = Reader<Environment, Either<String, Int>>(const(.right(5)))

        let reader2 = Reader<Environment, Either<String, Int>>(const(.right(10)))

        let result = (reader1.readerT *> reader2.readerT).rawValue

        let env = Environment(multiplier: 1)
        #expect(result(env) == .right(10))
    }

    @Test func applicativeOperatorSequenceLeft() {
        let reader1 = Reader<Environment, Either<String, Int>>(const(.right(5)))

        let reader2 = Reader<Environment, Either<String, Int>>(const(.right(10)))

        let result = (reader1.readerT <* reader2.readerT).rawValue

        let env = Environment(multiplier: 1)
        #expect(result(env) == .right(5))
    }
}
