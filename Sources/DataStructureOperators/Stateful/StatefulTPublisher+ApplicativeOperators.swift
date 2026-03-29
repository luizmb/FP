#if canImport(Combine)
import Combine
import CoreFP
import CoreFPOperators
import DataStructure

// (<*>) :: Stateful<s, any Publisher<(a -> b), e>> -> Stateful<s, any Publisher<a, e>> -> Stateful<s, any Publisher<b, e>>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <*> <S, A, B, E: Error>(
    _ sf: Stateful<S, any Publisher<(A) -> B, E>>,
    _ sa: Stateful<S, any Publisher<A, E>>
) -> Stateful<S, any Publisher<B, E>> {
    applyStatefulPublisher(sf, sa)
}

// (*>) :: Stateful<s, any Publisher<a, e>> -> Stateful<s, any Publisher<b, e>> -> Stateful<s, any Publisher<b, e>>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func *> <S, A, B, E: Error>(
    _ lhs: Stateful<S, any Publisher<A, E>>,
    _ rhs: Stateful<S, any Publisher<B, E>>
) -> Stateful<S, any Publisher<B, E>> {
    seqRightStatefulPublisher(lhs, rhs)
}

// (<*) :: Stateful<s, any Publisher<a, e>> -> Stateful<s, any Publisher<b, e>> -> Stateful<s, any Publisher<a, e>>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <* <S, A, B, E: Error>(
    _ lhs: Stateful<S, any Publisher<A, E>>,
    _ rhs: Stateful<S, any Publisher<B, E>>
) -> Stateful<S, any Publisher<A, E>> {
    seqLeftStatefulPublisher(lhs, rhs)
}

#endif
