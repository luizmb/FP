import CoreFP

// MARK: - Function Monad Operators

/// Monad bind operator for functions (Reader monad)
/// (>>=) :: (r -> a) -> (a -> r -> b) -> (r -> b)
/// Using >>- to avoid conflict with Swift's >>= bitwise operator
public func >>- <R, A, B>(
    _ f: @escaping @Sendable (R) -> A,
    _ transform: @escaping @Sendable (A) -> (R) -> B
) -> (R) -> B {
    flatMap(f, transform)
}

/// Reverse bind operator for functions
/// (=<<) :: (a -> r -> b) -> (r -> a) -> (r -> b)
public func -<< <R, A, B>(
    _ transform: @escaping @Sendable (A) -> (R) -> B,
    _ f: @escaping @Sendable (R) -> A
) -> (R) -> B {
    f >>- transform
}

/// Kleisli composition operator for functions (left-to-right)
/// (>=>) :: (a -> r -> b) -> (b -> r -> c) -> (a -> r -> c)
public func >=> <R, A: Sendable, B, C>(
    _ f: @escaping @Sendable (A) -> (R) -> B,
    _ g: @escaping @Sendable (B) -> (R) -> C
) -> (A) -> (R) -> C {
    kleisli(f, g)
}

/// Kleisli composition operator for functions (right-to-left)
/// (<=<) :: (b -> r -> c) -> (a -> r -> b) -> (a -> r -> c)
public func <=< <R, A: Sendable, B, C>(
    _ g: @escaping @Sendable (B) -> (R) -> C,
    _ f: @escaping @Sendable (A) -> (R) -> B
) -> (A) -> (R) -> C {
    kleisliReverse(g, f)
}
