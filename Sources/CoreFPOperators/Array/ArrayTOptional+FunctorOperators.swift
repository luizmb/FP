import CoreFP

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>

// (<£>) :: (a -> b) -> [a?] -> [b?]
public func <£> <A, B>(_ fn: @escaping (A) -> B, _ arr: [A?]) -> [B?] {
    arr.mapT(fn)
}

// (<&>) :: [a?] -> (a -> b) -> [b?]
public func <&> <A, B>(_ arr: [A?], _ fn: @escaping (A) -> B) -> [B?] {
    arr.mapT(fn)
}
