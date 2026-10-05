// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Laws on the struct API of the Writer-outer stacks (`WriterT w M`): functor identity / composition for every
// stack; for the `MonadT` stacks (Either, Optional, Result) `apply == ap` plus the monad laws; for the
// applicative-only stacks applicative identity and homomorphism. Each stack also checks its lifting property
// (`.writerT`) and its escape hatch (`mapWriterT` / `mapExceptT` / `mapMaybeT`).

private typealias Log = [String]

private enum Boom: Error, Equatable {
    case boom
}

private let inc: @Sendable (Int) -> Int = { $0 + 1 }
private let dbl: @Sendable (Int) -> Int = { $0 * 2 }
private let idInt: @Sendable (Int) -> Int = id
private let incThenDbl: @Sendable (Int) -> Int = { dbl(inc($0)) }
private let appendLog: @Sendable (Log) -> Log = { $0 + ["hatch"] }

// MARK: - WriterTEither (MonadT)

@Suite struct WriterTEitherLawTests {
    private typealias Stack<A> = WriterTEither<Log, String, A>

    private static let values: [Stack<Int>] = [Stack(Writer(.right(1), ["a"])), Stack(Writer(.left("e"), ["a!"]))]
    private static let functions: [Stack<@Sendable (Int) -> Int>] = [
        Stack(Writer(.right(inc), ["f"])),
        Stack(Writer(.left("f"), ["f!"]))
    ]
    private static let fn: @Sendable (Int) -> Stack<Int> = { n in Stack(Writer(n > 5 ? .left("big") : .right(n + 1), ["f\(n)"])) }
    private static let gn: @Sendable (Int) -> Stack<String> = { n in Stack(Writer(.right("\(n)"), ["g\(n)"])) }

    @Test func functorLaws() {
        for m in Self.values {
            #expect(m.map(idInt).rawValue == m.rawValue)
            #expect(m.map(incThenDbl).rawValue == m.map(inc).map(dbl).rawValue)
        }
    }

    @Test func applyEqualsAp() {
        for mf in Self.functions {
            for m in Self.values {
                #expect(Stack.apply(mf, m).rawValue == mf.flatMap { f in m.map(f) }.rawValue)
            }
        }
    }

    @Test func monadLaws() {
        for a in [0, 7] {
            #expect(Stack<Int>.pure(a).flatMap(Self.fn).rawValue == Self.fn(a).rawValue)
        }
        for m in Self.values {
            #expect(m.flatMap { Stack<Int>.pure($0) }.rawValue == m.rawValue)
            #expect(m.flatMap(Self.fn).flatMap(Self.gn).rawValue == m.flatMap { Self.fn($0).flatMap(Self.gn) }.rawValue)
        }
    }

    @Test func liftingProperty() {
        let nested = Writer<Log, Either<String, Int>>(.right(1), ["a"])
        #expect(nested.writerT.rawValue == nested)
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(Writer(.right(1), ["a"]))
        #expect(stack.mapExceptT { Writer($0.value, appendLog($0.log)) }.rawValue == Writer(.right(1), ["a", "hatch"]))
    }
}

// MARK: - WriterTOptional (MonadT)

@Suite struct WriterTOptionalLawTests {
    private typealias Stack<A> = WriterTOptional<Log, A>

    private static let values: [Stack<Int>] = [Stack(Writer(.some(1), ["a"])), Stack(Writer(nil, ["a!"]))]
    private static let functions: [Stack<@Sendable (Int) -> Int>] = [Stack(Writer(.some(inc), ["f"])), Stack(Writer(nil, ["f!"]))]
    private static let fn: @Sendable (Int) -> Stack<Int> = { n in Stack(Writer(n > 5 ? nil : n + 1, ["f\(n)"])) }
    private static let gn: @Sendable (Int) -> Stack<String> = { n in Stack(Writer("\(n)", ["g\(n)"])) }

    @Test func functorLaws() {
        for m in Self.values {
            #expect(m.map(idInt).rawValue == m.rawValue)
            #expect(m.map(incThenDbl).rawValue == m.map(inc).map(dbl).rawValue)
        }
    }

    @Test func applyEqualsAp() {
        for mf in Self.functions {
            for m in Self.values {
                #expect(Stack.apply(mf, m).rawValue == mf.flatMap { f in m.map(f) }.rawValue)
            }
        }
    }

