// StatefulTDeferredStream: outer = Stateful, inner = DeferredStream
// Type: Stateful<S, DeferredStream<A>>
//
// flatMapT is not implementable for this stack: Swift's concurrency model
// prohibits capturing an `inout` state parameter across async boundaries.
// Use Stateful<S, [A]> when monad sequencing with state is needed.
