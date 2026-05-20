import Foundation

// Composition helpers are pure — they only capture their `@Sendable` function inputs,
// so the function they return is unconditionally `@Sendable` (no extra constraints on A, B, …).
// Callers that need a non-`@Sendable` function can rely on the implicit conversion
// `@Sendable (X) -> Y  →  (X) -> Y` at the use site.

public func compose<A, B, C>(
    _ ab: @escaping @Sendable (A) -> B,
    _ bc: @escaping @Sendable (B) -> C
) -> @Sendable (A) -> C {
    { a in bc(ab(a)) }
}

public extension Of3 {
    static func compose(
        _ fn1: @escaping @Sendable (T) -> U,
        _ fn2: @escaping @Sendable (U) -> V
    ) -> @Sendable (T) -> V {
        CoreFP.compose(fn1, fn2)
    }
}

public func compose3<A, B, C, D>(
    _ ab: @escaping @Sendable (A) -> B,
    _ bc: @escaping @Sendable (B) -> C,
    _ cd: @escaping @Sendable (C) -> D
) -> @Sendable (A) -> D {
    { a in cd(bc(ab(a))) }
}

public func compose4<A, B, C, D, E>(
    _ ab: @escaping @Sendable (A) -> B,
    _ bc: @escaping @Sendable (B) -> C,
    _ cd: @escaping @Sendable (C) -> D,
    _ de: @escaping @Sendable (D) -> E
) -> @Sendable (A) -> E {
    { a in de(cd(bc(ab(a)))) }
}

public func apply<A, B>(
    _ value: A,
    _ fn: (A) -> B
) -> B {
    fn(value)
}

public func call<A, B>(
    _ fn: (A) -> B,
    _ value: A
) -> B {
    fn(value)
}

public func call<A, B>() -> ((A) -> B, A) -> B {
    call
}

public func call<A, B, C>(
    then transform: @escaping @Sendable (B) -> C
) -> @Sendable (@escaping @Sendable (A) -> B, A) -> C {
    { f, a in transform(f(a)) }
}
