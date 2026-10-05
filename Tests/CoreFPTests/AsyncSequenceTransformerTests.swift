// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

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
            for v in values {
                continuation.yield(v)
            }
            continuation.finish()
        }
    }

    // MARK: - AsyncStreamTOptional

    @Test func asyncStreamOptionalMap() async {
        let stream = makeStream([1, nil, 3] as [Int?])
        let result = stream.asyncStreamT.map { $0 * 2 }
        let collected = await collect(result.rawValue)
        #expect(collected == [2, nil, 6])
    }

    @Test func asyncStreamOptionalLiftA2() async {
        let streamA = makeStream([1, 2] as [Int?])
        let streamB = makeStream([10, 20] as [Int?])
        let result = AsyncStreamTOptional<Int>.liftA2(+)(streamA.asyncStreamT, streamB.asyncStreamT)
        let collected = await collect(result.rawValue)
        #expect(collected == [11, 21, 12, 22])
    }

    @Test func asyncStreamOptionalSeqRight() async {
        let streamA = makeStream([1, nil] as [Int?])
        let streamB = makeStream([10, 20] as [Int?])
        let result = streamA.asyncStreamT.seqRight(streamB.asyncStreamT)
        let collected = await collect(result.rawValue)
        #expect(collected == [10, 20, nil])
    }

    @Test func asyncStreamOptionalFlatMap() async {
        let stream = makeStream([1, nil, 2] as [Int?])
        let result = stream.asyncStreamT.flatMap { n in
            makeStream([n, n * 10] as [Int?]).asyncStreamT
        }
        let collected = await collect(result.rawValue)
        #expect(collected == [1, 10, nil, 2, 20])
    }

    // MARK: - AsyncStreamTArray

    @Test func asyncStreamArrayMap() async {
        let stream = makeStream([[1, 2], [3, 4]])
        let result = stream.asyncStreamT.map { $0 * 2 }
        let collected = await collect(result.rawValue)
        #expect(collected == [[2, 4], [6, 8]])
    }

    @Test func asyncStreamArrayLiftA2() async {
        let streamA = makeStream([[1, 2]])
        let streamB = makeStream([[10, 20]])
        let result = AsyncStreamTArray<Int>.liftA2(+)(streamA.asyncStreamT, streamB.asyncStreamT)
        let collected = await collect(result.rawValue)
        #expect(collected == [[11, 21, 12, 22]])
    }

    // MARK: - AsyncStreamTResult

    private enum Err: Error, Equatable { case fail }

    @Test func asyncStreamResultMapSuccess() async {
        let stream = makeStream([Result<Int, Err>.success(5), .failure(.fail)])
        let result = stream.asyncStreamT.map { $0 * 2 }
        let collected = await collect(result.rawValue)
        #expect(collected == [.success(10), .failure(.fail)])
    }

    @Test func asyncStreamResultFlatMapSuccess() async {
        let stream = makeStream([Result<Int, Err>.success(3), .failure(.fail)])
        let result = stream.asyncStreamT.flatMap { n in
            makeStream([Result<String, Err>.success("\(n)")]).asyncStreamT
        }
        let collected = await collect(result.rawValue)
        #expect(collected == [.success("3"), .failure(.fail)])
    }
}
