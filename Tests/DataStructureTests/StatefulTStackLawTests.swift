// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Laws for the Stateful-outer stacks, on the struct API (named functions only, no operators).
// Functor identity / composition for every stack; `apply == ap` plus the monad laws for the MonadT
// stacks (Either, Optional, Result, Writer); applicative identity / homomorphism for the
// applicative-only stacks. Each stack also gets one `mapStateT` (escape hatch) and one
// `.statefulT` (lifting property) test.

private enum StackLawError: Error, Equatable {
    case function
    case value
}

private let initialStates = [0, 3, -2]

/// A `Stateful` that first updates the state, then produces `output`.
private func step<A: Sendable>(_ update: @escaping @Sendable (Int) -> Int, _ output: A) -> Stateful<Int, A> {
    Stateful<Int, A> { s in
        s = update(s)
        return output
    }
}

private func expectSame<A: Equatable>(
    _ actual: Stateful<Int, A>,
    _ expected: Stateful<Int, A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for initial in initialStates {
        let (actualValue, actualState) = actual.runStateful(initial)
        let (expectedValue, expectedState) = expected.runStateful(initial)
        #expect(actualValue == expectedValue, sourceLocation: sourceLocation)
        #expect(actualState == expectedState, sourceLocation: sourceLocation)
    }
}

private let increment: @Sendable (Int) -> Int = { $0 + 1 }
private let describe: @Sendable (Int) -> String = { "<\($0)>" }
private let identity: @Sendable (Int) -> Int = id

// MARK: - StatefulTArray

@Suite struct StatefulTArrayLawTests {
    private typealias Stack<A> = StatefulTArray<Int, A>

    private let values: [Stack<Int>] = [
        Stack(step({ $0 + 1 }, [1, 2])),
        Stack(step({ $0 * 2 }, []))
    ]

    @Test func functorIdentity() {
        for v in values {
            expectSame(v.map(identity).rawValue, v.rawValue)
        }
    }

    @Test func functorComposition() {
        for v in values {
            expectSame(v.map(increment).map(describe).rawValue, v.map { describe(increment($0)) }.rawValue)
        }
    }

    @Test func applicativeIdentity() {
        for v in values {
            expectSame(Stack<Int>.apply(Stack.pure(identity), v).rawValue, v.rawValue)
        }
    }

    @Test func applicativeHomomorphism() {
        expectSame(Stack<String>.apply(Stack.pure(describe), Stack.pure(4)).rawValue, Stack<String>.pure(describe(4)).rawValue)
    }

    @Test func escapeHatch() {
        let stack = Stack(step({ $0 + 1 }, [1, 2]))
        let reversed: Stack<Int> = stack.mapStateT { $0.mapStateful { Array($0.reversed()) } }
        #expect(reversed.rawValue.runStateful(0) == ([2, 1], 1))
    }

    @Test func liftingProperty() {
        let nested = step({ $0 + 1 }, [1, 2])
        expectSame(nested.statefulT.rawValue, nested)
    }
}

// MARK: - StatefulTEither

@Suite struct StatefulTEitherLawTests {
    private typealias Stack<A> = StatefulTEither<Int, String, A>

    private let values: [Stack<Int>] = [
        Stack(step({ $0 * 10 }, .right(10))),
        Stack(step({ $0 - 3 }, .left("a")))
    ]
    private let functions: [Stack<@Sendable (Int) -> Int>] = [
        Stack(step({ $0 * 2 + 1 }, .right { $0 + 100 })),
        Stack(step({ $0 + 5 }, .left("f")))
    ]
    private let f: @Sendable (Int) -> Stack<Int> = { a in Stack(step({ $0 * 3 + a }, .right(a - 1))) }
    private let g: @Sendable (Int) -> Stack<String> = { b in Stack(step({ $0 - b }, b > 5 ? .right("\(b)") : .left("small"))) }

    @Test func functorIdentity() {
        for v in values {
            expectSame(v.map(identity).rawValue, v.rawValue)
        }
    }

    @Test func functorComposition() {
        for v in values {
            expectSame(v.map(increment).map(describe).rawValue, v.map { describe(increment($0)) }.rawValue)
        }
    }

    @Test func applyEqualsAp() {
        for ff in functions {
            for v in values {
                expectSame(Stack<Int>.apply(ff, v).rawValue, ff.flatMap { fn in v.map(fn) }.rawValue)
            }
        }
    }

