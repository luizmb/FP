import Foundation

// MARK: - Function as Functor

/// Functor instance for functions
/// For functions, fmap is just function composition
/// fmap :: (b -> c) -> (a -> b) -> (a -> c)
public func fmap<A, B, C>(
    _ transform: @escaping @Sendable (B) -> C,
    _ f: @escaping @Sendable (A) -> B
) -> (A) -> C {
    compose(f, transform)
}

/// Curried version of fmap for functions
public func fmap<A, B, C>(
    _ transform: @escaping @Sendable (B) -> C
) -> (@escaping @Sendable (A) -> B) -> (A) -> C {
    { f in
        compose(f, transform)
    }
}
