// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// ExceptT / WriterT / ReaderT over AsyncStream: bind is ordered concat, and the applicative
// is `ap` derived from it. Named functions only (no operators).

@Suite struct AsyncStreamEitherConcatTests {
    private let f: @Sendable (Int) -> AsyncStream<Either<String, Int>> = { x in streamOf([.right(x), .left("e\(x)"), .right(x * 10)]) }
    private let g: @Sendable (Int) -> AsyncStream<Either<String, Int>> = { x in streamOf([.right(x + 1), .right(x + 2)]) }

    @Test func leftIdentity() async {
        let lhs = await collectAll(flatMapTAsyncStreamEither(streamOf([Either<String, Int>.right(3)]), f))
        let rhs = await collectAll(f(3))
        #expect(lhs == rhs)
    }

    @Test func rightIdentity() async {
        let m: [Either<String, Int>] = [.right(1), .left("x"), .right(2)]
        let result = await collectAll(flatMapTAsyncStreamEither(streamOf(m)) { x in streamOf([Either<String, Int>.right(x)]) })
        #expect(result == m)
    }

    @Test func associativity() async {
        let m: [Either<String, Int>] = [.right(1), .left("x"), .right(2)]
        let lhs = await collectAll(flatMapTAsyncStreamEither(flatMapTAsyncStreamEither(streamOf(m), f), g))
        let rhs = await collectAll(flatMapTAsyncStreamEither(streamOf(m)) { x in flatMapTAsyncStreamEither(f(x), g) })
        #expect(lhs == rhs)
        #expect(lhs == [
            .right(2),
            .right(3),
            .left("e1"),
            .right(11),
            .right(12),
            .left("x"),
            .right(3),
            .right(4),
            .left("e2"),
            .right(21),
            .right(22)
        ])
    }

    @Test func kleisliMatchesBind() async {
        let composed = await collectAll(kleisliTAsyncStreamEither(f, g)(1))
        let bound = await collectAll(flatMapTAsyncStreamEither(f(1), g))
        #expect(composed == bound)
    }

    @Test func applyIsCartesianAndLeftShortCircuits() async {
        let fns: [Either<String, @Sendable (Int) -> String>] = [.right(label("f")), .left("no"), .right(label("g"))]
        let xs: [Either<String, Int>] = [.right(1), .left("bad"), .right(2)]
        let applied = await collectAll(applyAsyncStreamEither(streamOf(fns), streamOf(xs)))
        let derived = await collectAll(flatMapTAsyncStreamEither(streamOf(fns)) { fn in mapTAsyncStreamEither(fn, streamOf(xs)) })
        #expect(applied == derived)
        #expect(applied == [.right("f1"), .left("bad"), .right("f2"), .left("no"), .right("g1"), .left("bad"), .right("g2")])
    }

    @Test func leftOnTheLeftNeverPullsTheRight() async {
        let log = PullLog()
        let rhs = loggedStream("r", [Either<String, Int>.right(1)], log)
        let result = await collectAll(seqLeftAsyncStreamEither(streamOf([Either<String, Int>.left("stop")]), rhs))
        #expect(result == [.left("stop")])
        let observed1 = await log.entries
        #expect(observed1.isEmpty)
    }

    @Test func liftA2SeqRightSeqLeft() async {
        let a: [Either<String, Int>] = [.right(1), .left("x")]
        let b: [Either<String, Int>] = [.right(10), .right(20)]
        let lifted = await collectAll(liftA2AsyncStreamEither(+)(streamOf(a), streamOf(b)))
        let right = await collectAll(seqRightAsyncStreamEither(streamOf(a), streamOf(b)))
        let left = await collectAll(seqLeftAsyncStreamEither(streamOf(a), streamOf(b)))
        #expect(lifted == [.right(11), .right(21), .left("x")])
        #expect(right == [.right(10), .right(20), .left("x")])
        #expect(left == [.right(1), .right(1), .left("x")])
    }
}

@Suite struct AsyncStreamWriterConcatTests {
    private let f: @Sendable (Int) -> AsyncStream<Writer<[String], Int>> = { x in
        streamOf([Writer(x, ["f\(x)a"]), Writer(x * 10, ["f\(x)b"])])
    }

    private let g: @Sendable (Int) -> AsyncStream<Writer<[String], Int>> = { x in streamOf([Writer(x + 1, ["g\(x)"])]) }

    private func pure(_ x: Int) -> AsyncStream<Writer<[String], Int>> { streamOf([Writer.pure(x)]) }

