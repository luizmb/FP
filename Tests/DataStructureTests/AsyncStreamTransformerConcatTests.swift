// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// ExceptT / WriterT / ReaderT over AsyncStream: bind is ordered concat, and the applicative
// is `ap` derived from it. Named functions only (no operators).

@Suite struct AsyncStreamEitherConcatTests {
    private typealias Stack = AsyncStreamTEither<String, Int>

    private let f: @Sendable (Int) -> AsyncStreamTEither<String, Int> = { x in
        AsyncStreamTEither(streamOf([.right(x), .left("e\(x)"), .right(x * 10)]))
    }

    private let g: @Sendable (Int) -> AsyncStreamTEither<String, Int> = { x in
        AsyncStreamTEither(streamOf([.right(x + 1), .right(x + 2)]))
    }

    @Test func leftIdentity() async {
        let lhs = await collectAll(Stack.pure(3).flatMap(f).rawValue)
        let rhs = await collectAll(f(3).rawValue)
        #expect(lhs == rhs)
    }

    @Test func rightIdentity() async {
        let m: [Either<String, Int>] = [.right(1), .left("x"), .right(2)]
        let result = await collectAll(streamOf(m).asyncStreamT.flatMap(Stack.pure).rawValue)
        #expect(result == m)
    }

    @Test func associativity() async {
        let m: [Either<String, Int>] = [.right(1), .left("x"), .right(2)]
        let f = f
        let g = g
        let lhs = await collectAll(streamOf(m).asyncStreamT.flatMap(f).flatMap(g).rawValue)
        let rhs = await collectAll(streamOf(m).asyncStreamT.flatMap { x in f(x).flatMap(g) }.rawValue)
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
        let composed = await collectAll(Stack.kleisli(f, g)(1).rawValue)
        let bound = await collectAll(f(1).flatMap(g).rawValue)
        #expect(composed == bound)
    }

    @Test func applyIsCartesianAndLeftShortCircuits() async {
        let fns: [Either<String, @Sendable (Int) -> String>] = [.right(label("f")), .left("no"), .right(label("g"))]
        let xs: [Either<String, Int>] = [.right(1), .left("bad"), .right(2)]
        let applied = await collectAll(AsyncStreamTEither.apply(streamOf(fns).asyncStreamT, streamOf(xs).asyncStreamT).rawValue)
        let derived = await collectAll(streamOf(fns).asyncStreamT.flatMap { fn in streamOf(xs).asyncStreamT.map(fn) }.rawValue)
        #expect(applied == derived)
        #expect(applied == [.right("f1"), .left("bad"), .right("f2"), .left("no"), .right("g1"), .left("bad"), .right("g2")])
    }

    @Test func leftOnTheLeftNeverPullsTheRight() async {
        let log = PullLog()
        let rhs = loggedStream("r", [Either<String, Int>.right(1)], log)
        let result = await collectAll(streamOf([Either<String, Int>.left("stop")]).asyncStreamT.seqLeft(rhs.asyncStreamT).rawValue)
        #expect(result == [.left("stop")])
        let observed1 = await log.entries
        #expect(observed1.isEmpty)
    }

    @Test func liftA2SeqRightSeqLeft() async {
        let a: [Either<String, Int>] = [.right(1), .left("x")]
        let b: [Either<String, Int>] = [.right(10), .right(20)]
        let lifted = await collectAll(Stack.liftA2(+)(streamOf(a).asyncStreamT, streamOf(b).asyncStreamT).rawValue)
        let right = await collectAll(streamOf(a).asyncStreamT.seqRight(streamOf(b).asyncStreamT).rawValue)
        let left = await collectAll(streamOf(a).asyncStreamT.seqLeft(streamOf(b).asyncStreamT).rawValue)
        #expect(lifted == [.right(11), .right(21), .left("x")])
        #expect(right == [.right(10), .right(20), .left("x")])
        #expect(left == [.right(1), .right(1), .left("x")])
    }
}

@Suite struct AsyncStreamWriterConcatTests {
    private typealias Stack = AsyncStreamTWriter<[String], Int>

    private let f: @Sendable (Int) -> AsyncStreamTWriter<[String], Int> = { x in
        AsyncStreamTWriter(streamOf([Writer(x, ["f\(x)a"]), Writer(x * 10, ["f\(x)b"])]))
    }

    private let g: @Sendable (Int) -> AsyncStreamTWriter<[String], Int> = { x in AsyncStreamTWriter(streamOf([Writer(x + 1, ["g\(x)"])])) }

