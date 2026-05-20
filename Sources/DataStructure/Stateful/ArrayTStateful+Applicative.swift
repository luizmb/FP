import Foundation

// ArrayTStateful: outer = Array, inner = Stateful
// Type: [Stateful<S, A>]

/// apply for ArrayTStateful: [Stateful<S,(A->B)>] -> [Stateful<S,A>] -> [Stateful<S,B>]
public func applyArrayStateful<S, A, B>(
    _ fns: [Stateful<S, (A) -> B>],
    _ vals: [Stateful<S, A>]
) -> [Stateful<S, B>] {
    fns.flatMap { sf in vals.map { sa in Stateful<S, B>.apply(sf, sa) } }
}

/// liftA2 for ArrayTStateful
public func liftA2ArrayStateful<S, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> ([Stateful<S, A>], [Stateful<S, B>]) -> [Stateful<S, C>] {
    { arrA, arrB in
        arrA.flatMap { sa in arrB.map { sb in Stateful<S, C> { s in fn(sa.run(&s), sb.run(&s)) } } }
    }
}

/// seqRight for ArrayTStateful
public func seqRightArrayStateful<S, A, B>(
    _ lhs: [Stateful<S, A>],
    _ rhs: [Stateful<S, B>]
) -> [Stateful<S, B>] {
    lhs.flatMap { sa in rhs.map { sb in sa.seqRight(sb) } }
}

/// seqLeft for ArrayTStateful
public func seqLeftArrayStateful<S, A, B>(
    _ lhs: [Stateful<S, A>],
    _ rhs: [Stateful<S, B>]
) -> [Stateful<S, A>] {
    lhs.flatMap { sa in rhs.map { sb in sa.seqLeft(sb) } }
}