    @Test func leftIdentity() {
        for a in [0, 4, 9] {
            expectSame(Stack<Int>.pure(a).flatMap(f).rawValue, f(a).rawValue)
        }
    }

    @Test func rightIdentity() {
        for v in values {
            expectSame(v.flatMap(Stack.pure).rawValue, v.rawValue)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for v in values {
            expectSame(v.flatMap(f).flatMap(g).rawValue, v.flatMap { f($0).flatMap(g) }.rawValue)
        }
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(step({ $0 + 1 }, .left("e")))
        let recovered: Stack<Int> = stack.mapStateT { $0.mapStateful { $0.isA ? .right(0) : $0 } }
        #expect(recovered.rawValue.runStateful(0) == (.right(0), 1))
    }

    @Test func liftingProperty() {
        let nested = step({ $0 + 1 }, Either<String, Int>.right(2))
        expectSame(nested.statefulT.rawValue, nested)
    }
}

// MARK: - StatefulTNonEmpty

@Suite struct StatefulTNonEmptyLawTests {
    private typealias Stack<A: Sendable> = StatefulTNonEmpty<Int, A>

    private let values: [Stack<Int>] = [
        Stack(step({ $0 + 1 }, NonEmpty(head: 1, tail: [2]))),
        Stack(step({ $0 * 2 }, NonEmpty(head: 7)))
    ]

    @Test func functorIdentity() {
        for v in values {
            expectSame(v.map(identity).rawValue, v.rawValue)
        }
    }

    @Test func functorComposition() {
        for v in values {
            expectSame(v.map(increment).map(describe).rawValue, v.map { describe(increment($0)) }.rawValue)
        }
    }

    @Test func applicativeIdentity() {
        for v in values {
            expectSame(Stack<Int>.apply(Stack.pure(identity), v).rawValue, v.rawValue)
        }
    }

    @Test func applicativeHomomorphism() {
        expectSame(Stack<String>.apply(Stack.pure(describe), Stack.pure(4)).rawValue, Stack<String>.pure(describe(4)).rawValue)
    }

    @Test func escapeHatch() {
        let stack = Stack(step({ $0 + 1 }, NonEmpty(head: 1, tail: [2])))
        let headOnly: Stack<Int> = stack.mapStateT { $0.mapStateful { NonEmpty(head: $0.head) } }
        #expect(headOnly.rawValue.runStateful(0) == (NonEmpty(head: 1), 1))
    }

    @Test func liftingProperty() {
        let nested = step({ $0 + 1 }, NonEmpty(head: 1, tail: [2]))
        expectSame(nested.statefulT.rawValue, nested)
    }
}

// MARK: - StatefulTOptional

@Suite struct StatefulTOptionalLawTests {
    private typealias Stack<A> = StatefulTOptional<Int, A>

    private let values: [Stack<Int>] = [
        Stack(step({ $0 * 10 }, .some(10))),
        Stack(step({ $0 - 3 }, nil))
    ]
    private let functions: [Stack<@Sendable (Int) -> Int>] = [
        Stack(step({ $0 * 2 + 1 }, .some { $0 + 100 })),
        Stack(step({ $0 + 5 }, nil))
    ]
    private let f: @Sendable (Int) -> Stack<Int> = { a in Stack(step({ $0 * 3 + a }, .some(a - 1))) }
    private let g: @Sendable (Int) -> Stack<String> = { b in Stack(step({ $0 - b }, b > 5 ? .some("\(b)") : nil)) }

    @Test func functorIdentity() {
        for v in values {
            expectSame(v.map(identity).rawValue, v.rawValue)
        }
    }

    @Test func functorComposition() {
        for v in values {
            expectSame(v.map(increment).map(describe).rawValue, v.map { describe(increment($0)) }.rawValue)
        }
    }

    @Test func applyEqualsAp() {
        for ff in functions {
            for v in values {
                expectSame(Stack<Int>.apply(ff, v).rawValue, ff.flatMap { fn in v.map(fn) }.rawValue)
            }
        }
    }

    @Test func leftIdentity() {
        for a in [0, 4, 9] {
            expectSame(Stack<Int>.pure(a).flatMap(f).rawValue, f(a).rawValue)
        }
    }

