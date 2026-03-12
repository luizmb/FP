import FP

// MARK: - Function Applicative Operators

/// Applicative apply operator for functions (S combinator)
/// (<*>) :: (r -> a -> b) -> (r -> a) -> (r -> b)
public func <*> <R, A, B>(
    _ f: @escaping (R) -> (A) -> B,
    _ g: @escaping (R) -> A
) -> (R) -> B {
    apply(f, g)
}

/// Sequence right operator for functions
/// (*>) :: (r -> a) -> (r -> b) -> (r -> b)
public func *> <R, A, B>(
    _ f: @escaping (R) -> A,
    _ g: @escaping (R) -> B
) -> (R) -> B {
    { r in
        _ = f(r)
        return g(r)
    }
}

/// Sequence left operator for functions
/// (<*) :: (r -> a) -> (r -> b) -> (r -> a)
public func <* <R, A, B>(
    _ f: @escaping (R) -> A,
    _ g: @escaping (R) -> B
) -> (R) -> A {
    { r in
        let result = f(r)
        _ = g(r)
        return result
    }
}
