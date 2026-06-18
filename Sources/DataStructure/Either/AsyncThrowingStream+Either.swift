// SPDX-License-Identifier: Apache-2.0
// Bridges between AsyncThrowingStream and Either.
//
// A throwing async stream is structurally equivalent to a non-throwing stream
// of Either values — errors are just left values, elements are right values.
//
// toEitherStream  — materialise: turns throws into .left, elements into .right
// toThrowingStream — dematerialise: turns .left into throws, .right into elements
//
// Note: AsyncThrowingStream's continuation initialiser requires Failure == any Error,
// so toThrowingStream returns AsyncThrowingStream<R, any Error>. The actual thrown
// value is still the concrete L error; only the static type is erased.

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncThrowingStream where Element: Sendable, Failure: Sendable {
    /// toEitherStream :: AsyncThrowingStream<a, e> -> AsyncStream<Either<e, a>>
    ///
    /// Converts a throwing stream into a non-throwing stream of Either values.
    /// The stream never throws — errors surface as .left elements instead.
    func toEitherStream() -> AsyncStream<Either<Failure, Element>> {
        AsyncStream { continuation in
            Task {
                do {
                    for try await element in self {
                        continuation.yield(.right(element))
                    }
                    continuation.finish()
                } catch let error as Failure {
                    continuation.yield(.left(error))
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncStream {
    /// toThrowingStream :: AsyncStream<Either<e, a>> -> AsyncThrowingStream<a, any Error>
    ///
    /// Converts a non-throwing stream of Either values into a throwing stream.
    /// .right elements are yielded normally; the first .left element throws and ends the stream.
    func toThrowingStream<L: Error & Sendable, R: Sendable>() -> AsyncThrowingStream<R, any Error> where Element == Either<L, R> {
        AsyncThrowingStream { continuation in
            Task {
                for await element in self {
                    switch element {
                    case .right(let value):
                        continuation.yield(value)

                    case .left(let error):
                        continuation.finish(throwing: error)
                        return
                    }
                }
                continuation.finish()
            }
        }
    }
}