    @Test func rightIdentity() {
        for v in values {
            expectSame(v.flatMap(Stack.pure).rawValue, v.rawValue)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for v in values {
            expectSame(v.flatMap(f).flatMap(g).rawValue, v.flatMap { f($0).flatMap(g) }.rawValue)
        }
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(step({ $0 + 1 }, nil))
        let defaulted: Stack<Int> = stack.mapStateT { $0.mapStateful { $0 ?? 0 } }
        #expect(defaulted.rawValue.runStateful(0) == (.some(0), 1))
    }

    @Test func liftingProperty() {
        let nested = step({ $0 + 1 }, Int?.some(2))
        expectSame(nested.statefulT.rawValue, nested)
    }
}

// MARK: - StatefulTReader

@Suite struct StatefulTReaderLawTests {
    private typealias Stack<A> = StatefulTReader<Int, Int, A>

    private let environments = [1, 10]
    private let values: [Stack<Int>] = [
        Stack(step({ $0 + 1 }, Reader { $0 * 2 })),
        Stack(step({ $0 * 3 }, Reader(const(7))))
    ]

    /// Compares two stacks by running each with every initial state and every environment.
    private func expectSameReader<A: Equatable & Sendable>(
        _ actual: Stack<A>,
        _ expected: Stack<A>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        for env in environments {
            expectSame(
                actual.rawValue.mapStateful { $0(env) },
                expected.rawValue.mapStateful { $0(env) },
                sourceLocation: sourceLocation
            )
        }
    }

    @Test func functorIdentity() {
        for v in values {
            expectSameReader(v.map(identity), v)
        }
    }

    @Test func functorComposition() {
        for v in values {
            expectSameReader(v.map(increment).map(describe), v.map { describe(increment($0)) })
        }
    }

    @Test func applicativeIdentity() {
        for v in values {
            expectSameReader(Stack<Int>.apply(Stack.pure(identity), v), v)
        }
    }

    @Test func applicativeHomomorphism() {
        expectSameReader(Stack<String>.apply(Stack.pure(describe), Stack.pure(4)), Stack<String>.pure(describe(4)))
    }

    @Test func escapeHatch() {
        let stack = Stack(step({ $0 + 1 }, Reader { $0 * 2 }))
        let localised: Stack<Int> = stack.mapStateT { $0.mapStateful { $0.local { $0 + 100 } } }
        let (reader, state) = localised.rawValue.runStateful(0)
        #expect(reader(1) == 202)
        #expect(state == 1)
    }

    @Test func liftingProperty() {
        let nested = step({ $0 + 1 }, Reader<Int, Int> { $0 * 2 })
        expectSameReader(nested.statefulT, Stack(nested))
    }
}

// MARK: - StatefulTResult

@Suite struct StatefulTResultLawTests {
    private typealias Stack<A> = StatefulTResult<Int, StackLawError, A>

    private let values: [Stack<Int>] = [
        Stack(step({ $0 * 10 }, .success(10))),
        Stack(step({ $0 - 3 }, .failure(.value)))
    ]
    private let functions: [Stack<@Sendable (Int) -> Int>] = [
        Stack(step({ $0 * 2 + 1 }, .success { $0 + 100 })),
        Stack(step({ $0 + 5 }, .failure(.function)))
    ]
    private let f: @Sendable (Int) -> Stack<Int> = { a in Stack(step({ $0 * 3 + a }, .success(a - 1))) }
    private let g: @Sendable (Int) -> Stack<String> = { b in Stack(step({ $0 - b }, b > 5 ? .success("\(b)") : .failure(.value))) }

    @Test func functorIdentity() {
        for v in values {
            expectSame(v.map(identity).rawValue, v.rawValue)
        }
    }

    @Test func functorComposition() {
        for v in values {
            expectSame(v.map(increment).map(describe).rawValue, v.map { describe(increment($0)) }.rawValue)
        }
    }

    @Test func applyEqualsAp() {
        for ff in functions {
            for v in values {
                expectSame(Stack<Int>.apply(ff, v).rawValue, ff.flatMap { fn in v.map(fn) }.rawValue)
            }
        }
    }

    @Test func leftIdentity() {
        for a in [0, 4, 9] {
            expectSame(Stack<Int>.pure(a).flatMap(f).rawValue, f(a).rawValue)
        }
    }

