import Foundation

// MARK: - Function as Applicative

/// Pure/return for functions
/// For functions, pure is const - it creates a function that ignores its input
/// pure :: a -> (r -> a)
public func pure<R, A>(_ value: A) -> (R) -> A {
    const(value)
}

/// Applicative apply for functions
/// For functions, apply implements the S combinator
/// (<*>) :: (r -> a -> b) -> (r -> a) -> (r -> b)
public func apply<R, A, B>(
    _ f: @escaping (R) -> (A) -> B,
    _ g: @escaping (R) -> A
) -> (R) -> B {
    { r in
        f(r)(g(r))
    }
}

/// Curried version of apply for functions
public func apply<R, A, B>(
    _ f: @escaping (R) -> (A) -> B
) -> (@escaping (R) -> A) -> (R) -> B {
    { g in
        { r in
            f(r)(g(r))
        }
    }
}

/// Lift a binary function to work with functions
/// liftA2 :: (a -> b -> c) -> (r -> a) -> (r -> b) -> (r -> c)
public func liftA2<R, A, B, C>(
    _ f: @escaping (A) -> (B) -> C
) -> (@escaping (R) -> A) -> (@escaping (R) -> B) -> (R) -> C {
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
    _ f: @escaping (A) -> (B) -> C,
    _ fa: @escaping (R) -> A,
    _ fb: @escaping (R) -> B
) -> (R) -> C {
    { r in
        f(fa(r))(fb(r))
    }
}
