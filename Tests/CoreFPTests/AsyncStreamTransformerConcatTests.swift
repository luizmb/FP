// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

// MaybeT / ExceptT over AsyncStream: bind is ordered concat, and apply/liftA2/seqRight/seqLeft
// are derived from flatMap + map (`<*> == ap`). Named functions only (no operators).

@Suite struct AsyncStreamOptionalConcatTests {
    private let f: @Sendable (Int) -> AsyncStreamTOptional<Int> = { x in streamOf([x, nil, x * 10]).asyncStreamT }
    private let g: @Sendable (Int) -> AsyncStreamTOptional<Int> = { x in streamOf([x + 1, x + 2] as [Int?]).asyncStreamT }

    @Test func leftIdentity() async {
        let lhs = await collectAll(AsyncStreamTOptional.pure(3).flatMap(f).rawValue)
        let rhs = await collectAll(f(3).rawValue)
        #expect(lhs == rhs)
    }

    @Test func rightIdentity() async {
        let m: [Int?] = [1, nil, 2]
        let result = await collectAll(streamOf(m).asyncStreamT.flatMap(AsyncStreamTOptional.pure).rawValue)
        #expect(result == m)
    }

    @Test func associativity() async {
        let m: [Int?] = [1, nil, 2]
        let lhs = await collectAll(streamOf(m).asyncStreamT.flatMap(f).flatMap(g).rawValue)
        let rhs = await collectAll(streamOf(m).asyncStreamT.flatMap { x in f(x).flatMap(g) }.rawValue)
        #expect(lhs == rhs)
        #expect(lhs == [2, 3, nil, 11, 12, nil, 3, 4, nil, 21, 22])
    }

    @Test func kleisliMatchesBind() async {
        let composed = await collectAll(AsyncStreamTOptional<Int>.kleisli(f, g)(1).rawValue)
        let bound = await collectAll(f(1).flatMap(g).rawValue)
        #expect(composed == bound)
    }

    @Test func applyIsCartesianAndNilShortCircuits() async {
        let fns: [(@Sendable (Int) -> String)?] = [label("f"), nil, label("g")]
        let result = await collectAll(AsyncStreamTOptional.apply(streamOf(fns).asyncStreamT, streamOf([1, nil, 2]).asyncStreamT).rawValue)
        #expect(result == ["f1", nil, "f2", nil, "g1", nil, "g2"])
    }

    @Test func applyEqualsBindDerivedAp() async {
        let fns: [(@Sendable (Int) -> String)?] = [label("f"), nil, label("g")]
        let xs: [Int?] = [1, nil, 2]
        let applied = await collectAll(AsyncStreamTOptional.apply(streamOf(fns).asyncStreamT, streamOf(xs).asyncStreamT).rawValue)
        let derived = await collectAll(streamOf(fns).asyncStreamT.flatMap { fn in streamOf(xs).asyncStreamT.map(fn) }.rawValue)
        #expect(applied == derived)
    }

    @Test func nilOnTheLeftNeverPullsTheRight() async {
        let log = PullLog()
        let lhs = streamOf([Int?.none]).asyncStreamT
        let result = await collectAll(lhs.seqRight(loggedStream("r", [Int?.some(1)], log).asyncStreamT).rawValue)
        #expect(result == [nil])
        let observed1 = await log.entries
        #expect(observed1.isEmpty)
    }

    @Test func liftA2SeqRightSeqLeft() async {
        let lifted = await collectAll(
            AsyncStreamTOptional<Int>.liftA2(+)(streamOf([1, 2] as [Int?]).asyncStreamT, streamOf([10, 20] as [Int?]).asyncStreamT).rawValue
        )
        let right = await collectAll(streamOf([1, nil] as [Int?]).asyncStreamT.seqRight(streamOf([10, 20] as [Int?]).asyncStreamT).rawValue)
        let left = await collectAll(streamOf([1, 2] as [Int?]).asyncStreamT.seqLeft(streamOf([10, nil] as [Int?]).asyncStreamT).rawValue)
        #expect(lifted == [11, 21, 12, 22])
        #expect(right == [10, 20, nil])
        #expect(left == [1, nil, 2, nil])
    }
}

@Suite struct AsyncStreamResultConcatTests {
    private enum Err: Error, Equatable { case boom, bang }

    private let f: @Sendable (Int) -> AsyncStreamTResult<Err, Int> = { x in
        AsyncStreamTResult(streamOf([.success(x), .failure(.boom), .success(x * 10)]))
    }

    private let g: @Sendable (Int) -> AsyncStreamTResult<Err, Int> = { x in
        AsyncStreamTResult(streamOf([.success(x + 1), .success(x + 2)]))
    }

    @Test func leftIdentity() async {
        let lhs = await collectAll(AsyncStreamTResult<Err, Int>.pure(3).flatMap(f).rawValue)
        let rhs = await collectAll(f(3).rawValue)
        #expect(lhs == rhs)
    }

    @Test func rightIdentity() async {
        let m: [Result<Int, Err>] = [.success(1), .failure(.bang), .success(2)]
        let result = await collectAll(streamOf(m).asyncStreamT.flatMap(AsyncStreamTResult.pure).rawValue)
        #expect(result == m)
    }

    @Test func associativity() async {
        let m: [Result<Int, Err>] = [.success(1), .failure(.bang), .success(2)]
        let lhs = await collectAll(streamOf(m).asyncStreamT.flatMap(f).flatMap(g).rawValue)
        let rhs = await collectAll(streamOf(m).asyncStreamT.flatMap { x in f(x).flatMap(g) }.rawValue)
        #expect(lhs == rhs)
    }

    @Test func kleisliMatchesBind() async {
        let composed = await collectAll(AsyncStreamTResult<Err, Int>.kleisli(f, g)(1).rawValue)
        let bound = await collectAll(f(1).flatMap(g).rawValue)
        #expect(composed == bound)
    }

    @Test func applyEqualsBindDerivedAp() async {
        let fns: [Result<@Sendable (Int) -> String, Err>] = [.success(label("f")), .failure(.boom), .success(label("g"))]
        let xs: [Result<Int, Err>] = [.success(1), .failure(.bang)]
        let applied = await collectAll(AsyncStreamTResult.apply(streamOf(fns).asyncStreamT, streamOf(xs).asyncStreamT).rawValue)
        let derived = await collectAll(streamOf(fns).asyncStreamT.flatMap { fn in streamOf(xs).asyncStreamT.map(fn) }.rawValue)
        #expect(applied == derived)
        #expect(applied == [.success("f1"), .failure(.bang), .failure(.boom), .success("g1"), .failure(.bang)])
    }

    @Test func liftA2SeqRightSeqLeft() async {
        let a: [Result<Int, Err>] = [.success(1), .failure(.boom)]
        let b: [Result<Int, Err>] = [.success(10), .success(20)]
        let lifted = await collectAll(AsyncStreamTResult<Err, Int>.liftA2(+)(streamOf(a).asyncStreamT, streamOf(b).asyncStreamT).rawValue)
        let right = await collectAll(streamOf(a).asyncStreamT.seqRight(streamOf(b).asyncStreamT).rawValue)
        let left = await collectAll(streamOf(a).asyncStreamT.seqLeft(streamOf(b).asyncStreamT).rawValue)
        #expect(lifted == [.success(11), .success(21), .failure(.boom)])
        #expect(right == [.success(10), .success(20), .failure(.boom)])
        #expect(left == [.success(1), .success(1), .failure(.boom)])
    }
}

private func label(_ name: String) -> @Sendable (Int) -> String {
    { x in "\(name)\(x)" }
}