    @Test func rightIdentity() {
        for v in values {
            expectSame(v.flatMap(Stack.pure).rawValue, v.rawValue)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for v in values {
            expectSame(v.flatMap(f).flatMap(g).rawValue, v.flatMap { f($0).flatMap(g) }.rawValue)
        }
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(step({ $0 + 1 }, .failure(.value)))
        let recovered: Stack<Int> = stack.mapStateT { $0.mapStateful(const(Result<Int, StackLawError>.success(0))) }
        #expect(recovered.rawValue.runStateful(0) == (.success(0), 1))
    }

    @Test func liftingProperty() {
        let nested = step({ $0 + 1 }, Result<Int, StackLawError>.success(2))
        expectSame(nested.statefulT.rawValue, nested)
    }
}

// MARK: - StatefulTValidation

@Suite struct StatefulTValidationLawTests {
    private typealias Stack<A> = StatefulTValidation<Int, [String], A>

    private let values: [Stack<Int>] = [
        Stack(step({ $0 + 1 }, .success(1))),
        Stack(step({ $0 * 2 }, .failure(["e"])))
    ]

    @Test func functorIdentity() {
        for v in values {
            expectSame(v.map(identity).rawValue, v.rawValue)
        }
    }

    @Test func functorComposition() {
        for v in values {
            expectSame(v.map(increment).map(describe).rawValue, v.map { describe(increment($0)) }.rawValue)
        }
    }

    @Test func applicativeIdentity() {
        for v in values {
            expectSame(Stack<Int>.apply(Stack.pure(identity), v).rawValue, v.rawValue)
        }
    }

    @Test func applicativeHomomorphism() {
        expectSame(Stack<String>.apply(Stack.pure(describe), Stack.pure(4)).rawValue, Stack<String>.pure(describe(4)).rawValue)
    }

    @Test func escapeHatch() {
        let stack = Stack<Int>(step({ $0 + 1 }, .failure(["e"])))
        let cleared: Stack<Int> = stack.mapStateT { $0.mapStateful(const(Validation<[String], Int>.success(0))) }
        #expect(cleared.rawValue.runStateful(0) == (.success(0), 1))
    }

    @Test func liftingProperty() {
        let nested = step({ $0 + 1 }, Validation<[String], Int>.failure(["e"]))
        expectSame(nested.statefulT.rawValue, nested)
    }
}

// MARK: - StatefulTWriter

@Suite struct StatefulTWriterLawTests {
    private typealias Stack<A> = StatefulTWriter<Int, [String], A>

    private let values: [Stack<Int>] = [
        Stack(step({ $0 * 10 }, Writer(10, ["v"]))),
        Stack(step({ $0 - 3 }, Writer(-1, [])))
    ]
    private let functions: [Stack<@Sendable (Int) -> Int>] = [
        Stack(step({ $0 * 2 + 1 }, Writer<[String], @Sendable (Int) -> Int>({ $0 + 100 }, ["fn"]))),
        Stack(step({ $0 + 5 }, Writer<[String], @Sendable (Int) -> Int>({ $0 * 2 }, [])))
    ]
    private let f: @Sendable (Int) -> Stack<Int> = { a in Stack(step({ $0 * 3 + a }, Writer(a - 1, ["f\(a)"]))) }
    private let g: @Sendable (Int) -> Stack<String> = { b in Stack(step({ $0 - b }, Writer("\(b)", ["g\(b)"]))) }

    @Test func functorIdentity() {
        for v in values {
            expectSame(v.map(identity).rawValue, v.rawValue)
        }
    }

    @Test func functorComposition() {
        for v in values {
            expectSame(v.map(increment).map(describe).rawValue, v.map { describe(increment($0)) }.rawValue)
        }
    }

    @Test func applyEqualsAp() {
        for ff in functions {
            for v in values {
                expectSame(Stack<Int>.apply(ff, v).rawValue, ff.flatMap { fn in v.map(fn) }.rawValue)
            }
        }
    }

    @Test func leftIdentity() {
        for a in [0, 4, 9] {
            expectSame(Stack<Int>.pure(a).flatMap(f).rawValue, f(a).rawValue)
        }
    }

    @Test func rightIdentity() {
        for v in values {
            expectSame(v.flatMap(Stack.pure).rawValue, v.rawValue)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for v in values {
            expectSame(v.flatMap(f).flatMap(g).rawValue, v.flatMap { f($0).flatMap(g) }.rawValue)
        }
    }

    @Test func escapeHatch() {
        let stack = Stack(step({ $0 + 1 }, Writer(1, ["a", "b"])))
        let silenced: Stack<Int> = stack.mapStateT { $0.mapStateful { Writer($0.value, []) } }
        #expect(silenced.rawValue.runStateful(0) == (Writer(1, []), 1))
    }

    @Test func liftingProperty() {
        let nested = step({ $0 + 1 }, Writer(2, ["w"]))
        expectSame(nested.statefulT.rawValue, nested)
    }
}

// MARK: - StatefulTAsyncStream

@Suite struct StatefulTAsyncStreamLawTests {
    private typealias Stack<A> = StatefulTAsyncStream<Int, A>

