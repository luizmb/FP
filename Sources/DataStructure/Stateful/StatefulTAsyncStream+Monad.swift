import CoreFP
import Foundation

// StatefulT + AsyncStream — Stateful<S, AsyncStream<A>>
//
// flatMapT is not implementable for this transformer stack: Swift's concurrency
// model prohibits capturing an `inout` parameter across async boundaries
// (the state `S` in `(inout S) -> A` cannot be shared with async closures).
// Use Stateful<S, [A]> or Stateful<S, AnyPublisher<A, E>> for monad sequencing.