    @Test func monadLaws() {
        for a in [0, 7] {
            #expect(Stack<Int>.pure(a).flatMap(Self.fn).rawValue == Self.fn(a).rawValue)
        }
        for m in Self.values {
            #expect(m.flatMap { Stack<Int>.pure($0) }.rawValue == m.rawValue)
            #expect(m.flatMap(Self.fn).flatMap(Self.gn).rawValue == m.flatMap { Self.fn($0).flatMap(Self.gn) }.rawValue)
        }
    }

    @Test func liftingProperty() {
        let nested = Writer<Log, Int?>(.some(1), ["a"])
        #expect(nested.writerT.rawValue == nested)
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(Writer(.some(1), ["a"]))
        #expect(stack.mapMaybeT { Writer($0.value, appendLog($0.log)) }.rawValue == Writer(.some(1), ["a", "hatch"]))
    }
}

// MARK: - WriterTResult (MonadT)

@Suite struct WriterTResultLawTests {
    private typealias Stack<A> = WriterTResult<Log, Boom, A>

    private static let values: [Stack<Int>] = [Stack(Writer(.success(1), ["a"])), Stack(Writer(.failure(.boom), ["a!"]))]
    private static let functions: [Stack<@Sendable (Int) -> Int>] = [
        Stack(Writer(.success(inc), ["f"])),
        Stack(Writer(.failure(.boom), ["f!"]))
    ]
    private static let fn: @Sendable (Int) -> Stack<Int> = { n in Stack(Writer(n > 5 ? .failure(.boom) : .success(n + 1), ["f\(n)"])) }
    private static let gn: @Sendable (Int) -> Stack<String> = { n in Stack(Writer(.success("\(n)"), ["g\(n)"])) }

    @Test func functorLaws() {
        for m in Self.values {
            #expect(m.map(idInt).rawValue == m.rawValue)
            #expect(m.map(incThenDbl).rawValue == m.map(inc).map(dbl).rawValue)
        }
    }

    @Test func applyEqualsAp() {
        for mf in Self.functions {
            for m in Self.values {
                #expect(Stack.apply(mf, m).rawValue == mf.flatMap { f in m.map(f) }.rawValue)
            }
        }
    }

    @Test func monadLaws() {
        for a in [0, 7] {
            #expect(Stack<Int>.pure(a).flatMap(Self.fn).rawValue == Self.fn(a).rawValue)
        }
        for m in Self.values {
            #expect(m.flatMap { Stack<Int>.pure($0) }.rawValue == m.rawValue)
            #expect(m.flatMap(Self.fn).flatMap(Self.gn).rawValue == m.flatMap { Self.fn($0).flatMap(Self.gn) }.rawValue)
        }
    }

    @Test func liftingProperty() {
        let nested = Writer<Log, Result<Int, Boom>>(.success(1), ["a"])
        #expect(nested.writerT.rawValue == nested)
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(Writer(.success(1), ["a"]))
        #expect(stack.mapExceptT { Writer($0.value, appendLog($0.log)) }.rawValue == Writer(.success(1), ["a", "hatch"]))
    }
}

// MARK: - WriterTArray (applicative)

@Suite struct WriterTArrayLawTests {
    private typealias Stack<A> = WriterTArray<Log, A>

    private static let values: [Stack<Int>] = [Stack(Writer([], ["a"])), Stack(Writer([1, 2], ["b"]))]

    @Test func functorLaws() {
        for m in Self.values {
            #expect(m.map(idInt).rawValue == m.rawValue)
            #expect(m.map(incThenDbl).rawValue == m.map(inc).map(dbl).rawValue)
        }
    }

    @Test func applicativeLaws() {
        for m in Self.values {
            #expect(Stack.apply(Stack.pure(idInt), m).rawValue == m.rawValue)
        }
        #expect(Stack.apply(Stack.pure(inc), Stack.pure(3)).rawValue == Stack<Int>.pure(inc(3)).rawValue)
    }

    @Test func liftingProperty() {
        let nested = Writer<Log, [Int]>([1, 2], ["a"])
        #expect(nested.writerT.rawValue == nested)
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(Writer([1], ["a"]))
        #expect(stack.mapWriterT { Writer($0.value, appendLog($0.log)) }.rawValue == Writer([1], ["a", "hatch"]))
    }
}

// MARK: - WriterTNonEmpty (applicative)

@Suite struct WriterTNonEmptyLawTests {
    private typealias Stack<A: Sendable> = WriterTNonEmpty<Log, A>

    private static let values: [Stack<Int>] = [Stack(Writer(NonEmpty(head: 1), ["a"])), Stack(Writer(NonEmpty(head: 1, tail: [2]), ["b"]))]

    @Test func functorLaws() {
        for m in Self.values {
            #expect(m.map(idInt).rawValue == m.rawValue)
            #expect(m.map(incThenDbl).rawValue == m.map(inc).map(dbl).rawValue)
        }
    }

