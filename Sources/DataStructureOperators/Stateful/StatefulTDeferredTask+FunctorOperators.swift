import CoreFP
import CoreFPOperators
import DataStructure

// (<£^>) :: (a -> b) -> Stateful<s, DeferredTask<a>> -> Stateful<s, DeferredTask<b>>
public func <£^> <S, A: Sendable, B: Sendable>(
    _ fn: @escaping @Sendable (A) -> B,
    _ stateful: Stateful<S, DeferredTask<A>>
) -> Stateful<S, DeferredTask<B>> {
    stateful.mapT(fn)
}

// (<&^>) :: Stateful<s, DeferredTask<a>> -> (a -> b) -> Stateful<s, DeferredTask<b>>
public func <&^> <S, A: Sendable, B: Sendable>(
    _ stateful: Stateful<S, DeferredTask<A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Stateful<S, DeferredTask<B>> {
    stateful.mapT(fn)
}
