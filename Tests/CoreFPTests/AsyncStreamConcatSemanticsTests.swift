// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

// Haskell stream semantics for AsyncStream: bind is ordered concat, and the applicative is `ap`
// derived from it (cartesian, in order), not zip. Named functions only (no operators).

@Suite struct AsyncStreamConcatSemanticsTests {
    // MARK: - Monad laws (bind = ordered concat)

    @Test func bindLeftIdentity() async throws {
        let f: @Sendable (Int) -> AsyncStream<Int> = { x in streamOf([x, x * 10]) }
        let lhs = try await collectAllThrowing(streamOf([3]).bind(f))
        let rhs = await collectAll(f(3))
        #expect(lhs == rhs)
        #expect(lhs == [3, 30])
    }

    @Test func bindRightIdentity() async throws {
        let result = try await collectAllThrowing(streamOf([1, 2, 3]).bind { x in streamOf([x]) })
        #expect(result == [1, 2, 3])
    }

    @Test func bindAssociativity() async throws {
        let f: @Sendable (Int) -> AsyncStream<Int> = { x in streamOf([x, x + 1]) }
        let g: @Sendable (Int) -> AsyncStream<Int> = { x in streamOf([x * 10, x * 100]) }
        let lhs = try await collectAllThrowing(streamOf([1, 5]).bind(f).bind(g))
        let rhs = try await collectAllThrowing(streamOf([1, 5]).bind { x in f(x).bind(g) })
        #expect(lhs == rhs)
        #expect(lhs == [10, 100, 20, 200, 50, 500, 60, 600])
    }

    @Test func bindIsOrderedAndLosslessWithSlowInnerStreams() async throws {
        // the first inner stream suspends between elements; concat must still finish it first
        let bound = streamOf([1, 2, 3]).bind { x in slowStreamOf([x, x * 10, x * 100], yields: 4 - x) }
        let result = try await collectAllThrowing(bound)
        #expect(result == [1, 10, 100, 2, 20, 200, 3, 30, 300])
    }

    @Test func kleisliIsOrderedConcat() async throws {
        let f: @Sendable (Int) async throws -> AsyncStream<Int> = { x in streamOf([x, x + 1]) }
        let g: @Sendable (Int) async throws -> AsyncStream<String> = { x in streamOf(["\(x)a", "\(x)b"]) }
        let composed = AsyncStream<Int>.kleisli(f, g)
        let result = try await collectAllThrowing(try composed(1))
        #expect(result == ["1a", "1b", "2a", "2b"])
    }

    // MARK: - Applicative = ap (derived from bind)

    @Test func applyIsCartesianInFunctionOrder() async {
        let fns = streamOf([fnLabel("f"), fnLabel("g")])
        let result = await collectAll(AsyncStream<String>.apply(fns, streamOf([1, 2])))
        #expect(result == ["f1", "f2", "g1", "g2"])
    }

    @Test func applyEqualsBindDerivedAp() async throws {
        let fs: [@Sendable (Int) -> Int] = [{ $0 + 1 }, { $0 * 10 }, { $0 - 3 }]
        let xs = [1, 2, 3]
        let applied = await collectAll(AsyncStream<Int>.apply(streamOf(fs), streamOf(xs)))
        // fs >>= \f -> fmap f xs, with a fresh argument stream per function
        let derived = try await collectAllThrowing(streamOf(fs).bind { f in streamOf(xs).map(f) })
        #expect(applied == derived)
        #expect(applied == [2, 3, 4, 10, 20, 30, -2, -1, 0])
    }

    @Test func liftA2EqualsBindDerived() async throws {
        let lifted = await collectAll(AsyncStream<Int>.liftA2 { (a: Int, b: Int) in a * 100 + b }(streamOf([1, 2]), streamOf([3, 4, 5])))
        let derived = try await collectAllThrowing(streamOf([1, 2]).bind { a in streamOf([3, 4, 5]).map { b in a * 100 + b } })
        #expect(lifted == derived)
        #expect(lifted == [103, 104, 105, 203, 204, 205])
    }