    @Test func applicativeLaws() {
        for m in Self.values {
            #expect(Stack.apply(Stack.pure(idInt), m).rawValue == m.rawValue)
        }
        #expect(Stack.apply(Stack.pure(inc), Stack.pure(3)).rawValue == Stack<Int>.pure(inc(3)).rawValue)
    }

    @Test func liftingProperty() {
        let nested = Writer<Log, NonEmpty<Int>>(NonEmpty(head: 1, tail: [2]), ["a"])
        #expect(nested.writerT.rawValue == nested)
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(Writer(NonEmpty(head: 1), ["a"]))
        #expect(stack.mapWriterT { Writer($0.value, appendLog($0.log)) }.rawValue == Writer(NonEmpty(head: 1), ["a", "hatch"]))
    }
}

// MARK: - WriterTValidation (applicative)

@Suite struct WriterTValidationLawTests {
    private typealias Stack<A> = WriterTValidation<Log, [String], A>

    private static let values: [Stack<Int>] = [Stack(Writer(.success(1), ["a"])), Stack(Writer(.failure(["e"]), ["b"]))]

    @Test func functorLaws() {
        for m in Self.values {
            #expect(m.map(idInt).rawValue == m.rawValue)
            #expect(m.map(incThenDbl).rawValue == m.map(inc).map(dbl).rawValue)
        }
    }

    @Test func applicativeLaws() {
        for m in Self.values {
            #expect(Stack.apply(Stack.pure(idInt), m).rawValue == m.rawValue)
        }
        #expect(Stack.apply(Stack.pure(inc), Stack.pure(3)).rawValue == Stack<Int>.pure(inc(3)).rawValue)
    }

    @Test func liftingProperty() {
        let nested = Writer<Log, Validation<[String], Int>>(.failure(["e"]), ["a"])
        #expect(nested.writerT.rawValue == nested)
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(Writer(.success(1), ["a"]))
        #expect(stack.mapWriterT { Writer($0.value, appendLog($0.log)) }.rawValue == Writer(.success(1), ["a", "hatch"]))
    }
}

// MARK: - WriterTReader (applicative)

@Suite struct WriterTReaderLawTests {
    private typealias Stack<A> = WriterTReader<Log, Int, A>

    private static let values: [Stack<Int>] = [Stack(Writer(Reader { $0 }, ["a"])), Stack(Writer(Reader { $0 * 3 }, ["b"]))]

    private static func observe(_ stack: Stack<Int>) -> [Int] {
        [0, 1, 5].map(stack.rawValue.value.runReader) + [stack.rawValue.log.count]
    }

    @Test func functorLaws() {
        for m in Self.values {
            #expect(Self.observe(m.map(idInt)) == Self.observe(m))
            #expect(Self.observe(m.map(incThenDbl)) == Self.observe(m.map(inc).map(dbl)))
            #expect(m.map(inc).rawValue.log == m.rawValue.log)
        }
    }

    @Test func applicativeLaws() {
        for m in Self.values {
            #expect(Self.observe(Stack.apply(Stack.pure(idInt), m)) == Self.observe(m))
            #expect(Stack.apply(Stack.pure(idInt), m).rawValue.log == m.rawValue.log)
        }
        #expect(Self.observe(Stack.apply(Stack.pure(inc), Stack.pure(3))) == Self.observe(Stack<Int>.pure(inc(3))))
    }

    @Test func liftingProperty() {
        let nested = Writer<Log, Reader<Int, Int>>(Reader { $0 + 1 }, ["a"])
        #expect(nested.writerT.rawValue.value.runReader(1) == 2)
        #expect(nested.writerT.rawValue.log == ["a"])
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(Writer(Reader { $0 }, ["a"]))
        let hatched = stack.mapWriterT { Writer($0.value, appendLog($0.log)) }.rawValue
        #expect(hatched.value.runReader(4) == 4)
        #expect(hatched.log == ["a", "hatch"])
    }
}

// MARK: - WriterTStateful (applicative)

@Suite struct WriterTStatefulLawTests {
    private typealias Stack<A> = WriterTStateful<Log, Int, A>

    private static let tick = Stateful<Int, Int> { state in
        state += 1
        return state * 10
    }

    private static let values: [Stack<Int>] = [Stack(Writer(Stateful<Int, Int>.get, ["a"])), Stack(Writer(tick, ["b"]))]

    private static func observe(_ stack: Stack<Int>) -> [Int] {
        [0, 4].flatMap { initial in
            let (value, state) = stack.rawValue.value.runStateful(initial)
            return [value, state]
        } + [stack.rawValue.log.count]
    }

