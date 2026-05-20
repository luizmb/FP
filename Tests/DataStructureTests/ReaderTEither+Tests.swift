import DataStructure
import Testing

@Suite struct ReaderEitherTests {
    struct Environment {
        let multiplier: Int
    }

    // MARK: - ReaderT + Either Functor Tests

    @Test func mapT() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let mapped = reader.mapT { $0 * 2 }

        let env = Environment(multiplier: 5)
        #expect(mapped(env) == .right(10))
    }

    @Test func mapTLeft() {
        let reader = Reader<Environment, Either<String, Int>> { _ in
            .left("error")
        }

        let mapped = reader.mapT { $0 * 2 }

        let env = Environment(multiplier: 5)
        #expect(mapped(env) == .left("error"))
    }

    // MARK: - ReaderT + Either Applicative Tests

    @Test func apply() {
        let readerFn = Reader<Environment, Either<String, @Sendable (Int) -> Int>> { env in
            .right({ $0 + env.multiplier })
        }

        let readerValue = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let result = applyReaderEither(readerFn, readerValue)

        let env = Environment(multiplier: 5)
        #expect(result(env) == .right(15))
    }

    @Test func liftA2() {
        let reader1 = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let reader2 = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }
        let combined = liftA2ReaderEither(add)(reader1, reader2)

        let env = Environment(multiplier: 5)
        #expect(combined(env) == .right(15))
    }

    // MARK: - ReaderT + Either Monad Tests

    @Test func flatMapT() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let bound = reader.flatMapT { value in
            Reader<Environment, Either<String, String>> { env in
                .right("\(value + env.multiplier)")
            }
        }

        let env = Environment(multiplier: 5)
        #expect(bound(env) == .right("10"))
    }
}
