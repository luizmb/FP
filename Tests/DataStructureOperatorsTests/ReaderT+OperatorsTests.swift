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
        let doubled = { $0 * 2 } <£^> reader

        let env = Environment(multiplier: 5, addend: 3)
        #expect(doubled(env) == 10)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        let noneResult = { $0 * 2 } <£^> noneReader
        #expect(noneResult(env) == nil)
    }

    @Test func readerOptionalFlippedFmap() {
        let reader = Reader<Environment, Int?> { env in env.multiplier }
        let doubled = reader <&^> { $0 * 2 }

        let env = Environment(multiplier: 5, addend: 3)
        #expect(doubled(env) == 10)

        let noneReader = Reader<Environment, Int?> { _ in nil }
        let noneResult = noneReader <&^> { $0 * 2 }
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
        let doubled = { $0 * 2 } <£^> reader

        let env = Environment(multiplier: 5, addend: 3)
        #expect(try doubled(env).get() == 10)

        let failureReader = Reader<Environment, Result<Int, TestError>> { _ in .failure(.test) }
        let failureResult = { $0 * 2 } <£^> failureReader
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

    // MARK: - ReaderTStateful

    @Test func readerTStatefulFmap() {
        let reader = Reader<Environment, Stateful<Int, Int>> { env in Stateful { _ in env.multiplier } }
        let result = { $0 * 3 } <£^> reader
        let env = Environment(multiplier: 4, addend: 0)
        #expect(result(env).eval(0) == 12)
    }

    @Test func readerTStatefulBind() {
        let reader = Reader<Environment, Stateful<Int, Int>> { env in Stateful { _ in env.multiplier } }
        let result = reader >>- { n in Stateful<Int, String> { _ in "\(n)" } }
        let env = Environment(multiplier: 7, addend: 0)
        #expect(result(env).eval(0) == "7")
    }

    @Test func readerTStatefulKleisli() {
        let f: (Int) -> Reader<Environment, Stateful<Int, Int>> = { n in Reader { _ in Stateful { _ in n + 1 } } }
        let g: (Int) -> Stateful<Int, String> = { n in Stateful { _ in "\(n)" } }
        let env = Environment(multiplier: 0, addend: 0)
        let result = (f >=> g)(4)
        #expect(result(env).eval(0) == "5")
    }

    // MARK: - ReaderTWriter

    @Test func readerTWriterFmap() {
        let reader = Reader<Environment, Writer<[String], Int>> { env in Writer(env.multiplier, ["init"]) }
        let result = { $0 * 2 } <£^> reader
        let env = Environment(multiplier: 5, addend: 0)
        let w = result(env)
        #expect(w.value == 10)
        #expect(w.log == ["init"])
    }

    @Test func readerTWriterBind() {
        let reader = Reader<Environment, Writer<[String], Int>> { env in Writer(env.multiplier, ["outer"]) }
        let result = reader >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        let env = Environment(multiplier: 3, addend: 0)
        let w = result(env)
        #expect(w.value == "3")
        #expect(w.log == ["outer", "inner"])
    }

    @Test func readerTWriterKleisli() {
        let f: (Int) -> Reader<Environment, Writer<[String], Int>> = { n in Reader { _ in Writer(n + 1, ["f"]) } }
        let g: (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["g"]) }
        let env = Environment(multiplier: 0, addend: 0)
        let result = (f >=> g)(4)
        let w = result(env)
        #expect(w.value == "5")
        #expect(w.log == ["f", "g"])
    }

    // MARK: - ReaderTDeferredTask

    @Test func readerTDeferredTaskFmap() async {
        let reader = Reader<Environment, DeferredTask<Int>> { env in DeferredTask { env.multiplier } }
        let result = { (n: Int) in n * 2 } <£^> reader
        let env = Environment(multiplier: 6, addend: 0)
        let value = await result(env).run()
        #expect(value == 12)
    }

    @Test func readerTDeferredTaskBind() async {
        let reader = Reader<Environment, DeferredTask<Int>> { env in DeferredTask { env.multiplier } }
        let result: Reader<Environment, DeferredTask<String>> = reader >>- { n in Reader { _ in DeferredTask { "\(n)" } } }
        let env = Environment(multiplier: 9, addend: 0)
        let value = await result(env).run()
        #expect(value == "9")
    }

    @Test func readerTDeferredTaskKleisli() async {
        let f: @Sendable (Int) -> Reader<Environment, DeferredTask<Int>> = { n in Reader { _ in DeferredTask { n + 1 } } }
        let g: @Sendable (Int) -> Reader<Environment, DeferredTask<String>> = { n in Reader { _ in DeferredTask { "\(n)" } } }
        let env = Environment(multiplier: 0, addend: 0)
        let result = (f >=> g)(4)
        let value = await result(env).run()
        #expect(value == "5")
    }

    // MARK: - ReaderTDeferredStream

    @Test func readerTDeferredStreamFmap() async {
        let reader = Reader<Environment, DeferredStream<Int>> { env in
            let m = env.multiplier
            return DeferredStream { AsyncStream { c in c.yield(m); c.finish() } }
        }
        let result = { (n: Int) in n * 3 } <£^> reader
        let env = Environment(multiplier: 4, addend: 0)
        var collected: [Int] = []
        for await v in result(env) { collected.append(v) }
        #expect(collected == [12])
    }

    @Test func readerTDeferredStreamBind() async {
        let reader = Reader<Environment, DeferredStream<Int>> { env in
            let m = env.multiplier
            return DeferredStream { AsyncStream { c in c.yield(m); c.finish() } }
        }
        let result: Reader<Environment, DeferredStream<String>> = reader >>- { n in
            Reader { _ in DeferredStream { AsyncStream { c in c.yield("\(n)"); c.finish() } } }
        }
        let env = Environment(multiplier: 5, addend: 0)
        var collected: [String] = []
        for await v in result(env) { collected.append(v) }
        #expect(collected == ["5"])
    }
}
