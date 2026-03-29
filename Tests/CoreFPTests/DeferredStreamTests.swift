import CoreFP
import Testing

private enum TestError: Error, Equatable { case err }

@Suite struct DeferredStreamTests {
    // MARK: - Lazy behavior

    @Test func doesNotStartUntilIterated() async {
        nonisolated(unsafe) var started = false
        let stream = DeferredStream<Int> {
            AsyncStream<Int> { continuation in
                started = true
                continuation.yield(42)
                continuation.finish()
            }
        }
        #expect(!started, "factory must not run before iteration")
        var results: [Int] = []
        for await v in stream { results.append(v) }
        #expect(started)
        #expect(results == [42])
    }

    // MARK: - Functor

    @Test func fmap() async {
        let stream = DeferredStream<Int> {
            AsyncStream<Int> { c in c.yield(1); c.yield(2); c.yield(3); c.finish() }
        }
        var results: [Int] = []
        for await v in stream.fmap({ $0 * 2 }) { results.append(v) }
        #expect(results == [2, 4, 6])
    }

    @Test func replace() async {
        let stream = DeferredStream<Int> {
            AsyncStream<Int> { c in c.yield(1); c.yield(2); c.finish() }
        }
        var results: [String] = []
        for await v in stream.replace("x") { results.append(v) }
        #expect(results == ["x", "x"])
    }

    // MARK: - Applicative

    @Test func pure() async {
        var results: [Int] = []
        for await v in DeferredStream<Int>.pure(99) { results.append(v) }
        #expect(results == [99])
    }

    @Test func seqRight() async {
        let lhs = DeferredStream<Int> { AsyncStream { c in c.yield(1); c.yield(2); c.finish() } }
        let rhs = DeferredStream<String> { AsyncStream { c in c.yield("a"); c.yield("b"); c.finish() } }
        var results: [String] = []
        for await v in lhs.seqRight(rhs) { results.append(v) }
        #expect(results == ["a", "b"])
    }

    @Test func seqLeft() async {
        let lhs = DeferredStream<Int> { AsyncStream { c in c.yield(1); c.yield(2); c.finish() } }
        let rhs = DeferredStream<String> { AsyncStream { c in c.yield("a"); c.yield("b"); c.finish() } }
        var results: [Int] = []
        for await v in lhs.seqLeft(rhs) { results.append(v) }
        #expect(results == [1, 2])
    }

    // MARK: - Monad

    @Test func flatMap() async {
        let stream = DeferredStream<Int> {
            AsyncStream<Int> { c in c.yield(1); c.yield(2); c.finish() }
        }
        let result = stream.flatMap { n in
            DeferredStream<Int> { AsyncStream { c in c.yield(n); c.yield(n * 10); c.finish() } }
        }
        var results: [Int] = []
        for await v in result { results.append(v) }
        #expect(results == [1, 10, 2, 20])
    }

    @Test func kleisli() async {
        let f: @Sendable (Int) -> DeferredStream<Int> = { n in
            DeferredStream { AsyncStream { c in c.yield(n + 1); c.finish() } }
        }
        let g: @Sendable (Int) -> DeferredStream<String> = { n in
            DeferredStream { AsyncStream { c in c.yield("\(n)"); c.finish() } }
        }
        let fg = DeferredStream<Int>.kleisli(f, g)
        var results: [String] = []
        for await v in fg(5) { results.append(v) }
        #expect(results == ["6"])
    }

    // MARK: - Zip

    private func makeStream<A>(_ values: A...) -> DeferredStream<A> {
        DeferredStream<A> { AsyncStream { c in values.forEach { c.yield($0) }; c.finish() } }
    }

    @Test func zipPairsElementsPositionally() async {
        var results: [(Int, String)] = []
        for await pair in DeferredStream.zip(makeStream(1, 2, 3), makeStream("a", "b", "c")) {
            results.append(pair)
        }
        #expect(results.map(\.0) == [1, 2, 3])
        #expect(results.map(\.1) == ["a", "b", "c"])
    }

    @Test func zipStopsAtShorterStream() async {
        var results: [(Int, Int)] = []
        for await pair in DeferredStream.zip(makeStream(1, 2), makeStream(10, 20, 30)) {
            results.append(pair)
        }
        #expect(results.count == 2)
        #expect(results.map(\.0) == [1, 2])
        #expect(results.map(\.1) == [10, 20])
    }

    @Test func zip3PairsAllThreeStreams() async {
        var results: [(Int, String, Bool)] = []
        for await triple in DeferredStream.zip3(makeStream(1, 2), makeStream("a", "b"), makeStream(true, false)) {
            results.append(triple)
        }
        #expect(results.count == 2)
        #expect(results.map(\.0) == [1, 2])
        #expect(results.map(\.1) == ["a", "b"])
        #expect(results.map(\.2) == [true, false])
    }

    @Test func zip3StopsAtShortestStream() async {
        var count = 0
        for await _ in DeferredStream.zip3(makeStream(1, 2, 3), makeStream("a"), makeStream(true, false, true)) {
            count += 1
        }
        #expect(count == 1)
    }

