import CoreFP

// MARK: - Function Composition

/// Left-to-right function composition
/// (>>>) :: (a -> b) -> (b -> c) -> a -> c
public func >>> <A, B, C>(
    _ f: @escaping (A) -> B,
    _ g: @escaping (B) -> C
) -> (A) -> C {
    { a in g(f(a)) }
}

/// Right-to-left function composition
/// (<<<) :: (b -> c) -> (a -> b) -> a -> c
public func <<< <A, B, C>(
    _ g: @escaping (B) -> C,
    _ f: @escaping (A) -> B
) -> (A) -> C {
    { a in g(f(a)) }
}

/// Right-to-left function composition (alternative symbol)
/// (•) :: (b -> c) -> (a -> b) -> a -> c
public func • <A, B, C>(
    _ g: @escaping (B) -> C,
    _ f: @escaping (A) -> B
) -> (A) -> C {
    { a in g(f(a)) }
}

// MARK: - Function Application

/// Function application operator (low precedence)
/// ($) :: (a -> b) -> a -> b
public func £ <A, B>(
    _ fn: @escaping (A) -> B,
    _ value: A
) -> B {
    fn(value)
}

/// Function application operator (alternative symbol)
/// (<|) :: (a -> b) -> a -> b
public func <| <A, B>(
    _ fn: @escaping (A) -> B,
    _ value: A
) -> B {
    fn(value)
}

/// Flipped function application operator
/// (|>) :: a -> (a -> b) -> b
public func |> <A, B>(
    _ value: A,
    _ fn: @escaping (A) -> B
) -> B {
    fn(value)
}
