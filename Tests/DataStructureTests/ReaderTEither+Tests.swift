// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ReaderEitherTests {
    struct Environment {
        let multiplier: Int
    }

    // MARK: - ReaderT + Either Functor Tests

    @Test func map() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let mapped = reader.readerT.map { $0 * 2 }.rawValue

        let env = Environment(multiplier: 5)
        #expect(mapped(env) == .right(10))
    }

    @Test func mapLeft() {
        let reader = Reader<Environment, Either<String, Int>>(const(.left("error")))

        let mapped = reader.readerT.map { $0 * 2 }.rawValue

        let env = Environment(multiplier: 5)
        #expect(mapped(env) == .left("error"))
    }

    // MARK: - ReaderT + Either Applicative Tests

    @Test func apply() {
        let readerFn = Reader<Environment, Either<String, @Sendable (Int) -> Int>> { env in
            .right { $0 + env.multiplier }
        }

        let readerValue = Reader<Environment, Either<String, Int>>(const(.right(10)))

        let result = ReaderTEither<Environment, String, Int>.apply(readerFn.readerT, readerValue.readerT).rawValue

        let env = Environment(multiplier: 5)
        #expect(result(env) == .right(15))
    }

    @Test func liftA2() {
        let reader1 = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let reader2 = Reader<Environment, Either<String, Int>>(const(.right(10)))

        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }
        let combined = ReaderTEither<Environment, String, Int>.liftA2(add)(reader1.readerT, reader2.readerT).rawValue

        let env = Environment(multiplier: 5)
        #expect(combined(env) == .right(15))
    }

    // MARK: - ReaderT + Either Monad Tests

    @Test func flatMap() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let bound = reader.readerT.flatMap { value in
            ReaderTEither<Environment, String, String>(Reader { env in
                .right("\(value + env.multiplier)")
            })
        }.rawValue

        let env = Environment(multiplier: 5)
        #expect(bound(env) == .right("10"))
    }
}