    @Test func functorLaws() {
        for m in Self.values {
            #expect(Self.observe(m.map(idInt)) == Self.observe(m))
            #expect(Self.observe(m.map(incThenDbl)) == Self.observe(m.map(inc).map(dbl)))
            #expect(m.map(inc).rawValue.log == m.rawValue.log)
        }
    }

    @Test func applicativeLaws() {
        for m in Self.values {
            #expect(Self.observe(Stack.apply(Stack.pure(idInt), m)) == Self.observe(m))
            #expect(Stack.apply(Stack.pure(idInt), m).rawValue.log == m.rawValue.log)
        }
        #expect(Self.observe(Stack.apply(Stack.pure(inc), Stack.pure(3))) == Self.observe(Stack<Int>.pure(inc(3))))
    }

    @Test func liftingProperty() {
        let nested = Writer<Log, Stateful<Int, Int>>(Self.tick, ["a"])
        #expect(nested.writerT.rawValue.value.runStateful(1) == (20, 2))
        #expect(nested.writerT.rawValue.log == ["a"])
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(Writer(Self.tick, ["a"]))
        let hatched = stack.mapWriterT { Writer($0.value, appendLog($0.log)) }.rawValue
        #expect(hatched.value.runStateful(0) == (10, 1))
        #expect(hatched.log == ["a", "hatch"])
    }
}

// MARK: - WriterTAsyncStream (applicative)

@Suite struct WriterTAsyncStreamLawTests {
    private typealias Stack<A: Sendable> = WriterTAsyncStream<Log, A>

    private static func observe<A>(_ stack: WriterTAsyncStream<Log, A>) async -> ([A], Log) {
        await (collectAll(stack.rawValue.value), stack.rawValue.log)
    }

    private static func stack(_ values: [Int], _ log: Log) -> Stack<Int> {
        Stack(Writer(streamOf(values), log))
    }

    @Test func functorLaws() async {
        let identity = await Self.observe(Self.stack([1, 2], ["a"]).map(idInt))
        #expect(identity.0 == [1, 2])
        #expect(identity.1 == ["a"])
        let composed = await Self.observe(Self.stack([1, 2], ["a"]).map(incThenDbl))
        let chained = await Self.observe(Self.stack([1, 2], ["a"]).map(inc).map(dbl))
        #expect(composed.0 == chained.0)
        #expect(composed.1 == chained.1)
    }

    @Test func applicativeLaws() async {
        let identity = await Self.observe(Stack.apply(Stack.pure(idInt), Self.stack([1, 2], ["a"])))
        #expect(identity.0 == [1, 2])
        #expect(identity.1 == ["a"])
        let homomorphism = await Self.observe(Stack.apply(Stack.pure(inc), Stack.pure(3)))
        #expect(homomorphism.0 == [4])
        #expect(homomorphism.1 == [])
    }

    @Test func applyIsCartesianAp() async {
        let fns = Stack<@Sendable (Int) -> Int>(Writer(streamOf([inc, dbl]), ["fns"]))
        let applied = await Self.observe(Stack.apply(fns, Self.stack([10, 20], ["xs"])))
        #expect(applied.0 == [11, 21, 20, 40])
        #expect(applied.1 == ["fns", "xs"])
        let lifted = await Self.observe(Stack.liftA2 { (a: Int, b: Int) in a + b }(Self.stack([1, 2], ["a"]), Self.stack([10, 20], ["b"])))
        #expect(lifted.0 == [11, 21, 12, 22])
        #expect(lifted.1 == ["a", "b"])
        let right = await Self.observe(Self.stack([1, 2], ["a"]).seqRight(Self.stack([10, 20], ["b"])))
        #expect(right.0 == [10, 20, 10, 20])
        let left = await Self.observe(Self.stack([1, 2], ["a"]).seqLeft(Self.stack([10, 20], ["b"])))
        #expect(left.0 == [1, 1, 2, 2])
    }

    @Test func liftingProperty() async {
        let lifted = await Self.observe(Writer<Log, AsyncStream<Int>>(streamOf([1, 2]), ["a"]).writerT)
        #expect(lifted.0 == [1, 2])
        #expect(lifted.1 == ["a"])
    }

    @Test func escapeHatch() async {
        let hatched = await Self.observe(Self.stack([1], ["a"]).mapWriterT { Writer($0.value, appendLog($0.log)) })
        #expect(hatched.0 == [1])
        #expect(hatched.1 == ["a", "hatch"])
    }
}
