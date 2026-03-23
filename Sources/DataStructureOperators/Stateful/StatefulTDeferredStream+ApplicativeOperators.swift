import DataStructure
import CoreFPOperators
import CoreFP

// (<*>) :: Stateful<s, DeferredStream<(a -> b)>> -> Stateful<s, DeferredStream<a>> -> Stateful<s, DeferredStream<b>>
public func <*> <S, A: Sendable, B: Sendable>(_ sf: Stateful<S, DeferredStream<@Sendable (A) -> B>>, _ sa: Stateful<S, DeferredStream<A>>) -> Stateful<S, DeferredStream<B>> {
    applyStatefulDeferredStream(sf, sa)
}

// (*>) :: Stateful<s, DeferredStream<a>> -> Stateful<s, DeferredStream<b>> -> Stateful<s, DeferredStream<b>>
public func *> <S, A: Sendable, B: Sendable>(_ lhs: Stateful<S, DeferredStream<A>>, _ rhs: Stateful<S, DeferredStream<B>>) -> Stateful<S, DeferredStream<B>> {
    seqRightStatefulDeferredStream(lhs, rhs)
}

// (<*) :: Stateful<s, DeferredStream<a>> -> Stateful<s, DeferredStream<b>> -> Stateful<s, DeferredStream<a>>
public func <* <S, A: Sendable, B: Sendable>(_ lhs: Stateful<S, DeferredStream<A>>, _ rhs: Stateful<S, DeferredStream<B>>) -> Stateful<S, DeferredStream<A>> {
    seqLeftStatefulDeferredStream(lhs, rhs)
}
