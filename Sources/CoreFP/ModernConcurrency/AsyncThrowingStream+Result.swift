// MARK: - AsyncThrowingStream <-> Result bridges
//
// A throwing async stream is structurally equivalent to a non-throwing stream
// of Result values — errors are just failures, elements are successes.
//
// This is the "materialise/dematerialise" pattern:
//   toResultStream   — materialise: turns throws into .failure, elements into .success
//   toThrowingStream — dematerialise: turns .failure into throws, .success into elements
//
// Use cases:
//   - Buffer error streams for retry/recovery logic (materialise first)
//   - Feed a non-throwing Result stream into APIs that expect throwing streams
//
// Note: AsyncThrowingStream's continuation initialiser requires Failure == any Error,
// so toThrowingStream returns AsyncThrowingStream<Success, any Error>. The actual thrown
// value is still the concrete E error; only the static type is erased.

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AsyncThrowingStream where Element: Sendable, Failure: Sendable {
    // toResultStream :: AsyncThrowingStream<a, e> -> AsyncStream<Result<a, e>>
    //
    // Converts a throwing stream into a non-throwing stream of Result values.
    // The stream never throws — errors surface as .failure elements instead.
    func toResultStream() -> AsyncStream<Result<Element, Failure>> {
        AsyncStream { continuation in
            Task {
                do {
                    for try await element in self {
                        continuation.yield(.success(element))
                    }
                    continuation.finish()
                } catch let error as Failure {
                    continuation.yield(.failure(error))
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
    // toThrowingStream :: AsyncStream<Result<a, e>> -> AsyncThrowingStream<a, any Error>
    //
    // Converts a non-throwing stream of Result values into a throwing stream.
    // .success elements are yielded normally; the first .failure element throws and ends the stream.
    func toThrowingStream<Success: Sendable, E: Error & Sendable>() -> AsyncThrowingStream<Success, any Error>
    where Element == Result<Success, E> {
        AsyncThrowingStream { continuation in
            Task {
                for await element in self {
                    switch element {
                    case .success(let value):
                        continuation.yield(value)
                    case .failure(let error):
                        continuation.finish(throwing: error)
                        return
                    }
                }
                continuation.finish()
            }
        }
    }
}
