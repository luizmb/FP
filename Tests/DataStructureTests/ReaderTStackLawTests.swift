// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Functor, applicative and monad laws for the Reader-outer stacks, on the struct API. Both sides of
// every law run against concrete environments (and inner environments / initial states) and are
// compared observationally. Each suite also checks `apply == ap`, the `mapReaderT` escape hatch and
// the `.readerT` lifting property.

let readerTLawEnvironments = [0, 3, -2]

enum ReaderTLawError: Error, Equatable {
    case boom
    case negative
}

private let increment: @Sendable (Int) -> Int = { $0 + 1 }
private let describe: @Sendable (Int) -> String = { "<\($0)>" }

// MARK: - ReaderTArray

typealias LawRArr<A> = ReaderTArray<Int, A>

private func expectSameArray<A: Equatable>(
    _ lhs: LawRArr<A>,
    _ rhs: LawRArr<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in readerTLawEnvironments {
        #expect(lhs.rawValue(env) == rhs.rawValue(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTArrayLawTests {
    let ms: [LawRArr<Int>] = [
        LawRArr<Int>(Reader { [$0, $0 + 1] }),
        LawRArr<Int>(Reader(const([])))
    ]
    let f: @Sendable (Int) -> LawRArr<Int> = { a in
        LawRArr<Int>(Reader { env in [a, a * env] })
    }

    let g: @Sendable (Int) -> LawRArr<String> = { b in
        LawRArr<String>(Reader { env in ["\(b)", "\(b + env)"] })
    }

    @Test func functorIdentity() {
        for m in ms {
            expectSameArray(m.map(id), m)
        }
    }

    @Test func functorComposition() {
        for m in ms {
            expectSameArray(m.map(increment).map(describe), m.map { describe(increment($0)) })
        }
    }

    @Test func applyEqualsAp() {
        let fs = LawRArr<@Sendable (Int) -> Int>(Reader { env in [{ $0 + env }, { $0 * 2 }] })
        for m in ms {
            expectSameArray(LawRArr<Int>.apply(fs, m), fs.flatMap { fn in m.map(fn) })
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameArray(LawRArr<Int>.pure(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameArray(m.flatMap(LawRArr<Int>.pure), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameArray(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func escapeHatchReachesTheWholeReader() {
        for m in ms {
            let shifted = m.mapReaderT { $0.local(increment) }
            expectSameArray(shifted, LawRArr<Int>(Reader { m.rawValue(increment($0)) }))
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() {
        let nested = Reader<Int, [Int]> { [$0, $0 * 2] }
        expectSameArray(nested.readerT, LawRArr<Int>(nested))
    }
}

// MARK: - ReaderTOptional

typealias LawROpt<A> = ReaderTOptional<Int, A>

private func expectSameOptional<A: Equatable>(
    _ lhs: LawROpt<A>,
    _ rhs: LawROpt<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in readerTLawEnvironments {
        #expect(lhs.rawValue(env) == rhs.rawValue(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTOptionalLawTests {
    let ms: [LawROpt<Int>] = [
        LawROpt<Int>(Reader { $0 }),
        LawROpt<Int>(Reader(const(nil)))
    ]
    let f: @Sendable (Int) -> LawROpt<Int> = { a in
        LawROpt<Int>(Reader { env in env == 0 ? nil : a * env })
    }

    let g: @Sendable (Int) -> LawROpt<String> = { b in
        LawROpt<String>(Reader { env in "\(b + env)" })
    }

    @Test func functorIdentity() {
        for m in ms {
            expectSameOptional(m.map(id), m)
        }
    }

    @Test func functorComposition() {
        for m in ms {
            expectSameOptional(m.map(increment).map(describe), m.map { describe(increment($0)) })
        }
    }

    @Test func applyEqualsAp() {
        let fs = LawROpt<@Sendable (Int) -> Int>(Reader { env in { @Sendable (x: Int) in x + env } })
        for m in ms {
            expectSameOptional(LawROpt<Int>.apply(fs, m), fs.flatMap { fn in m.map(fn) })
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameOptional(LawROpt<Int>.pure(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameOptional(m.flatMap(LawROpt<Int>.pure), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameOptional(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func escapeHatchReachesTheWholeReader() {
        for m in ms {
            let shifted = m.mapReaderT { $0.local(increment) }
            expectSameOptional(shifted, LawROpt<Int>(Reader { m.rawValue(increment($0)) }))
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() {
        let nested = Reader<Int, Int?> { $0 > 0 ? $0 : nil }
        expectSameOptional(nested.readerT, LawROpt<Int>(nested))
    }
}

// MARK: - ReaderTEither

typealias LawREither<A> = ReaderTEither<Int, String, A>

private func expectSameEither<A: Equatable>(
    _ lhs: LawREither<A>,
    _ rhs: LawREither<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in readerTLawEnvironments {
        #expect(lhs.rawValue(env) == rhs.rawValue(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTEitherLawTests {
    let ms: [LawREither<Int>] = [
        LawREither<Int>(Reader { .right($0) }),
        LawREither<Int>(Reader(const(.left("boom"))))
    ]
    let f: @Sendable (Int) -> LawREither<Int> = { a in
        LawREither<Int>(Reader { env in env < 0 ? .left("negative") : .right(a + env) })
    }

    let g: @Sendable (Int) -> LawREither<String> = { b in
        LawREither<String>(Reader { env in .right("\(b * env)") })
    }

    @Test func functorIdentity() {
        for m in ms {
            expectSameEither(m.map(id), m)
        }
    }

    @Test func functorComposition() {
        for m in ms {
            expectSameEither(m.map(increment).map(describe), m.map { describe(increment($0)) })
        }
    }

    @Test func applyEqualsAp() {
        let fs = LawREither<@Sendable (Int) -> Int>(Reader { env in .right { $0 + env } })
        for m in ms {
            expectSameEither(LawREither<Int>.apply(fs, m), fs.flatMap { fn in m.map(fn) })
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameEither(LawREither<Int>.pure(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameEither(m.flatMap(LawREither<Int>.pure), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameEither(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func escapeHatchReachesTheWholeReader() {
        for m in ms {
            let shifted = m.mapReaderT { $0.local(increment) }
            expectSameEither(shifted, LawREither<Int>(Reader { m.rawValue(increment($0)) }))
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() {
        let nested = Reader<Int, Either<String, Int>> { $0 > 0 ? .right($0) : .left("small") }
        expectSameEither(nested.readerT, LawREither<Int>(nested))
    }
}

// MARK: - ReaderTResult

typealias LawRResult<A> = ReaderTResult<Int, ReaderTLawError, A>

private func expectSameResult<A: Equatable>(
    _ lhs: LawRResult<A>,
    _ rhs: LawRResult<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in readerTLawEnvironments {
        #expect(lhs.rawValue(env) == rhs.rawValue(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTResultLawTests {
    let ms: [LawRResult<Int>] = [
        LawRResult<Int>(Reader { .success($0) }),
        LawRResult<Int>(Reader(const(.failure(.boom))))
    ]
    let f: @Sendable (Int) -> LawRResult<Int> = { a in
        LawRResult<Int>(Reader { env in env < 0 ? .failure(.negative) : .success(a + env) })
    }

    let g: @Sendable (Int) -> LawRResult<String> = { b in
        LawRResult<String>(Reader { env in .success("\(b * env)") })
    }

    @Test func functorIdentity() {
        for m in ms {
            expectSameResult(m.map(id), m)
        }
    }

    @Test func functorComposition() {
        for m in ms {
            expectSameResult(m.map(increment).map(describe), m.map { describe(increment($0)) })
        }
    }

    @Test func applyEqualsAp() {
        let fs = LawRResult<@Sendable (Int) -> Int>(Reader { env in .success { $0 + env } })
        for m in ms {
            expectSameResult(LawRResult<Int>.apply(fs, m), fs.flatMap { fn in m.map(fn) })
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameResult(LawRResult<Int>.pure(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameResult(m.flatMap(LawRResult<Int>.pure), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameResult(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func escapeHatchReachesTheWholeReader() {
        for m in ms {
            let shifted = m.mapReaderT { $0.local(increment) }
            expectSameResult(shifted, LawRResult<Int>(Reader { m.rawValue(increment($0)) }))
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() {
        let nested = Reader<Int, Result<Int, ReaderTLawError>> { $0 > 0 ? .success($0) : .failure(.boom) }
        expectSameResult(nested.readerT, LawRResult<Int>(nested))
    }
}

// MARK: - ReaderTNonEmpty

typealias LawRNonEmpty<A> = ReaderTNonEmpty<Int, A>

private func expectSameNonEmpty<A: Equatable & Sendable>(
    _ lhs: LawRNonEmpty<A>,
    _ rhs: LawRNonEmpty<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in readerTLawEnvironments {
        #expect(lhs.rawValue(env) == rhs.rawValue(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTNonEmptyLawTests {
    let ms: [LawRNonEmpty<Int>] = [
        LawRNonEmpty<Int>(Reader { NonEmpty(head: $0, tail: [$0 + 1]) }),
        LawRNonEmpty<Int>(Reader { NonEmpty(head: $0 * 10) })
    ]
    let f: @Sendable (Int) -> LawRNonEmpty<Int> = { a in
        LawRNonEmpty<Int>(Reader { env in NonEmpty(head: a, tail: [a * env]) })
    }

    let g: @Sendable (Int) -> LawRNonEmpty<String> = { b in
        LawRNonEmpty<String>(Reader { env in NonEmpty(head: "\(b)", tail: ["\(b + env)"]) })
    }

    @Test func functorIdentity() {
        for m in ms {
            expectSameNonEmpty(m.map(id), m)
        }
    }

    @Test func functorComposition() {
        for m in ms {
            expectSameNonEmpty(m.map(increment).map(describe), m.map { describe(increment($0)) })
        }
    }

    @Test func applyEqualsAp() {
        let fs = LawRNonEmpty<@Sendable (Int) -> Int>(Reader { env in NonEmpty(head: { $0 + env }, tail: [{ $0 * 2 }]) })
        for m in ms {
            expectSameNonEmpty(LawRNonEmpty<Int>.apply(fs, m), fs.flatMap { fn in m.map(fn) })
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameNonEmpty(LawRNonEmpty<Int>.pure(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameNonEmpty(m.flatMap(LawRNonEmpty<Int>.pure), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameNonEmpty(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func escapeHatchReachesTheWholeReader() {
        for m in ms {
            let shifted = m.mapReaderT { $0.local(increment) }
            expectSameNonEmpty(shifted, LawRNonEmpty<Int>(Reader { m.rawValue(increment($0)) }))
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() {
        let nested = Reader<Int, NonEmpty<Int>> { NonEmpty(head: $0, tail: [$0 * 2]) }
        expectSameNonEmpty(nested.readerT, LawRNonEmpty<Int>(nested))
    }
}

// MARK: - ReaderTReader

typealias LawRReader<A> = ReaderTReader<Int, Int, A>

private func expectSameReader<A: Equatable>(
    _ lhs: LawRReader<A>,
    _ rhs: LawRReader<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in readerTLawEnvironments {
        for inner in readerTLawEnvironments {
            #expect(lhs.rawValue(env)(inner) == rhs.rawValue(env)(inner), sourceLocation: sourceLocation)
        }
    }
}

@Suite struct ReaderTReaderLawTests {
    let ms: [LawRReader<Int>] = [
        LawRReader<Int>(Reader { env in Reader { env * 10 + $0 } }),
        LawRReader<Int>(Reader(const(Reader(const(7)))))
    ]
    let f: @Sendable (Int) -> LawRReader<Int> = { a in
        LawRReader<Int>(Reader { env in Reader { inner in a + env * inner } })
    }

    let g: @Sendable (Int) -> LawRReader<String> = { b in
        LawRReader<String>(Reader { env in Reader { inner in "\(b):\(env):\(inner)" } })
    }

    @Test func functorIdentity() {
        for m in ms {
            expectSameReader(m.map(id), m)
        }
    }

    @Test func functorComposition() {
        for m in ms {
            expectSameReader(m.map(increment).map(describe), m.map { describe(increment($0)) })
        }
    }

    @Test func applyEqualsAp() {
        let fs = LawRReader<@Sendable (Int) -> Int>(Reader { env in Reader { inner in { $0 + env - inner } } })
        for m in ms {
            expectSameReader(LawRReader<Int>.apply(fs, m), fs.flatMap { fn in m.map(fn) })
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameReader(LawRReader<Int>.pure(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameReader(m.flatMap(LawRReader<Int>.pure), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameReader(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func escapeHatchReachesTheWholeReader() {
        for m in ms {
            let shifted = m.mapReaderT { $0.local(increment) }
            expectSameReader(shifted, LawRReader<Int>(Reader { m.rawValue(increment($0)) }))
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() {
        let nested = Reader<Int, Reader<Int, Int>> { env in Reader { env - $0 } }
        expectSameReader(nested.readerT, LawRReader<Int>(nested))
    }
}

// MARK: - ReaderTStateful

typealias LawRStateful<A> = ReaderTStateful<Int, Int, A>

private func expectSameStateful<A: Equatable>(
    _ lhs: LawRStateful<A>,
    _ rhs: LawRStateful<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in readerTLawEnvironments {
        for initial in readerTLawEnvironments {
            let (lhsValue, lhsState) = lhs.rawValue(env).runStateful(initial)
            let (rhsValue, rhsState) = rhs.rawValue(env).runStateful(initial)
            #expect(lhsValue == rhsValue, sourceLocation: sourceLocation)
            #expect(lhsState == rhsState, sourceLocation: sourceLocation)
        }
    }
}

@Suite struct ReaderTStatefulLawTests {
    let ms: [LawRStateful<Int>] = [
        LawRStateful<Int>(Reader { env in
            Stateful { s in
                s += 1
                return env * 10 + s
            }
        }),
        LawRStateful<Int>(Reader { env in Stateful { s in s * env } })
    ]
    let f: @Sendable (Int) -> LawRStateful<Int> = { a in
        LawRStateful<Int>(Reader { env in
            Stateful { s in
                s = s * 2 + env
                return a + s
            }
        })
    }

    let g: @Sendable (Int) -> LawRStateful<String> = { b in
        LawRStateful<String>(Reader { env in
            Stateful { s in
                s -= b
                return "\(b):\(env):\(s)"
            }
        })
    }

    @Test func functorIdentity() {
        for m in ms {
            expectSameStateful(m.map(id), m)
        }
    }

    @Test func functorComposition() {
        for m in ms {
            expectSameStateful(m.map(increment).map(describe), m.map { describe(increment($0)) })
        }
    }

    @Test func applyEqualsAp() {
        let fs = LawRStateful<@Sendable (Int) -> Int>(Reader { env in
            Stateful { s in
                s += 100
                return { $0 * env }
            }
        })
        for m in ms {
            expectSameStateful(LawRStateful<Int>.apply(fs, m), fs.flatMap { fn in m.map(fn) })
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameStateful(LawRStateful<Int>.pure(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameStateful(m.flatMap(LawRStateful<Int>.pure), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameStateful(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func escapeHatchReachesTheWholeReader() {
        for m in ms {
            let shifted = m.mapReaderT { $0.local(increment) }
            expectSameStateful(shifted, LawRStateful<Int>(Reader { m.rawValue(increment($0)) }))
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() {
        let nested = Reader<Int, Stateful<Int, Int>> { env in Stateful { s in s + env } }
        expectSameStateful(nested.readerT, LawRStateful<Int>(nested))
    }
}

// MARK: - ReaderTWriter

typealias LawRWriter<A> = ReaderTWriter<Int, [String], A>

private func expectSameWriter<A: Equatable>(
    _ lhs: LawRWriter<A>,
    _ rhs: LawRWriter<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in readerTLawEnvironments {
        #expect(lhs.rawValue(env) == rhs.rawValue(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTWriterLawTests {
    let ms: [LawRWriter<Int>] = [
        LawRWriter<Int>(Reader { env in Writer(env, ["m"]) }),
        LawRWriter<Int>(Reader { env in Writer(env * 10, []) })
    ]
    let f: @Sendable (Int) -> LawRWriter<Int> = { a in
        LawRWriter<Int>(Reader { env in Writer(a + env, ["f\(a)"]) })
    }

    let g: @Sendable (Int) -> LawRWriter<String> = { b in
        LawRWriter<String>(Reader { env in Writer("\(b * env)", ["g\(b)"]) })
    }

    @Test func functorIdentity() {
        for m in ms {
            expectSameWriter(m.map(id), m)
        }
    }

    @Test func functorComposition() {
        for m in ms {
            expectSameWriter(m.map(increment).map(describe), m.map { describe(increment($0)) })
        }
    }

    @Test func applyEqualsAp() {
        let fs = LawRWriter<@Sendable (Int) -> Int>(Reader { env in Writer({ $0 + env }, ["fn"]) })
        for m in ms {
            expectSameWriter(LawRWriter<Int>.apply(fs, m), fs.flatMap { fn in m.map(fn) })
        }
    }

    @Test func leftIdentity() {
        for a in [0, 1, 7] {
            expectSameWriter(LawRWriter<Int>.pure(a).flatMap(f), f(a))
        }
    }

    @Test func rightIdentity() {
        for m in ms {
            expectSameWriter(m.flatMap(LawRWriter<Int>.pure), m)
        }
    }

    @Test func associativity() {
        let f = f
        let g = g
        for m in ms {
            expectSameWriter(m.flatMap(f).flatMap(g), m.flatMap { a in f(a).flatMap(g) })
        }
    }

    @Test func escapeHatchReachesTheWholeReader() {
        for m in ms {
            let shifted = m.mapReaderT { $0.local(increment) }
            expectSameWriter(shifted, LawRWriter<Int>(Reader { m.rawValue(increment($0)) }))
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() {
        let nested = Reader<Int, Writer<[String], Int>> { Writer($0, ["nested"]) }
        expectSameWriter(nested.readerT, LawRWriter<Int>(nested))
    }
}

// MARK: - ReaderTValidation (applicative only)

typealias LawRValidation<A> = ReaderTValidation<Int, [String], A>

private func expectSameValidation<A: Equatable>(
    _ lhs: LawRValidation<A>,
    _ rhs: LawRValidation<A>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for env in readerTLawEnvironments {
        #expect(lhs.rawValue(env) == rhs.rawValue(env), sourceLocation: sourceLocation)
    }
}

@Suite struct ReaderTValidationLawTests {
    let ms: [LawRValidation<Int>] = [
        LawRValidation<Int>(Reader { .success($0) }),
        LawRValidation<Int>(Reader { .failure(["e\($0)"]) })
    ]

    @Test func functorIdentity() {
        for m in ms {
            expectSameValidation(m.map(id), m)
        }
    }

    @Test func functorComposition() {
        for m in ms {
            expectSameValidation(m.map(increment).map(describe), m.map { describe(increment($0)) })
        }
    }

    @Test func applicativeIdentity() {
        let identity: @Sendable (Int) -> Int = id
        for m in ms {
            expectSameValidation(LawRValidation<Int>.apply(LawRValidation.pure(identity), m), m)
        }
    }

    @Test func applicativeHomomorphism() {
        for x in [0, 4] {
            expectSameValidation(
                LawRValidation<String>.apply(LawRValidation.pure(describe), LawRValidation.pure(x)),
                LawRValidation<String>.pure(describe(x))
            )
        }
    }

    @Test func applyAccumulatesBothFailures() {
        let fs = LawRValidation<@Sendable (Int) -> Int>(Reader { .failure(["fn\($0)"]) })
        let failing = LawRValidation<Int>(Reader { .failure(["arg\($0)"]) })
        #expect(LawRValidation<Int>.apply(fs, failing).rawValue(3) == .failure(["fn3", "arg3"]))
    }

    @Test func escapeHatchReachesTheWholeReader() {
        for m in ms {
            let shifted = m.mapReaderT { $0.local(increment) }
            expectSameValidation(shifted, LawRValidation<Int>(Reader { m.rawValue(increment($0)) }))
        }
    }

    @Test func liftingPropertyWrapsTheNestedValue() {
        let nested = Reader<Int, Validation<[String], Int>> { $0 > 0 ? .success($0) : .failure(["small"]) }
        expectSameValidation(nested.readerT, LawRValidation<Int>(nested))
    }
}