    @Test func zip4PairsAllFourStreams() async {
        var results: [(Int, String, Bool, Double)] = []
        for await quad in DeferredStream.zip4(makeStream(1, 2), makeStream("a", "b"), makeStream(true, false), makeStream(1.0, 2.0)) {
            results.append(quad)
        }
        #expect(results.count == 2)
        #expect(results.map(\.0) == [1, 2])
        #expect(results.map(\.1) == ["a", "b"])
        #expect(results.map(\.2) == [true, false])
        #expect(results.map(\.3) == [1.0, 2.0])
    }

    // MARK: - TOptional

    @Test func tOptionalMapT() async {
        let stream = DeferredStream<Int?> {
            AsyncStream<Int?> { c in c.yield(1); c.yield(nil); c.yield(3); c.finish() }
        }
        var results: [Int?] = []
        for await v in mapTDeferredStreamOptional({ $0 * 2 }, stream) { results.append(v) }
        #expect(results == [2, nil, 6])
    }

    @Test func tOptionalFlatMapT() async {
        let stream = DeferredStream<Int?> {
            AsyncStream<Int?> { c in c.yield(2); c.yield(nil); c.finish() }
        }
        let result = flatMapTDeferredStreamOptional(stream) { n in
            DeferredStream<Int?> { AsyncStream { c in c.yield(n * 10); c.finish() } }
        }
        var results: [Int?] = []
        for await v in result { results.append(v) }
        #expect(results == [20, nil])
    }

    // MARK: - TArray

    @Test func tArrayMapT() async {
        let stream = DeferredStream<[Int]> {
            AsyncStream<[Int]> { c in c.yield([1, 2]); c.yield([3]); c.finish() }
        }
        var results: [[Int]] = []
        for await v in mapTDeferredStreamArray({ $0 * 2 }, stream) { results.append(v) }
        #expect(results == [[2, 4], [6]])
    }

    @Test func tArrayFlatMapT() async {
        let stream = DeferredStream<[Int]> {
            AsyncStream<[Int]> { c in c.yield([1, 2]); c.finish() }
        }
        let result = flatMapTDeferredStreamArray(stream) { n in
            DeferredStream<[Int]> { AsyncStream { c in c.yield([n, n * 10]); c.finish() } }
        }
        var results: [[Int]] = []
        for await v in result { results.append(v) }
        #expect(results == [[1, 10, 2, 20]])
    }

    // MARK: - TResult

    @Test func tResultMapT() async {
        let stream = DeferredStream<Result<Int, TestError>> {
            AsyncStream<Result<Int, TestError>> { c in
                c.yield(.success(3))
                c.yield(.failure(.err))
                c.finish()
            }
        }
        var results: [Result<Int, TestError>] = []
        for await v in mapTDeferredStreamResult({ $0 * 2 }, stream) { results.append(v) }
        #expect(results == [.success(6), .failure(.err)])
    }

    @Test func tResultFlatMapT() async {
        let stream = DeferredStream<Result<Int, TestError>> {
            AsyncStream<Result<Int, TestError>> { c in c.yield(.success(5)); c.finish() }
        }
        let result = flatMapTDeferredStreamResult(stream) { n in
            DeferredStream<Result<String, TestError>> {
                AsyncStream { c in c.yield(.success("v\(n)")); c.finish() }
            }
        }
        var results: [Result<String, TestError>] = []
        for await v in result { results.append(v) }
        #expect(results == [.success("v5")])
    }

    // MARK: - join / void

    @Test func joinFreeFunction() async {
        let inner = DeferredStream<Int> { AsyncStream { c in c.yield(1); c.yield(2); c.finish() } }
        let nested = DeferredStream<DeferredStream<Int>> { AsyncStream { c in c.yield(inner); c.finish() } }
        var collected: [Int] = []
        for await v in CoreFP.join(nested) { collected.append(v) }
        #expect(collected == [1, 2])
    }

    @Test func voidFreeFunction() async {
        let stream = DeferredStream<Int> { AsyncStream { c in c.yield(1); c.yield(2); c.finish() } }
        var count = 0
        for await _ in CoreFP.void(stream) { count += 1 }
        #expect(count == 2)
    }

    // MARK: - Alternative

    @Test func altConcatenatesElements() async {
        let lhs = DeferredStream<Int> { AsyncStream { c in c.yield(1); c.yield(2); c.finish() } }
        let rhs = DeferredStream<Int> { AsyncStream { c in c.yield(3); c.yield(4); c.finish() } }
        var results: [Int] = []
        for await v in DeferredStream.alt(lhs, rhs) { results.append(v) }
        #expect(results == [1, 2, 3, 4])
    }

    @Test func altEmptyLhsYieldsRhs() async {
        let lhs = DeferredStream<Int> { AsyncStream { c in c.finish() } }
        let rhs = DeferredStream<Int> { AsyncStream { c in c.yield(42); c.finish() } }
        var results: [Int] = []
        for await v in DeferredStream.alt(lhs, rhs) { results.append(v) }
        #expect(results == [42])
    }

    @Test func altEmptyRhsYieldsLhs() async {
        let lhs = DeferredStream<Int> { AsyncStream { c in c.yield(1); c.finish() } }
        let rhs = DeferredStream<Int> { AsyncStream { c in c.finish() } }
        var results: [Int] = []
        for await v in DeferredStream.alt(lhs, rhs) { results.append(v) }
        #expect(results == [1])
    }
}