    /// Rebuilt on every use: an `AsyncStream` is single-pass.
    private func values() -> [Stack<Int>] {
        [
            Stack(Stateful { s in
                s += 1
                return streamOf([1, 2])
            }),
            Stack(Stateful { s in
                s *= 2
                return streamOf([])
            })
        ]
    }

    /// Compares two stacks by running each with every initial state and draining the streams.
    private func expectSameStream<A: Equatable & Sendable>(
        _ actual: Stack<A>,
        _ expected: Stack<A>,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        for initial in initialStates {
            let (actualStream, actualState) = actual.rawValue.runStateful(initial)
            let (expectedStream, expectedState) = expected.rawValue.runStateful(initial)
            let actualValues = await collectAll(actualStream)
            let expectedValues = await collectAll(expectedStream)
            #expect(actualValues == expectedValues, sourceLocation: sourceLocation)
            #expect(actualState == expectedState, sourceLocation: sourceLocation)
        }
    }

    @Test func functorIdentity() async {
        for (v, w) in zip(values(), values()) {
            await expectSameStream(v.map(identity), w)
        }
    }

    @Test func functorComposition() async {
        for (v, w) in zip(values(), values()) {
            await expectSameStream(v.map(increment).map(describe), w.map { describe(increment($0)) })
        }
    }

    @Test func applicativeIdentity() async {
        for (v, w) in zip(values(), values()) {
            await expectSameStream(Stack<Int>.apply(Stack.pure(identity), v), w)
        }
    }

    @Test func applicativeHomomorphism() async {
        await expectSameStream(Stack<String>.apply(Stack.pure(describe), Stack.pure(4)), Stack<String>.pure(describe(4)))
    }

    @Test func applyIsCartesianNotZip() async {
        let functions = Stack<@Sendable (Int) -> String>(Stateful { s in
            s += 1
            return streamOf([{ "f\($0)" }, { "g\($0)" }])
        })
        let arguments = Stack<Int>(Stateful { s in
            s *= 10
            return streamOf([1, 2])
        })
        let (stream, state) = Stack<String>.apply(functions, arguments).rawValue.runStateful(0)
        let streamValues = await collectAll(stream)
        #expect(streamValues == ["f1", "f2", "g1", "g2"])
        #expect(state == 10)
    }

    @Test func liftA2IsCartesianNotZip() async {
        let lhs = Stack<Int>(.pure(streamOf([1, 2])))
        let rhs = Stack<Int>(.pure(streamOf([10, 20])))
        let (stream, _) = Stack<Int>.liftA2 { (a: Int, b: Int) in a + b }(lhs, rhs).rawValue.runStateful(0)
        let streamValues = await collectAll(stream)
        #expect(streamValues == [11, 21, 12, 22])
    }

    @Test func seqRightAndSeqLeftAreCartesian() async {
        let lhs = { Stack<Int>(.pure(streamOf([1, 2]))) }
        let rhs = { Stack<String>(.pure(streamOf(["a", "b"]))) }
        let (right, _) = lhs().seqRight(rhs()).rawValue.runStateful(0)
        let (left, _) = lhs().seqLeft(rhs()).rawValue.runStateful(0)
        let rightValues = await collectAll(right)
        #expect(rightValues == ["a", "b", "a", "b"])
        let leftValues = await collectAll(left)
        #expect(leftValues == [1, 1, 2, 2])
    }

    @Test func escapeHatch() async {
        let stack = Stack<Int>(Stateful { s in
            s += 1
            return streamOf([1, 2, 3])
        })
        let replaced: Stack<Int> = stack.mapStateT { $0.mapStateful(const(streamOf([9]))) }
        let (stream, state) = replaced.rawValue.runStateful(0)
        let streamValues = await collectAll(stream)
        #expect(streamValues == [9])
        #expect(state == 1)
    }

    @Test func liftingProperty() async {
        let nested = Stateful<Int, AsyncStream<Int>> { s in
            s += 1
            return streamOf([1, 2])
        }
        let (stream, state) = nested.statefulT.rawValue.runStateful(0)
        let streamValues = await collectAll(stream)
        #expect(streamValues == [1, 2])
        #expect(state == 1)
    }
}
