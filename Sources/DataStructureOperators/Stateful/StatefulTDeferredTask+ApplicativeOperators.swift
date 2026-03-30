import CoreFP
import DataStructure
import CoreFPOperators

// (<*>) :: Stateful<s, DeferredTask<(a -> b)>> -> Stateful<s, DeferredTask<a>> -> Stateful<s, DeferredTask<b>>
public func <*> <S, A: Sendable, B: Sendable>(
    _ sf: Stateful<S, DeferredTask<@Sendable (A) -> B>>,
    _ sa: Stateful<S, DeferredTask<A>>
) -> Stateful<S, DeferredTask<B>> {
    applyStatefulDeferredTask(sf, sa)
}

// (*>) :: Stateful<s, DeferredTask<a>> -> Stateful<s, DeferredTask<b>> -> Stateful<s, DeferredTask<b>>
public func *> <S, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, DeferredTask<A>>,
    _ rhs: Stateful<S, DeferredTask<B>>
) -> Stateful<S, DeferredTask<B>> {
    seqRightStatefulDeferredTask(lhs, rhs)
}

// (<*) :: Stateful<s, DeferredTask<a>> -> Stateful<s, DeferredTask<b>> -> Stateful<s, DeferredTask<a>>
public func <* <S, A: Sendable, B: Sendable>(
    _ lhs: Stateful<S, DeferredTask<A>>,
    _ rhs: Stateful<S, DeferredTask<B>>
) -> Stateful<S, DeferredTask<A>> {
    seqLeftStatefulDeferredTask(lhs, rhs)
}
