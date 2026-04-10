import CoreFP
import CoreFPOperators

// (<£>) :: (a -> b) -> DeferredStream a -> DeferredStream b
public func <£> <A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stream: DeferredStream<A>
) -> DeferredStream<B> {
    stream.map(fn)
}

// (<&>) :: DeferredStream a -> (a -> b) -> DeferredStream b
public func <&> <A: Sendable, B: Sendable>(
    _ stream: DeferredStream<A>,
    _ fn: @escaping @Sendable (A) -> B
) -> DeferredStream<B> {
    stream.map(fn)
}

// (£>) :: DeferredStream a -> b -> DeferredStream b
public func £> <A: Sendable, B: Sendable>(
    _ stream: DeferredStream<A>,
    _ value: B
) -> DeferredStream<B> {
    stream.replace(value)
}

// (<£) :: b -> DeferredStream a -> DeferredStream b
public func <£ <A: Sendable, B: Sendable>(
    _ value: B,
    _ stream: DeferredStream<A>
) -> DeferredStream<B> {
    stream £> value
}