    @Test func bindConcatsAndCombinesLogs() async {
        let m = streamOf([Writer(1, ["m1"]), Writer(2, ["m2"])])
        let result = await collectAll(m.asyncStreamT.flatMap(f).rawValue)
        #expect(result == [
            Writer(1, ["m1", "f1a"]), Writer(10, ["m1", "f1b"]),
            Writer(2, ["m2", "f2a"]), Writer(20, ["m2", "f2b"])
        ])
    }

    @Test func leftIdentity() async {
        let lhs = await collectAll(Stack.pure(3).flatMap(f).rawValue)
        let rhs = await collectAll(f(3).rawValue)
        #expect(lhs == rhs)
    }

    @Test func rightIdentity() async {
        let m = [Writer(1, ["a"]), Writer(2, ["b"])]
        let result = await collectAll(streamOf(m).asyncStreamT.flatMap(Stack.pure).rawValue)
        #expect(result == m)
    }

    @Test func associativity() async {
        let m = [Writer(1, ["a"]), Writer(2, ["b"])]
        let f = f
        let g = g
        let lhs = await collectAll(streamOf(m).asyncStreamT.flatMap(f).flatMap(g).rawValue)
        let rhs = await collectAll(streamOf(m).asyncStreamT.flatMap { x in f(x).flatMap(g) }.rawValue)
        #expect(lhs == rhs)
    }

    @Test func bindAndKleisliMatchFlatMap() async {
        let viaBind = await collectAll(Stack.bind(g)(f(1)).rawValue)
        let viaKleisli = await collectAll(Stack.kleisli(f, g)(1).rawValue)
        let viaFlatMap = await collectAll(f(1).flatMap(g).rawValue)
        #expect(viaBind == viaFlatMap)
        #expect(viaKleisli == viaFlatMap)
    }

    @Test func applyEqualsBindDerivedAp() async {
        let fns = [Writer<[String], @Sendable (Int) -> String>(label("f"), ["F"]), Writer(label("g"), ["G"])]
        let xs = [Writer(1, ["x1"]), Writer(2, ["x2"])]
        let applied = await collectAll(AsyncStreamTWriter.apply(streamOf(fns).asyncStreamT, streamOf(xs).asyncStreamT).rawValue)
        let derived = await collectAll(streamOf(fns).asyncStreamT.flatMap { fn in
            streamOf(xs).asyncStreamT.flatMap { x in AsyncStreamTWriter<[String], String>.pure(fn(x)) }
        }.rawValue)
        #expect(applied == derived)
        #expect(applied == [
            Writer("f1", ["F", "x1"]), Writer("f2", ["F", "x2"]),
            Writer("g1", ["G", "x1"]), Writer("g2", ["G", "x2"])
        ])
    }

    @Test func seqRightAndSeqLeftKeepBothLogsLeftFirst() async {
        let a = [Writer("a", ["la"]), Writer("b", ["lb"])]
        let b = [Writer(1, ["r1"])]
        let right = await collectAll(streamOf(a).asyncStreamT.seqRight(streamOf(b).asyncStreamT).rawValue)
        let left = await collectAll(streamOf(a).asyncStreamT.seqLeft(streamOf(b).asyncStreamT).rawValue)
        #expect(right == [Writer(1, ["la", "r1"]), Writer(1, ["lb", "r1"])])
        #expect(left == [Writer("a", ["la", "r1"]), Writer("b", ["lb", "r1"])])
    }
}

@Suite struct ReaderTAsyncStreamConcatTests {
    @Test func liftA2IsBindDerivedUnderTheSameEnvironment() async {
        let readerA = Reader<Int, AsyncStream<Int>> { env in streamOf([env, env * 2]) }
        let readerB = Reader<Int, AsyncStream<Int>> { env in streamOf([env * 100, env * 1_000]) }
        let combine = ReaderTAsyncStream<Int, Int>.liftA2 { (a: Int, b: Int) in a + b }
        let combined = await collectAll(combine(readerA.readerT, readerB.readerT).rawValue(1))
        #expect(combined == [101, 1_001, 102, 1_002])
    }

    @Test func seqRightAndSeqLeft() async {
        let readerA = Reader<Int, AsyncStream<String>> { env in streamOf(["a\(env)", "b\(env)"]) }
        let readerB = Reader<Int, AsyncStream<Int>> { env in streamOf([env, env + 1]) }
        let right = await collectAll(readerA.readerT.seqRight(readerB.readerT).rawValue(5))
        let left = await collectAll(readerA.readerT.seqLeft(readerB.readerT).rawValue(5))
        #expect(right == [5, 6, 5, 6])
        #expect(left == ["a5", "a5", "b5", "b5"])
    }

    @Test func flatMapIsOrderedConcat() async {
        let reader = Reader<Int, AsyncStream<Int>>(const(streamOf([1, 2])))
        let bound = reader.readerT.flatMap { x in ReaderTAsyncStream(Reader<Int, AsyncStream<Int>> { env in streamOf([x, x * env]) }) }
        let result = await collectAll(bound.rawValue(10))
        #expect(result == [1, 10, 2, 20])
    }
}

private func label(_ name: String) -> @Sendable (Int) -> String {
    { x in "\(name)\(x)" }
}
