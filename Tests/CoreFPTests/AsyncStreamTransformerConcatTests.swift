// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
import Testing

// MaybeT / ExceptT over AsyncStream: bind is ordered concat, and apply/liftA2/seqRight/seqLeft
// are derived from flatMapT + mapT (`<*> == ap`). Named functions only (no operators).

@Suite struct AsyncStreamOptionalConcatTests {
    private let f: @Sendable (Int) -> AsyncStream<Int?> = { x in streamOf([x, nil, x * 10]) }
    private let g: @Sendable (Int) -> AsyncStream<Int?> = { x in streamOf([x + 1, x + 2]) }

    @Test func leftIdentity() async {
        let lhs = await collectAll(flatMapTAsyncStreamOptional(streamOf([Int?.some(3)]), f))
        let rhs = await collectAll(f(3))
        #expect(lhs == rhs)
    }

    @Test func rightIdentity() async {
        let m: [Int?] = [1, nil, 2]
        let result = await collectAll(flatMapTAsyncStreamOptional(streamOf(m)) { x in streamOf([Int?.some(x)]) })
        #expect(result == m)
    }

    @Test func associativity() async {
        let m: [Int?] = [1, nil, 2]
        let lhs = await collectAll(flatMapTAsyncStreamOptional(flatMapTAsyncStreamOptional(streamOf(m), f), g))
        let rhs = await collectAll(flatMapTAsyncStreamOptional(streamOf(m)) { x in flatMapTAsyncStreamOptional(f(x), g) })
        #expect(lhs == rhs)
        #expect(lhs == [2, 3, nil, 11, 12, nil, 3, 4, nil, 21, 22])
    }

    @Test func kleisliMatchesBind() async {
        let composed = await collectAll(kleisliTAsyncStreamOptional(f, g)(1))
        let bound = await collectAll(flatMapTAsyncStreamOptional(f(1), g))
        #expect(composed == bound)
    }

    @Test func applyIsCartesianAndNilShortCircuits() async {
        let fns: [(@Sendable (Int) -> String)?] = [label("f"), nil, label("g")]
        let result = await collectAll(applyAsyncStreamOptional(streamOf(fns), streamOf([1, nil, 2])))
        #expect(result == ["f1", nil, "f2", nil, "g1", nil, "g2"])
    }

    @Test func applyEqualsBindDerivedAp() async {
        let fns: [(@Sendable (Int) -> String)?] = [label("f"), nil, label("g")]
        let xs: [Int?] = [1, nil, 2]
        let applied = await collectAll(applyAsyncStreamOptional(streamOf(fns), streamOf(xs)))
        let derived = await collectAll(flatMapTAsyncStreamOptional(streamOf(fns)) { fn in mapTAsyncStreamOptional(fn, streamOf(xs)) })
        #expect(applied == derived)
    }

    @Test func nilOnTheLeftNeverPullsTheRight() async {
        let log = PullLog()
        let result = await collectAll(seqRightAsyncStreamOptional(streamOf([Int?.none]), loggedStream("r", [Int?.some(1)], log)))
        #expect(result == [nil])
        let observed1 = await log.entries
        #expect(observed1.isEmpty)
    }

    @Test func liftA2SeqRightSeqLeft() async {
        let lifted = await collectAll(liftA2AsyncStreamOptional(+)(streamOf([1, 2] as [Int?]), streamOf([10, 20] as [Int?])))
        let right = await collectAll(seqRightAsyncStreamOptional(streamOf([1, nil] as [Int?]), streamOf([10, 20] as [Int?])))
        let left = await collectAll(seqLeftAsyncStreamOptional(streamOf([1, 2] as [Int?]), streamOf([10, nil] as [Int?])))
        #expect(lifted == [11, 21, 12, 22])
        #expect(right == [10, 20, nil])
        #expect(left == [1, nil, 2, nil])
    }
}

@Suite struct AsyncStreamResultConcatTests {
    private enum Err: Error, Equatable { case boom, bang }

    private let f: @Sendable (Int) -> AsyncStream<Result<Int, Err>> = { x in streamOf([.success(x), .failure(.boom), .success(x * 10)]) }
    private let g: @Sendable (Int) -> AsyncStream<Result<Int, Err>> = { x in streamOf([.success(x + 1), .success(x + 2)]) }

    @Test func leftIdentity() async {
        let lhs = await collectAll(flatMapTAsyncStreamResult(streamOf([Result<Int, Err>.success(3)]), f))
        let rhs = await collectAll(f(3))
        #expect(lhs == rhs)
    }

    @Test func rightIdentity() async {
        let m: [Result<Int, Err>] = [.success(1), .failure(.bang), .success(2)]
        let result = await collectAll(flatMapTAsyncStreamResult(streamOf(m)) { x in streamOf([Result<Int, Err>.success(x)]) })
        #expect(result == m)
    }

    @Test func associativity() async {
        let m: [Result<Int, Err>] = [.success(1), .failure(.bang), .success(2)]
        let lhs = await collectAll(flatMapTAsyncStreamResult(flatMapTAsyncStreamResult(streamOf(m), f), g))
        let rhs = await collectAll(flatMapTAsyncStreamResult(streamOf(m)) { x in flatMapTAsyncStreamResult(f(x), g) })
        #expect(lhs == rhs)
    }

    @Test func kleisliMatchesBind() async {
        let composed = await collectAll(kleisliTAsyncStreamResult(f, g)(1))
        let bound = await collectAll(flatMapTAsyncStreamResult(f(1), g))
        #expect(composed == bound)
    }

    @Test func applyEqualsBindDerivedAp() async {
        let fns: [Result<@Sendable (Int) -> String, Err>] = [.success(label("f")), .failure(.boom), .success(label("g"))]
        let xs: [Result<Int, Err>] = [.success(1), .failure(.bang)]
        let applied = await collectAll(applyAsyncStreamResult(streamOf(fns), streamOf(xs)))
        let derived = await collectAll(flatMapTAsyncStreamResult(streamOf(fns)) { fn in mapTAsyncStreamResult(fn, streamOf(xs)) })
        #expect(applied == derived)
        #expect(applied == [.success("f1"), .failure(.bang), .failure(.boom), .success("g1"), .failure(.bang)])
    }

    @Test func liftA2SeqRightSeqLeft() async {
        let a: [Result<Int, Err>] = [.success(1), .failure(.boom)]
        let b: [Result<Int, Err>] = [.success(10), .success(20)]
        let lifted = await collectAll(liftA2AsyncStreamResult(+)(streamOf(a), streamOf(b)))
        let right = await collectAll(seqRightAsyncStreamResult(streamOf(a), streamOf(b)))
        let left = await collectAll(seqLeftAsyncStreamResult(streamOf(a), streamOf(b)))
        #expect(lifted == [.success(11), .success(21), .failure(.boom)])
        #expect(right == [.success(10), .success(20), .failure(.boom)])
        #expect(left == [.success(1), .success(1), .failure(.boom)])
    }
}

private func label(_ name: String) -> @Sendable (Int) -> String {
    { x in "\(name)\(x)" }
}
