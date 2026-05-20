import Foundation

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>

/// apply for ArrayTOptional: [(A->B)?] -> [A?] -> [B?]
/// Cartesian product with Optional apply at each pair
public func applyArrayOptional<A, B>(_ fns: [((A) -> B)?], _ values: [A?]) -> [B?] {
    fns.flatMap { f in values.map { a in f.flatMap { fn in a.map(fn) } } }
}

/// liftA2 for ArrayTOptional: (A,B)->C -> [A?] -> [B?] -> [C?]
public func liftA2ArrayOptional<A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> ([A?], [B?]) -> [C?] {
    { arrA, arrB in
        Array.liftA2({ @Sendable a, b in Optional.liftA2(fn)(a, b) })(arrA, arrB)
    }
}

/// seqRight for ArrayTOptional: [A?] -> [B?] -> [B?]
/// Cartesian product keeping right values (threading Optional through)
public func seqRightArrayOptional<A, B>(_ lhs: [A?], _ rhs: [B?]) -> [B?] {
    Array.liftA2({ (a: A?, b: B?) in a.seqRight(b) })(lhs, rhs)
}

/// seqLeft for ArrayTOptional: [A?] -> [B?] -> [A?]
public func seqLeftArrayOptional<A, B>(_ lhs: [A?], _ rhs: [B?]) -> [A?] {
    Array.liftA2({ (a: A?, b: B?) in a.seqLeft(b) })(lhs, rhs)
}
