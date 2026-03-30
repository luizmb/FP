// StatefulTDeferredTask: outer = Stateful, inner = DeferredTask
// Type: Stateful<S, DeferredTask<A>>
//
// flatMapT is not implementable for this stack: Swift's `@Sendable` async closures
// cannot capture `inout` state parameters. The state mutation in Stateful and the
// async execution in DeferredTask cannot be safely composed.
// Use Stateful<S, Result<A,E>> or Reader<Env, DeferredTask<A>> instead.
