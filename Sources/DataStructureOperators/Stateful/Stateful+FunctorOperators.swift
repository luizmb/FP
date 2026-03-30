import CoreFP
import CoreFPOperators
import DataStructure
import Foundation

// (<$>) :: (a -> b) -> Stateful<s, a> -> Stateful<s, b>
public func <£> <S, A, B>(
    _ transform: @escaping (A) -> B,
    _ stateful: Stateful<S, A>
) -> Stateful<S, B> {
    stateful.fmap(transform)
}

// ($>) :: Stateful<s, a> -> b -> Stateful<s, b>
public func £> <S, A, B>(
    _ stateful: Stateful<S, A>,
    _ value: B
) -> Stateful<S, B> {
    stateful.fmap(const(value))
}

// (<$) :: b -> Stateful<s, a> -> Stateful<s, b>
public func <£ <S, A, B>(
    _ value: B,
    _ stateful: Stateful<S, A>
) -> Stateful<S, B> {
    stateful £> value
}

// (<&>) :: Stateful<s, a> -> (a -> b) -> Stateful<s, b>
public func <&> <S, A, B>(
    _ stateful: Stateful<S, A>,
    _ transform: @escaping (A) -> B
) -> Stateful<S, B> {
    stateful.mapStateful(transform)
}
