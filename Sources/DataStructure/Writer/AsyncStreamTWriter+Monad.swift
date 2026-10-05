// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// AsyncStreamTWriter: outer = AsyncStream, inner = Writer
// Type: AsyncStream<Writer<W, A>>  (Haskell: WriterT w AsyncStream a)
//
// flatMapT is WriterT's bind: the continuation returns the full stack, so it can emit several
// elements (or none) as well as log. It is ordered concat: each continuation stream runs to
// completion, in upstream order, and each result's log is prefixed by the log of the element
// it came from (`w1 <> w2`).

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AsyncStream {
    /// flatMapT :: AsyncStream<Writer<w, a>> -> (a -> AsyncStream<Writer<w, b>>) -> AsyncStream<Writer<w, b>>
    /// for each w1, for each w2 in fn(w1.value): Writer(w2.value, w1.log <> w2.log)
    func flatMapT<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> AsyncStream<Writer<W, B>>) -> AsyncStream<Writer<W, B>>
    where Element == Writer<W, A>, A: Sendable, B: Sendable {
        AsyncStream<Writer<W, B>> { continuation in
            let task = Task { @Sendable in
                for await w1 in self {
                    for await w2 in fn(w1.value) {
                        continuation.yield(Writer(w2.value, W.combine(w1.log, w2.log)))
                    }
                }
                continuation.finish()
            }
            // swiftlint:disable:next closure_ignoring_args
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// bindT :: (a -> AsyncStream<Writer<w, b>>) -> AsyncStream<Writer<w, a>> -> AsyncStream<Writer<w, b>>
    static func bindT<W: Monoid, A, B>(
        _ fn: @escaping @Sendable (A) -> AsyncStream<Writer<W, B>>
    ) -> @Sendable (AsyncStream<Writer<W, A>>) -> AsyncStream<Writer<W, B>>
    where A: Sendable, B: Sendable {
        { stream in stream.flatMapT(fn) }
    }
}

/// Kleisli composition for `AsyncStreamT + Writer` (left-to-right)
/// (>=>) :: (a -> AsyncStream<Writer<w, b>>) -> (b -> AsyncStream<Writer<w, c>>) -> a -> AsyncStream<Writer<w, c>>
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func kleisliT<W: Monoid, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> AsyncStream<Writer<W, B>>,
    _ fn2: @escaping @Sendable (B) -> AsyncStream<Writer<W, C>>
) -> @Sendable (A) -> AsyncStream<Writer<W, C>> where B: Sendable, C: Sendable {
    { a in fn1(a).flatMapT(fn2) }
}
