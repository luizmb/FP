// SPDX-License-Identifier: Apache-2.0
import Foundation

// MARK: - Function as Functor

/// Functor instance for functions
/// For functions, fmap is just function composition
/// fmap :: (b -> c) -> (a -> b) -> (a -> c)
public func fmap<A, B, C>(
    _ transform: @escaping @Sendable (B) -> C,
    _ f: @escaping @Sendable (A) -> B
) -> @Sendable (A) -> C {
    compose(f, transform)
}

/// Curried version of fmap for functions
public func fmap<A, B, C>(
    _ transform: @escaping @Sendable (B) -> C
) -> @Sendable (@escaping @Sendable (A) -> B) -> @Sendable (A) -> C {
    { f in
        compose(f, transform)
    }
}
