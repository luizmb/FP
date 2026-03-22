import Testing
@testable import Core

@Suite struct AsyncSequenceTransformerTests {

    // Helper to collect all values from an AsyncStream
    private func collect<A: Sendable>(_ stream: AsyncStream<A>) async -> [A] {
        var results: [A] = []
        for await value in stream {
            results.append(value)
        }
        return results
    }

    private func makeStream<A: Sendable>(_ values: [A]) -> AsyncStream<A> {
        AsyncStream { continuation in
            for v in values { continuation.yield(v) }
            continuation.finish()
        }
    }

    // MARK: - AsyncSequenceTOptional

    @Test func asyncStreamOptionalMapT() async {
        let stream = makeStream([1, nil, 3] as [Int?])
        let result = mapTAsyncStreamOptional({ $0 * 2 }, stream)
        let collected = await collect(result)
        #expect(collected == [2, nil, 6])
    }

    @Test func asyncStreamOptionalLiftA2() async {
        let streamA = makeStream([1, 2] as [Int?])
        let streamB = makeStream([10, 20] as [Int?])
        let result = liftA2AsyncStreamOptional(+)(streamA, streamB)
        let collected = await collect(result)
        #expect(collected == [11, 22])
    }

    @Test func asyncStreamOptionalSeqRight() async {
        let streamA = makeStream([1, nil] as [Int?])
        let streamB = makeStream([10, 20] as [Int?])
        let result = seqRightAsyncStreamOptional(streamA, streamB)
        let collected = await collect(result)
        #expect(collected == [10, nil])
    }

    @Test func asyncStreamOptionalFlatMapT() async {
        let stream = makeStream([1, nil, 2] as [Int?])
        let result = flatMapTAsyncStreamOptional(stream) { n in
            makeStream([n, n * 10] as [Int?])
        }
        let collected = await collect(result)
        #expect(collected == [1, 10, nil, 2, 20])
    }

    // MARK: - AsyncSequenceTArray

    @Test func asyncStreamArrayMapT() async {
        let stream = makeStream([[1, 2], [3, 4]])
        let result = mapTAsyncStreamArray({ $0 * 2 }, stream)
        let collected = await collect(result)
        #expect(collected == [[2, 4], [6, 8]])
    }

    @Test func asyncStreamArrayLiftA2() async {
        let streamA = makeStream([[1, 2]])
        let streamB = makeStream([[10, 20]])
        let result = liftA2AsyncStreamArray(+)(streamA, streamB)
        let collected = await collect(result)
        #expect(collected == [[11, 21, 12, 22]])
    }

    @Test func asyncStreamArrayFlatMapT() async {
        let stream = makeStream([[1, 2]])
        let result = flatMapTAsyncStreamArray(stream) { n in
            makeStream([[n, n * 10]])
        }
        let collected = await collect(result)
        #expect(collected == [[1, 10, 2, 20]])
    }

    // MARK: - AsyncSequenceTResult

    private enum Err: Error, Equatable { case fail }

    @Test func asyncStreamResultMapTSuccess() async {
        let stream = makeStream([Result<Int, Err>.success(5), .failure(.fail)])
        let result = mapTAsyncStreamResult({ $0 * 2 }, stream)
        let collected = await collect(result)
        #expect(collected == [.success(10), .failure(.fail)])
    }

    @Test func asyncStreamResultFlatMapTSuccess() async {
        let stream = makeStream([Result<Int, Err>.success(3), .failure(.fail)])
        let result = flatMapTAsyncStreamResult(stream) { n in
            makeStream([Result<String, Err>.success("\(n)")])
        }
        let collected = await collect(result)
        #expect(collected == [.success("3"), .failure(.fail)])
    }
}
