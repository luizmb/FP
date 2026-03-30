import CoreFP
import DataStructure
import CoreFPOperators

// (<£^>) :: (a -> b) -> Stateful<s, DeferredStream<a>> -> Stateful<s, DeferredStream<b>>
public func <£^> <S, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stateful: Stateful<S, DeferredStream<A>>
) -> Stateful<S, DeferredStream<B>> {
    stateful.mapT(fn)
}

// (<&^>) :: Stateful<s, DeferredStream<a>> -> (a -> b) -> Stateful<s, DeferredStream<b>>
public func <&^> <S, A: Sendable, B: Sendable>(
    _ stateful: Stateful<S, DeferredStream<A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Stateful<S, DeferredStream<B>> {
    stateful.mapT(fn)
}
