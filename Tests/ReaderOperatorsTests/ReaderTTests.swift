import XCTest
@testable import FP
@testable import Reader
@testable import ReaderOperators
import Operators

final class ReaderTTests: XCTestCase {

    struct Environment {
        let multiplier: Int
        let addend: Int
    }

    // MARK: - ReaderT + Optional Tests

    func testReaderOptionalFmap() {
        let reader = Reader<Environment, Int?> { env in env.multiplier }
        let doubled = { $0 * 2 } <£> reader

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(doubled(env), 10)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        let noneResult = { $0 * 2 } <£> noneReader
        XCTAssertNil(noneResult(env))
    }

    func testReaderOptionalApply() {
        let readerFn = Reader<Environment, ((Int) -> Int)?> { env in
            { $0 * env.multiplier }
        }
        let readerValue = Reader<Environment, Int?> { env in env.addend }

        let result = readerFn <*> readerValue
        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(result(env), 15)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        let noneResult = readerFn <*> noneReader
        XCTAssertNil(noneResult(env))
    }

    func testReaderOptionalSequenceRight() {
        let reader1 = Reader<Environment, Int?> { env in env.multiplier }
        let reader2 = Reader<Environment, Int?> { env in env.addend }

        let result = reader1 *> reader2
        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(result(env), 3)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        XCTAssertNil((reader1 *> noneReader)(env))
        XCTAssertNil((noneReader *> reader2)(env))
    }

    func testReaderOptionalSequenceLeft() {
        let reader1 = Reader<Environment, Int?> { env in env.multiplier }
        let reader2 = Reader<Environment, Int?> { env in env.addend }

        let result = reader1 <* reader2
        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(result(env), 5)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        XCTAssertNil((reader1 <* noneReader)(env))
        XCTAssertNil((noneReader <* reader2)(env))
    }

    // MARK: - ReaderT + Result Tests

    enum TestError: Error, Equatable {
        case test
    }

    func testReaderResultFmap() {
        let reader = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }
        let doubled = { $0 * 2 } <£> reader

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(try? doubled(env).get(), 10)

        let failureReader = Reader<Environment, Result<Int, TestError>> { _ in .failure(.test) }
        let failureResult = { $0 * 2 } <£> failureReader
        XCTAssertThrowsError(try failureResult(env).get())
    }

    func testReaderResultApply() {
        let readerFn = Reader<Environment, Result<(Int) -> Int, TestError>> { env in
            .success({ $0 * env.multiplier })
        }
        let readerValue = Reader<Environment, Result<Int, TestError>> { env in .success(env.addend) }

        let result = readerFn <*> readerValue
        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(try? result(env).get(), 15)

        let failureReader = Reader<Environment, Result<Int, TestError>> { _ in .failure(.test) }
        let failureResult = readerFn <*> failureReader
        XCTAssertThrowsError(try failureResult(env).get())
    }

    func testReaderResultSequenceRight() {
        let reader1 = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }
        let reader2 = Reader<Environment, Result<Int, TestError>> { env in .success(env.addend) }

        let result = reader1 *> reader2
        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(try? result(env).get(), 3)

        let failureReader = Reader<Environment, Result<Int, TestError>> { _ in .failure(.test) }
        XCTAssertThrowsError(try (reader1 *> failureReader)(env).get())
    }

    func testReaderResultSequenceLeft() {
        let reader1 = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }
        let reader2 = Reader<Environment, Result<Int, TestError>> { env in .success(env.addend) }

        let result = reader1 <* reader2
        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(try? result(env).get(), 5)

        let failureReader = Reader<Environment, Result<Int, TestError>> { _ in .failure(.test) }
        XCTAssertThrowsError(try (reader1 <* failureReader)(env).get())
    }

    // MARK: - ReaderT + Either Tests
    // Either-specific tests removed due to soft dependency pattern
    // Users who import Either can test this functionality in their own code

    // MARK: - ReaderT Applicative Functions

    func testApplyReaderOptional() {
        let readerFn = Reader<Environment, ((Int) -> Int)?> { _ in { $0 * 2 } }
        let readerValue = Reader<Environment, Int?> { env in env.multiplier }

        let result = applyReaderOptional(readerFn, readerValue)
        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(result(env), 10)
    }

    func testLiftA2ReaderOptional() {
        let reader1 = Reader<Environment, Int?> { env in env.multiplier }
        let reader2 = Reader<Environment, Int?> { env in env.addend }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let lifted: (Reader<Environment, Int?>, Reader<Environment, Int?>) -> Reader<Environment, Int?> = liftA2ReaderOptional(add)
        let result = lifted(reader1, reader2)

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(result(env), 8)
    }

    func testApplyReaderResult() {
        let readerFn = Reader<Environment, Result<(Int) -> Int, TestError>> { _ in .success({ $0 * 2 }) }
        let readerValue = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }

        let result = applyReaderResult(readerFn, readerValue)
        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(try? result(env).get(), 10)
    }

    func testLiftA2ReaderResult() {
        let reader1 = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }
        let reader2 = Reader<Environment, Result<Int, TestError>> { env in .success(env.addend) }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let lifted: (Reader<Environment, Result<Int, TestError>>, Reader<Environment, Result<Int, TestError>>) -> Reader<Environment, Result<Int, TestError>> = liftA2ReaderResult(add)
        let result = lifted(reader1, reader2)

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(try? result(env).get(), 8)
    }

    // Either-specific applicative function tests removed due to soft dependency pattern
}
