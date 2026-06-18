// SPDX-License-Identifier: Apache-2.0
import CoreFP

/// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <A, A1>(_ optional: A?, _ fn: @escaping @Sendable (A) -> A1?) -> A1? {
    optional.flatMap(fn)
}

/// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <A, A1>(_ fn: @escaping @Sendable (A) -> A1?, _ optional: A?) -> A1? {
    optional.flatMap(fn)
}

/// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <A0, A, A1>(
    _ fn1: @escaping @Sendable (A0) -> A?,
    _ fn2: @escaping @Sendable (A) -> A1?
) -> (A0) -> A1? {
    Optional.kleisli(fn1, fn2)
}

/// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <A, A1>(_ optional: A?, _ transform: @escaping @Sendable (A) -> A1) -> A1? {
    optional.map(transform)
}

/// (<|>) :: Alternative f => f a -> f a -> f a
public func <|> <A>(_ lhs: A?, _ rhs: @autoclosure () -> A?) -> A? {
    Optional.alt(lhs, rhs())
}
