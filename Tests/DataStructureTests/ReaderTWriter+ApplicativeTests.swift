// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct ReaderTWriterApplicativeTests {
    struct Env { let value: Int }

    // MARK: - Reader<Env, Writer<W, A>> — Reader as outer, Writer as inner

    @Test func apply() {
        let fn: @Sendable (Int) -> String = { "\($0)" }
        let rf: Reader<Env, Writer<[String], @Sendable (Int) -> String>> = Reader(const(Writer(fn, ["fn"])))
        let ra: Reader<Env, Writer<[String], Int>> = Reader { env in Writer(env.value, ["val"]) }
        let result = ReaderTWriter<Env, [String], String>.apply(rf.readerT, ra.readerT).rawValue
        let w = result(Env(value: 7))
        #expect(w.value == "7")
        #expect(w.log == ["fn", "val"])
    }

    @Test func applyUsesEnv() {
        let rf: Reader<Env, Writer<[String], @Sendable (Int) -> Int>> = Reader { env in Writer({ $0 + env.value }, ["fn"]) }
        let ra: Reader<Env, Writer<[String], Int>> = Reader { env in Writer(env.value * 2, ["val"]) }
        let result = ReaderTWriter<Env, [String], Int>.apply(rf.readerT, ra.readerT).rawValue
        let env = Env(value: 3)
        let w = result(env)
        #expect(w.value == 9)
        #expect(w.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs: Reader<Env, Writer<[String], Int>> = Reader(const(Writer(1, ["a"])))
        let rhs: Reader<Env, Writer<[String], String>> = Reader(const(Writer("hello", ["b"])))
        let result = lhs.readerT.seqRight(rhs.readerT).rawValue
        let w = result(Env(value: 0))
        #expect(w.value == "hello")
        #expect(w.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs: Reader<Env, Writer<[String], Int>> = Reader(const(Writer(99, ["a"])))
        let rhs: Reader<Env, Writer<[String], String>> = Reader(const(Writer("ignored", ["b"])))
        let result = lhs.readerT.seqLeft(rhs.readerT).rawValue
        let w = result(Env(value: 0))
        #expect(w.value == 99)
        #expect(w.log == ["a", "b"])
    }

    @Test func liftA2() {
        let ra: Reader<Env, Writer<[String], Int>> = Reader { env in Writer(env.value, ["a"]) }
        let rb: Reader<Env, Writer<[String], Int>> = Reader { env in Writer(env.value * 2, ["b"]) }
        let result = ReaderTWriter<Env, [String], Int>.liftA2(+)(ra.readerT, rb.readerT).rawValue
        let env = Env(value: 4)
        let w = result(env)
        #expect(w.value == 12)
        #expect(w.log == ["a", "b"])
    }

    // MARK: - liftA2 runs each reader once

    @Test func liftA2RunsEachReaderOnce() {
        let counter = CallCounter()
        let ra: Reader<CallCounter, Writer<[String], Int>> = Reader { env in env.tick(); return Writer(1, ["a"]) }
        let rb: Reader<CallCounter, Writer<[String], Int>> = Reader { env in env.tick(); return Writer(2, ["b"]) }
        let w = ReaderTWriter<CallCounter, [String], Int>.liftA2 { (a: Int, b: Int) in a + b }(ra.readerT, rb.readerT).rawValue(counter)
        #expect(w.value == 3)
        #expect(w.log == ["a", "b"])
        #expect(counter.count == 2)
    }
}

import Foundation

// Test-only invocation counter. `@unchecked Sendable` is sound: every access goes
// through `lock`.
private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0

    var count: Int { lock.withLock { calls } }
    func tick() { lock.withLock { calls += 1 } }
}
