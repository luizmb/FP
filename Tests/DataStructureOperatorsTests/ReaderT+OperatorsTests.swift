import DataStructureOperators
import DataStructure
import Testing
@testable import CoreFP
import CoreFPOperators

@Suite struct ReaderTTests {

    struct Environment {
        let multiplier: Int
        let addend: Int
    }

    // MARK: - ReaderT + Optional Tests

    @Test func readerOptionalFmap() {
        let reader = Reader<Environment, Int?> { env in env.multiplier }
        let doubled = { $0 * 2 } <£> reader

        let env = Environment(multiplier: 5, addend: 3)
        #expect(doubled(env) == 10)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        let noneResult = { $0 * 2 } <£> noneReader
        #expect(noneResult(env) == nil)
    }

    @Test func readerOptionalApply() {
        let readerFn = Reader<Environment, ((Int) -> Int)?> { env in
            { $0 * env.multiplier }
        }
        let readerValue = Reader<Environment, Int?> { env in env.addend }

        let result = readerFn <*> readerValue
        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == 15)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        let noneResult = readerFn <*> noneReader
        #expect(noneResult(env) == nil)
    }

    @Test func readerOptionalSequenceRight() {
        let reader1 = Reader<Environment, Int?> { env in env.multiplier }
        let reader2 = Reader<Environment, Int?> { env in env.addend }

        let result = reader1 *> reader2
        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == 3)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        #expect((reader1 *> noneReader)(env) == nil)
        #expect((noneReader *> reader2)(env) == nil)
    }

    @Test func readerOptionalSequenceLeft() {
        let reader1 = Reader<Environment, Int?> { env in env.multiplier }
        let reader2 = Reader<Environment, Int?> { env in env.addend }

        let result = reader1 <* reader2
        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == 5)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        #expect((reader1 <* noneReader)(env) == nil)
        #expect((noneReader <* reader2)(env) == nil)
    }

    // MARK: - ReaderT + Result Tests

    enum TestError: Error, Equatable {
        case test
    }

    @Test func readerResultFmap() throws {
        let reader = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }
        let doubled = { $0 * 2 } <£> reader

        let env = Environment(multiplier: 5, addend: 3)
        #expect(try doubled(env).get() == 10)

        let failureReader = Reader<Environment, Result<Int, TestError>> { _ in .failure(.test) }
        let failureResult = { $0 * 2 } <£> failureReader
        #expect(throws: (any Error).self) { try failureResult(env).get() }
    }

    @Test func readerResultApply() throws {
        let readerFn = Reader<Environment, Result<(Int) -> Int, TestError>> { env in
            .success({ $0 * env.multiplier })
        }
        let readerValue = Reader<Environment, Result<Int, TestError>> { env in .success(env.addend) }

        let result = readerFn <*> readerValue
        let env = Environment(multiplier: 5, addend: 3)
        #expect(try result(env).get() == 15)

        let failureReader = Reader<Environment, Result<Int, TestError>> { _ in .failure(.test) }
        let failureResult = readerFn <*> failureReader
        #expect(throws: (any Error).self) { try failureResult(env).get() }
    }

    @Test func readerResultSequenceRight() throws {
        let reader1 = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }
        let reader2 = Reader<Environment, Result<Int, TestError>> { env in .success(env.addend) }

        let result = reader1 *> reader2
        let env = Environment(multiplier: 5, addend: 3)
        #expect(try result(env).get() == 3)

        let failureReader = Reader<Environment, Result<Int, TestError>> { _ in .failure(.test) }
        #expect(throws: (any Error).self) { try (reader1 *> failureReader)(env).get() }
    }

    @Test func readerResultSequenceLeft() throws {
        let reader1 = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }
        let reader2 = Reader<Environment, Result<Int, TestError>> { env in .success(env.addend) }

        let result = reader1 <* reader2
        let env = Environment(multiplier: 5, addend: 3)
        #expect(try result(env).get() == 5)

        let failureReader = Reader<Environment, Result<Int, TestError>> { _ in .failure(.test) }
        #expect(throws: (any Error).self) { try (reader1 <* failureReader)(env).get() }
    }

    // MARK: - ReaderT + Either Tests
    // Either-specific tests removed due to soft dependency pattern
    // Users who import Either can test this functionality in their own code

    // MARK: - ReaderT Applicative Functions

    @Test func applyOptional() {
        let readerFn = Reader<Environment, ((Int) -> Int)?> { _ in { $0 * 2 } }
        let readerValue = Reader<Environment, Int?> { env in env.multiplier }

        let result = applyReaderOptional(readerFn, readerValue)
        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == 10)
    }

    @Test func liftA2Optional() {
        let reader1 = Reader<Environment, Int?> { env in env.multiplier }
        let reader2 = Reader<Environment, Int?> { env in env.addend }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let lifted: (Reader<Environment, Int?>, Reader<Environment, Int?>) -> Reader<Environment, Int?> = liftA2ReaderOptional(add)
        let result = lifted(reader1, reader2)

        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == 8)
    }

    @Test func applyResult() throws {
        let readerFn = Reader<Environment, Result<(Int) -> Int, TestError>> { _ in .success({ $0 * 2 }) }
        let readerValue = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }

        let result = applyReaderResult(readerFn, readerValue)
        let env = Environment(multiplier: 5, addend: 3)
        #expect(try result(env).get() == 10)
    }

    @Test func liftA2Result() throws {
        let reader1 = Reader<Environment, Result<Int, TestError>> { env in .success(env.multiplier) }
        let reader2 = Reader<Environment, Result<Int, TestError>> { env in .success(env.addend) }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let lifted: (Reader<Environment, Result<Int, TestError>>, Reader<Environment, Result<Int, TestError>>) -> Reader<Environment, Result<Int, TestError>> = liftA2ReaderResult(add)
        let result = lifted(reader1, reader2)

        let env = Environment(multiplier: 5, addend: 3)
        #expect(try result(env).get() == 8)
    }

    // Either-specific applicative function tests removed due to soft dependency pattern
}
