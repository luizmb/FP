import Foundation

// MARK: - Function as Monad

/// Monad bind for functions (Reader monad)
/// For functions, bind applies both the function and the continuation to the same input
/// (>>=) :: (r -> a) -> (a -> r -> b) -> (r -> b)
public func flatMap<R, A, B>(
    _ f: @escaping (R) -> A,
    _ transform: @escaping (A) -> (R) -> B
) -> (R) -> B {
    { r in
        transform(f(r))(r)
    }
}

/// Curried version of flatMap for functions
public func flatMap<R, A, B>(
    _ transform: @escaping (A) -> (R) -> B
) -> (@escaping (R) -> A) -> (R) -> B {
    { f in
        { r in
            transform(f(r))(r)
        }
    }
}

/// Monad join for functions
/// Flattens a nested function by applying the outer function and then the inner
/// join :: (r -> (r -> a)) -> (r -> a)
public func join<R, A>(
    _ f: @escaping (R) -> (R) -> A
) -> (R) -> A {
    { r in
        f(r)(r)
    }
}

/// Kleisli composition for functions
/// Composes two monadic functions (Kleisli arrows)
/// (>=>) :: (a -> r -> b) -> (b -> r -> c) -> (a -> r -> c)
public func kleisli<R, A, B, C>(
    _ f: @escaping (A) -> (R) -> B,
    _ g: @escaping (B) -> (R) -> C
) -> (A) -> (R) -> C {
    { a in
        flatMap({ r in f(a)(r) }, g)
    }
}

/// Reverse Kleisli composition for functions
/// (<=<) :: (b -> r -> c) -> (a -> r -> b) -> (a -> r -> c)
public func kleisliReverse<R, A, B, C>(
    _ g: @escaping (B) -> (R) -> C,
    _ f: @escaping (A) -> (R) -> B
) -> (A) -> (R) -> C {
    kleisli(f, g)
}
