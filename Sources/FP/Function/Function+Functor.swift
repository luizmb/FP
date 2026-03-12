import Foundation

// MARK: - Function as Functor

/// Functor instance for functions
/// For functions, fmap is just function composition
/// fmap :: (b -> c) -> (a -> b) -> (a -> c)
public func fmap<A, B, C>(
    _ transform: @escaping (B) -> C,
    _ f: @escaping (A) -> B
) -> (A) -> C {
    compose(f, transform)
}

/// Curried version of fmap for functions
public func fmap<A, B, C>(
    _ transform: @escaping (B) -> C
) -> (@escaping (A) -> B) -> (A) -> C {
    { f in
        compose(f, transform)
    }
}
