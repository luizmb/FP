import XCTest
@testable import Reader
@testable import Either
@testable import ReaderEither
@testable import ReaderEitherOperators
@testable import EitherOperators
@testable import Operators
import FP

final class ReaderEitherOperatorsTests: XCTestCase {

    struct Environment {
        let multiplier: Int
    }

    // MARK: - Functor Operators

    func testFunctorOperatorFmap() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let mapped = { $0 * 2 } <£> reader

        let env = Environment(multiplier: 5)
        XCTAssertEqual(mapped(env), .right(10))
    }

    func testFunctorOperatorReplace() {
        let reader = Reader<Environment, Either<String, Int>> { env in
            .right(env.multiplier)
        }

        let replaced = reader £> 42

        let env = Environment(multiplier: 5)
        XCTAssertEqual(replaced(env), .right(42))
    }

    // MARK: - Applicative Operators

    func testApplicativeOperatorApply() {
        let readerFn = Reader<Environment, Either<String, (Int) -> Int>> { env in
            .right({ $0 + env.multiplier })
        }

        let readerValue = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let result = readerFn <*> readerValue

        let env = Environment(multiplier: 5)
        XCTAssertEqual(result(env), .right(15))
    }

    func testApplicativeOperatorSequenceRight() {
        let reader1 = Reader<Environment, Either<String, Int>> { _ in
            .right(5)
        }

        let reader2 = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let result = reader1 *> reader2

        let env = Environment(multiplier: 1)
        XCTAssertEqual(result(env), .right(10))
    }

    func testApplicativeOperatorSequenceLeft() {
        let reader1 = Reader<Environment, Either<String, Int>> { _ in
            .right(5)
        }

        let reader2 = Reader<Environment, Either<String, Int>> { _ in
            .right(10)
        }

        let result = reader1 <* reader2

        let env = Environment(multiplier: 1)
        XCTAssertEqual(result(env), .right(5))
    }
}
