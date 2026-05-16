import DataStructure
import Foundation
import Testing

@Suite struct WriterCoreTests {
    // MARK: - Construction & Execution

    @Test func writerInit() {
        let w = Writer<[String], Int>(42, ["hello"])
        #expect(w.value == 42)
        #expect(w.log == ["hello"])
    }

    @Test func runWriter() {
        let w = Writer<[String], Int>(10, ["a"])
        let (value, log) = w.runWriter()
        #expect(value == 10)
        #expect(log == ["a"])
    }

    @Test func evalWriter() {
        let w = Writer<[String], Int>(7, ["log"])
        #expect(w.evalWriter() == 7)
    }

    @Test func execWriter() {
        let w = Writer<[String], Int>(0, ["entry"])
        #expect(w.execWriter() == ["entry"])
    }

    // MARK: - Equatable

    @Test func equatable() {
        let a = Writer<[String], Int>(1, ["x"])
        let b = Writer<[String], Int>(1, ["x"])
        let c = Writer<[String], Int>(2, ["x"])
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - Primitives

    @Test func pure() {
        let w = Writer<[String], Int>.pure(42)
        #expect(w.value == 42)
        #expect(w.log == [])
    }

    @Test func tell() {
        let w = Writer<[String], Void>.tell(["logged"])
        #expect(w.log == ["logged"])
    }

    @Test func listen() {
        let w = Writer<[String], Int>(5, ["a", "b"])
        let heard = w.listen()
        #expect(heard.value.0 == 5)
        #expect(heard.value.1 == ["a", "b"])
        #expect(heard.log == ["a", "b"])
    }

    @Test func censor() {
        let w = Writer<[String], Int>(1, ["hello", "world"])
        let censored = w.censor { $0.map { $0.uppercased() } }
        #expect(censored.log == ["HELLO", "WORLD"])
        #expect(censored.value == 1)
    }

    @Test func pass() {
        let w = Writer<[String], (Int, ([String]) -> [String])>(
            (42, { log in log + ["appended"] }),
            ["original"]
        )
        let result = writerPass(w)
        #expect(result.value == 42)
        #expect(result.log == ["original", "appended"])
    }

    // MARK: - Functor

    @Test func fmap() {
        let w = Writer<[String], Int>(5, ["entry"])
        let mapped = w.map { $0 * 2 }
        #expect(mapped.value == 10)
        #expect(mapped.log == ["entry"])
    }

    @Test func mapWriter() {
        let w = Writer<[String], Int>(3, ["x"])
        let mapped = w.mapWriter { "\($0)" }
        #expect(mapped.value == "3")
        #expect(mapped.log == ["x"])
    }

    @Test func staticFmap() {
        let double = Writer<[String], Int>.fmap { $0 * 3 }
        let w = Writer<[String], Int>(4, ["y"])
        #expect(double(w).value == 12)
    }

    // MARK: - Applicative

    @Test func apply() {
        let wf = Writer<[String], (Int) -> String>(
            { "\($0)" },
            ["fn-log"]
        )
        let wa = Writer<[String], Int>(7, ["val-log"])
        let result = Writer<[String], String>.apply(wf, wa)
        #expect(result.value == "7")
        #expect(result.log == ["fn-log", "val-log"])
    }

    @Test func seqRight() {
        let a = Writer<[String], Int>(1, ["a"])
        let b = Writer<[String], Int>(2, ["b"])
        let result = a.seqRight(b)
        #expect(result.value == 2)
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let a = Writer<[String], Int>(1, ["a"])
        let b = Writer<[String], Int>(2, ["b"])
        let result = a.seqLeft(b)
        #expect(result.value == 1)
        #expect(result.log == ["a", "b"])
    }

    @Test func liftA2() {
        let wa = Writer<[String], Int>(3, ["a"])
        let wb = Writer<[String], Int>(4, ["b"])
        let result = Writer<[String], Int>.liftA2(+)(wa, wb)
        #expect(result.value == 7)
        #expect(result.log == ["a", "b"])
    }

    // MARK: - Monad

    @Test func flatMap() {
        let w = Writer<[String], Int>(5, ["outer"])
        let result = w.flatMap { n in
            Writer<[String], String>("\(n)", ["inner"])
        }
        #expect(result.value == "5")
        #expect(result.log == ["outer", "inner"])
    }

    @Test func bind() {
        let double: (Int) -> Writer<[String], Int> = { n in
            Writer<[String], Int>(n * 2, ["\(n)"])
        }
        let w = Writer<[String], Int>.bind(double)(Writer<[String], Int>(3, ["start"]))
        #expect(w.value == 6)
        #expect(w.log == ["start", "3"])
    }

    @Test func kleisli() {
        let step1: (Int) -> Writer<[String], Int> = { n in
            Writer<[String], Int>(n + 1, ["step1"])
        }
        let step2: (Int) -> Writer<[String], String> = { n in
            Writer<[String], String>("\(n)", ["step2"])
        }
        let composed = Writer<[String], Int>.kleisli(step1, step2)
        let result = composed(4)
        #expect(result.value == "5")
        #expect(result.log == ["step1", "step2"])
    }

    @Test func join() {
        let inner = Writer<[String], Int>(42, ["inner"])
        let outer = Writer<[String], Writer<[String], Int>>(inner, ["outer"])
        let flat = Writer<[String], Writer<[String], Int>>.join(outer)
        #expect(flat.value == 42)
        #expect(flat.log == ["outer", "inner"])
    }

    // MARK: - Zip

    @Test func zipCombinesValuesAndLogs() {
        let wa = Writer<[String], Int>(1, ["log-a"])
        let wb = Writer<[String], String>("x", ["log-b"])
        let result = Writer<[String], (Int, String)>.zip(wa, wb)
        #expect(result.value == (1, "x"))
        #expect(result.log == ["log-a", "log-b"])
    }

    @Test func zipWithEmptyLogs() {
        let wa = Writer<[String], Int>(42, [])
        let wb = Writer<[String], Int>(58, [])
        let result = Writer<[String], (Int, Int)>.zip(wa, wb)
        #expect(result.value == (42, 58))
        #expect(result.log == [])
    }

    @Test func zip3CombinesAllValuesAndLogs() {
        let wa = Writer<[String], Int>(1, ["a"])
        let wb = Writer<[String], String>("x", ["b"])
        let wc = Writer<[String], Bool>(true, ["c"])
        let result = Writer<[String], (Int, String, Bool)>.zip3(wa, wb, wc)
        #expect(result.value == (1, "x", true))
        #expect(result.log == ["a", "b", "c"])
    }

    @Test func zip4CombinesAllValuesAndLogs() {
        let wa = Writer<[String], Int>(1, ["a"])
        let wb = Writer<[String], String>("x", ["b"])
        let wc = Writer<[String], Bool>(true, ["c"])
        let wd = Writer<[String], Double>(3.14, ["d"])
        let result = Writer<[String], (Int, String, Bool, Double)>.zip4(wa, wb, wc, wd)
        #expect(result.value == (1, "x", true, 3.14))
        #expect(result.log == ["a", "b", "c", "d"])
    }

    // MARK: - Log accumulation

    @Test func logsAccumulateAcrossChain() {
        let result = Writer<[String], Int>.pure(1)
            .flatMap { n in Writer(n + 1, ["step1"]) }
            .flatMap { n in Writer(n * 3, ["step2"]) }
            .flatMap { n in Writer("\(n)", ["step3"]) }
        #expect(result.value == "6")
        #expect(result.log == ["step1", "step2", "step3"])
    }

    // MARK: - join / void

    @Test func joinFreeFunction() {
        let nested = Writer<[String], Writer<[String], Int>>(Writer(42, ["inner"]), ["outer"])
        let result = DataStructure.join(nested)
        #expect(result.value == 42)
        #expect(result.log == ["outer", "inner"])
    }

    @Test func voidFreeFunction() {
        let writer = Writer<[String], Int>(99, ["log"])
        let voided = DataStructure.void(writer)
        #expect(voided.log == ["log"])
    }

    // MARK: - Conditional conformances

    @Test func codable_roundTrip() throws {
        let w = Writer<[String], Int>(42, ["step1", "step2"])
        let data = try JSONEncoder().encode(w)
        let decoded = try JSONDecoder().decode(Writer<[String], Int>.self, from: data)
        #expect(decoded == w)
    }

    @Test func description() {
        let w = Writer<String, Int>(42, "log")
        #expect(w.description == "Writer(value: 42, log: log)")
    }
}