    @Test func bindConcatsAndCombinesLogs() async {
        let m = streamOf([Writer(1, ["m1"]), Writer(2, ["m2"])])
        let result = await collectAll(m.flatMapT(f))
        #expect(result == [
            Writer(1, ["m1", "f1a"]), Writer(10, ["m1", "f1b"]),
            Writer(2, ["m2", "f2a"]), Writer(20, ["m2", "f2b"])
        ])
    }

    @Test func leftIdentity() async {
        let lhs = await collectAll(pure(3).flatMapT(f))
        let rhs = await collectAll(f(3))
        #expect(lhs == rhs)
    }

    @Test func rightIdentity() async {
        let m = [Writer(1, ["a"]), Writer(2, ["b"])]
        let result = await collectAll(streamOf(m).flatMapT { x in streamOf([Writer<[String], Int>.pure(x)]) })
        #expect(result == m)
    }

    @Test func associativity() async {
        let m = [Writer(1, ["a"]), Writer(2, ["b"])]
        let lhs = await collectAll(streamOf(m).flatMapT(f).flatMapT(g))
        let rhs = await collectAll(streamOf(m).flatMapT { x in f(x).flatMapT(g) })
        #expect(lhs == rhs)
    }

    @Test func bindTAndKleisliMatchBind() async {
        let viaBindT = await collectAll(AsyncStream<Writer<[String], Int>>.bindT(g)(f(1)))
        let viaKleisli = await collectAll(kleisliT(f, g)(1))
        let viaBind = await collectAll(f(1).flatMapT(g))
        #expect(viaBindT == viaBind)
        #expect(viaKleisli == viaBind)
    }

    @Test func applyEqualsBindDerivedAp() async {
        let fns = [Writer<[String], @Sendable (Int) -> String>(label("f"), ["F"]), Writer(label("g"), ["G"])]
        let xs = [Writer(1, ["x1"]), Writer(2, ["x2"])]
        let applied = await collectAll(applyAsyncStreamWriter(streamOf(fns), streamOf(xs)))
        let derived = await collectAll(streamOf(fns).flatMapT { fn in
            streamOf(xs).flatMapT { x in streamOf([Writer<[String], String>.pure(fn(x))]) }
        })
        #expect(applied == derived)
        #expect(applied == [
            Writer("f1", ["F", "x1"]), Writer("f2", ["F", "x2"]),
            Writer("g1", ["G", "x1"]), Writer("g2", ["G", "x2"])
        ])
    }

    @Test func seqRightAndSeqLeftKeepBothLogsLeftFirst() async {
        let a = [Writer("a", ["la"]), Writer("b", ["lb"])]
        let b = [Writer(1, ["r1"])]
        let right = await collectAll(seqRightAsyncStreamWriter(streamOf(a), streamOf(b)))
        let left = await collectAll(seqLeftAsyncStreamWriter(streamOf(a), streamOf(b)))
        #expect(right == [Writer(1, ["la", "r1"]), Writer(1, ["lb", "r1"])])
        #expect(left == [Writer("a", ["la", "r1"]), Writer("b", ["lb", "r1"])])
    }
}

@Suite struct ReaderTAsyncStreamConcatTests {
    @Test func liftA2IsBindDerivedUnderTheSameEnvironment() async {
        let readerA = Reader<Int, AsyncStream<Int>> { env in streamOf([env, env * 2]) }
        let readerB = Reader<Int, AsyncStream<Int>> { env in streamOf([env * 100, env * 1_000]) }
        let combined = await collectAll(liftA2ReaderAsyncStream { (a: Int, b: Int) in a + b }(readerA, readerB)(1))
        #expect(combined == [101, 1_001, 102, 1_002])
    }

    @Test func seqRightAndSeqLeft() async {
        let readerA = Reader<Int, AsyncStream<String>> { env in streamOf(["a\(env)", "b\(env)"]) }
        let readerB = Reader<Int, AsyncStream<Int>> { env in streamOf([env, env + 1]) }
        let right = await collectAll(seqRightReaderAsyncStream(readerA, readerB)(5))
        let left = await collectAll(seqLeftReaderAsyncStream(readerA, readerB)(5))
        #expect(right == [5, 6, 5, 6])
        #expect(left == ["a5", "a5", "b5", "b5"])
    }

    @Test func flatMapTIsOrderedConcat() async throws {
        let reader = Reader<Int, AsyncStream<Int>>(const(streamOf([1, 2])))
        let bound = reader.flatMapT { x in Reader<Int, AsyncStream<Int>> { env in streamOf([x, x * env]) } }
        let result = try await collectAllThrowing(bound(10))
        #expect(result == [1, 10, 2, 20])
    }
}

private func label(_ name: String) -> @Sendable (Int) -> String {
    { x in "\(name)\(x)" }
}
