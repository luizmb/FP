import Foundation

// MARK: - Function as Applicative

/// Pure/return for functions
/// For functions, pure is const - it creates a function that ignores its input
/// pure :: a -> (r -> a)
public func pure<R, A: Sendable>(_ value: A) -> @Sendable (R) -> A {
    { _ in value }
}

/// Applicative apply for functions
/// For functions, apply implements the S combinator
/// (<*>) :: (r -> a -> b) -> (r -> a) -> (r -> b)
public func apply<R, A, B>(
    _ f: @escaping @Sendable (R) -> @Sendable (A) -> B,
    _ g: @escaping @Sendable (R) -> A
) -> @Sendable (R) -> B {
    { r in
        f(r)(g(r))
    }
}

/// Curried version of apply for functions
public func apply<R, A, B>(
    _ f: @escaping @Sendable (R) -> @Sendable (A) -> B
) -> @Sendable (@escaping @Sendable (R) -> A) -> @Sendable (R) -> B {
    { g in
        { r in
            f(r)(g(r))
        }
    }
}

/// Lift a binary function to work with functions
/// liftA2 :: (a -> b -> c) -> (r -> a) -> (r -> b) -> (r -> c)
public func liftA2<R, A, B, C>(
    _ f: @escaping @Sendable (A) -> @Sendable (B) -> C
) -> @Sendable (@escaping @Sendable (R) -> A) -> @Sendable (@escaping @Sendable (R) -> B) -> @Sendable (R) -> C {
    { fa in
        { fb in
            { r in
                f(fa(r))(fb(r))
            }
        }
    }
}

/// Non-curried version of liftA2 for functions
public func liftA2<R, A, B, C>(
    _ f: @escaping @Sendable (A) -> @Sendable (B) -> C,
    _ fa: @escaping @Sendable (R) -> A,
    _ fb: @escaping @Sendable (R) -> B
) -> @Sendable (R) -> C {
    { r in
        f(fa(r))(fb(r))
    }
}
