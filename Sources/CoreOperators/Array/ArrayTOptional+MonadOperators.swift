import Core

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>

// (>>-) :: [a?] -> (a -> [b?]) -> [b?]
public func >>- <A, B>(_ arr: [A?], _ fn: @escaping (A) -> [B?]) -> [B?] {
    arr.flatMapT(fn)
}

// (-<<) :: (a -> [b?]) -> [a?] -> [b?]
public func -<< <A, B>(_ fn: @escaping (A) -> [B?], _ arr: [A?]) -> [B?] {
    arr.flatMapT(fn)
}

// (>=>) :: (a -> [b?]) -> (b -> [c?]) -> a -> [c?]
public func >=> <A, B, C>(_ fn1: @escaping (A) -> [B?], _ fn2: @escaping (B) -> [C?]) -> (A) -> [C?] {
    { a in fn1(a).flatMapT(fn2) }
}
