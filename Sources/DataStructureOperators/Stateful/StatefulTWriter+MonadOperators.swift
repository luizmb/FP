import CoreFP
import CoreFPOperators
import DataStructure

// (>>-) :: Stateful<s, Writer<w, a>> -> (a -> Writer<w, b>) -> Stateful<s, Writer<w, b>>
public func >>- <S, W: Monoid, A, B>(
    _ stateful: Stateful<S, Writer<W, A>>,
    _ fn: @escaping (A) -> Writer<W, B>
) -> Stateful<S, Writer<W, B>> {
    stateful.flatMapT(fn)
}

// (-<<) :: (a -> Writer<w, b>) -> Stateful<s, Writer<w, a>> -> Stateful<s, Writer<w, b>>
public func -<< <S, W: Monoid, A, B>(
    _ fn: @escaping (A) -> Writer<W, B>,
    _ stateful: Stateful<S, Writer<W, A>>
) -> Stateful<S, Writer<W, B>> {
    stateful.flatMapT(fn)
}

// Note: Kleisli composition for (a -> Writer<w, b>) -> (b -> Writer<w, c>) is already
// provided by Writer+MonadOperators.swift's base >=> declaration.
