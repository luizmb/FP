import Foundation

public func compose<A, B, C>(_ ab: @escaping (A) -> B, _ bc: @escaping (B) -> C) -> (A) -> C {
    { a in
        bc(ab(a))
    }
}

public extension Of3 {
    static func compose(_ fn1: @escaping (T) -> U, _ fn2: @escaping (U) -> V) -> (T) -> V {
        CoreFP.compose(fn1, fn2)
    }
}

public func compose3<A, B, C, D>(
    _ ab: @escaping (A) -> B,
    _ bc: @escaping (B) -> C,
    _ cd: @escaping (C) -> D
) -> (A) -> D {
    { a in
        cd(bc(ab(a)))
    }
}

public func compose4<A, B, C, D, E>(
    _ ab: @escaping (A) -> B,
    _ bc: @escaping (B) -> C,
    _ cd: @escaping (C) -> D,
    _ de: @escaping (D) -> E
) -> (A) -> E {
    { a in
        de(cd(bc(ab(a))))
    }
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

public func call<A, B, C>(then transform: @escaping (B) -> C) -> (@escaping (A) -> B, A) -> C {
    uncurry(partialApplyFlip(compose, transform))
}