    @Test func seqRightRepeatsRightForEachLeft() async {
        let result = await collectAll(AsyncStream<Int>.seqRight(streamOf(["a", "b", "c"]), streamOf([10, 20])))
        #expect(result == [10, 20, 10, 20, 10, 20])
    }

    @Test func seqLeftRepeatsLeftForEachRight() async {
        let result = await collectAll(AsyncStream<String>.seqLeft(streamOf(["a", "b"]), streamOf([1, 2, 3])))
        #expect(result == ["a", "a", "a", "b", "b", "b"])
    }

    @Test func applicativeIdentityLaw() async {
        let identity: @Sendable (Int) -> Int = id
        let result = await collectAll(AsyncStream<Int>.apply(streamOf([identity]), streamOf([4, 5, 6])))
        #expect(result == [4, 5, 6])
    }

    @Test func applyWithEmptySidesIsEmpty() async {
        let noFns: [@Sendable (Int) -> Int] = []
        let emptyLeft = await collectAll(AsyncStream<Int>.apply(streamOf(noFns), streamOf([1, 2])))
        let emptyRight = await collectAll(AsyncStream<Int>.apply(streamOf([fnId]), streamOf([Int]())))
        #expect(emptyLeft.isEmpty)
        #expect(emptyRight.isEmpty)
    }

    @Test func applyNeverPullsArgumentWhenFunctionsAreEmpty() async {
        let log = PullLog()
        let noFns: [@Sendable (Int) -> Int] = []
        let result = await collectAll(AsyncStream<Int>.apply(streamOf(noFns), loggedStream("x", [1, 2], log)))
        #expect(result.isEmpty)
        let observed1 = await log.entries
        #expect(observed1.isEmpty)
    }

    @Test func applyDrainsArgumentStreamOnlyOnce() async {
        let log = PullLog()
        let fns = streamOf([fnLabel("f"), fnLabel("g"), fnLabel("h")])
        let result = await collectAll(AsyncStream<String>.apply(fns, loggedStream("x", [1, 2], log)))
        #expect(result == ["f1", "f2", "g1", "g2", "h1", "h2"])
        let observed2 = await log.entries
        #expect(observed2 == ["x", "x", "x"])
    }

    // MARK: - zip stays pairwise

    @Test func zipPairsPositionallyAndStopsAtShortest() async {
        let result = await collectAll(AsyncStream<Int>.zip(streamOf([1, 2, 3]), streamOf(["a", "b"])))
        #expect(result.map(\.0) == [1, 2])
        #expect(result.map(\.1) == ["a", "b"])
    }

    // MARK: - replayable

    @Test func replayableDrainsOnceAndReplaysInOrder() async {
        let log = PullLog()
        let source = AsyncStream<Int>.replayable(loggedStream("u", [1, 2, 3], log))
        let observed3 = await log.entries
        #expect(observed3.isEmpty)
        let first = await collectAll(source())
        let second = await collectAll(source())
        #expect(first == [1, 2, 3])
        #expect(second == [1, 2, 3])
        let observed4 = await log.entries
        #expect(observed4 == ["u", "u", "u", "u"])
    }

    @Test func replayableSharesTheDrainBetweenConcurrentConsumers() async {
        let log = PullLog()
        let source = AsyncStream<Int>.replayable(loggedStream("u", [1, 2], log))
        async let first = collectAll(source())
        async let second = collectAll(source())
        let results = await [first, second]
        #expect(results == [[1, 2], [1, 2]])
        let observed5 = await log.entries
        #expect(observed5 == ["u", "u", "u"])
    }
}

private let fnId: @Sendable (Int) -> Int = id

private func fnLabel(_ label: String) -> @Sendable (Int) -> String {
    { x in "\(label)\(x)" }
}
