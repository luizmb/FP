import XCTest
@testable import Reader
@testable import Either
@testable import ReaderEither
import FP

final class ReaderEitherTests: XCTestCase {

    struct Environment {
        let multiplier: Int
    }

    // MARK: - ReaderT + Either Functor Tests

    func testMapT() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let mapped = reader.mapT { $0 * 2 }

        let env = Environment(multiplier: 5)
        XCTAssertEqual(mapped(env), .right(10))
    }

    func testMapTLeft() {
        let reader = Reader<Environment, Either<String, Int>> { _ in
            .left("error")
        }

        let mapped = reader.mapT { $0 * 2 }

        let env = Environment(multiplier: 5)
        XCTAssertEqual(mapped(env), .left("error"))
    }

    // MARK: - ReaderT + Either Applicative Tests

    func testApplyReaderEither() {
        let readerFn = Reader<Environment, Either<String, (Int) -> Int>> { env in
            .right({ $0 + env.multiplier })
        }

        let readerValue = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let result = applyReaderEither(readerFn, readerValue)

        let env = Environment(multiplier: 5)
        XCTAssertEqual(result(env), .right(15))
    }

    func testLiftA2ReaderEither() {
        let reader1 = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let reader2 = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let combined = liftA2ReaderEither(add)(reader1, reader2)

        let env = Environment(multiplier: 5)
        XCTAssertEqual(combined(env), .right(15))
    }

    // MARK: - ReaderT + Either Monad Tests

    func testFlatMapT() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let bound = reader.flatMapT { value in
            Reader<Environment, Either<String, String>> { env in
                .right("\(value + env.multiplier)")
            }
        }

        let env = Environment(multiplier: 5)
        XCTAssertEqual(bound(env), .right("10"))
    }
}
