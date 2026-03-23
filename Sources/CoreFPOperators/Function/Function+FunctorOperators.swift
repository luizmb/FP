import CoreFP

// MARK: - Function Functor Operators

/// Functor fmap operator for functions
/// For functions, this is function composition
/// (<£>) :: (b -> c) -> (a -> b) -> (a -> c)
public func <£> <A, B, C>(
    _ transform: @escaping (B) -> C,
    _ f: @escaping (A) -> B
) -> (A) -> C {
    compose(f, transform)
}

/// Map replace operator for functions (always returns a constant)
/// (£>) :: (a -> b) -> c -> (a -> c)
public func £> <A, B, C>(
    _ f: @escaping (A) -> B,
    _ value: C
) -> (A) -> C {
    const(value)
}

/// Flipped map replace operator for functions
/// (<£) :: c -> (a -> b) -> (a -> c)
public func <£ <A, B, C>(
    _ value: C,
    _ f: @escaping (A) -> B
) -> (A) -> C {
    f £> value
}

/// Flipped functor fmap for functions — left-to-right composition
/// (<&>) :: (a -> b) -> (b -> c) -> (a -> c)
public func <&> <A, B, C>(
    _ f: @escaping (A) -> B,
    _ transform: @escaping (B) -> C
) -> (A) -> C {
    compose(f, transform)
}
