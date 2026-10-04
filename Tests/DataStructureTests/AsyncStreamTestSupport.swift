// SPDX-License-Identifier: Apache-2.0

// Shared helpers for AsyncStream tests: finite streams, slow streams, pull logging and collection.

/// A finite stream yielding `values` in order.
func streamOf<A: Sendable>(_ values: [A]) -> AsyncStream<A> {
    AsyncStream { continuation in
        for value in values {
            continuation.yield(value)
        }
        continuation.finish()
    }
}

/// A finite stream that suspends `yields` times before producing each element (and the end).
func slowStreamOf<A: Sendable>(_ values: [A], yields: Int) -> AsyncStream<A> {
    let cursor = UnfoldCursor(values)
    return AsyncStream(unfolding: {
        for _ in 0..<yields {
            await Task.yield()
        }
        return await cursor.next()
    })
}

/// A finite stream that records `label` in `log` every time it is pulled (including the final pull that ends it).
func loggedStream<A: Sendable>(_ label: String, _ values: [A], _ log: PullLog) -> AsyncStream<A> {
    let cursor = UnfoldCursor(values)
    return AsyncStream(unfolding: {
        await log.record(label)
        return await cursor.next()
    })
}

/// Collects every element of a stream.
func collectAll<A>(_ stream: AsyncStream<A>) async -> [A] {
    var results: [A] = []
    for await value in stream {
        results.append(value)
    }
    return results
}

/// Collects every element of a (possibly throwing) async sequence.
func collectAllThrowing<S: AsyncSequence>(_ sequence: S) async throws -> [S.Element] {
    var results: [S.Element] = []
    for try await value in sequence {
        results.append(value)
    }
    return results
}

actor PullLog {
    private(set) var entries: [String] = []
    func record(_ entry: String) { entries.append(entry) }
}

actor UnfoldCursor<A: Sendable> {
    private var remaining: [A]
    init(_ values: [A]) { remaining = values }
    func next() -> A? { remaining.isEmpty ? nil : remaining.removeFirst() }
}
