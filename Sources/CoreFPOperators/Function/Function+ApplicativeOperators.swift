import CoreFP

// MARK: - Function Applicative Operators

/// Applicative apply operator for functions (S combinator)
/// (<*>) :: (r -> a -> b) -> (r -> a) -> (r -> b)
public func <*> <R, A, B>(
    _ f: @escaping @Sendable (R) -> @Sendable (A) -> B,
    _ g: @escaping @Sendable (R) -> A
) -> @Sendable (R) -> B {
    apply(f, g)
}

/// Sequence right operator for functions
/// (*>) :: (r -> a) -> (r -> b) -> (r -> b)
public func *> <R, A, B>(
    _ f: @escaping @Sendable (R) -> A,
    _ g: @escaping @Sendable (R) -> B
) -> @Sendable (R) -> B {
    { r in
        _ = f(r)
        return g(r)
    }
}

/// Sequence left operator for functions
/// (<*) :: (r -> a) -> (r -> b) -> (r -> a)
public func <* <R, A, B>(
    _ f: @escaping @Sendable (R) -> A,
    _ g: @escaping @Sendable (R) -> B
) -> @Sendable (R) -> A {
    { r in
        let result = f(r)
        _ = g(r)
        return result
    }
}
