#if canImport(Combine)
import Foundation
import Core
import Combine

// StatefulT + Publisher — Stateful<S, any Publisher<A, E>>
//
// flatMapT is not implementable for this transformer stack: Combine's flatMap
// takes an @escaping closure, which cannot capture an `inout` parameter.
// Mutable state also cannot safely be shared across concurrent publisher events.
// Use Stateful<S, [A]> or Stateful<S, Result<A, E>> for monad sequencing.

#endif
