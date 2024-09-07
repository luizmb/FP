import FP
import Foundation

// (<*>) :: Either a (b0 -> b) -> Either a b0 -> Either a b
public func <*> <A, A0, B>(_ lhs: Result<(A0) -> A, B>, _ rhs: Result<A0, B>) -> Result<A, B> {
    .specialLeftLeft(lhs: lhs, rhs: rhs, handling: call)
}

// (*>) :: Either a ignore -> Either a b -> Either a b
public func *> <A, Ignore, B>(_ lhs: Result<Ignore, B>, _ rhs: Result<A, B>) -> Result<A, B> {
    .specialLeftLeft(lhs: lhs, rhs: rhs, handling: untuple(\.1))
}

// (<*) :: Either a b -> Either a ignore -> Either a b
public func <* <A, B, Ignore>(_ lhs: Result<A, B>, _ rhs: Result<Ignore, B>) -> Result<A, B> {
    rhs *> lhs
}

extension Result {
    fileprivate static func specialLeftLeft<Aa, Ab>(
        lhs: Result<Aa, B>, 
        rhs: Result<Ab, B>,
        handling: @escaping (Aa, Ab) -> A
    ) -> Result<A, B> {
        .match(
            lhs, rhs,
            caseLeftLeft: untuple(compose(handling, Result.left)),
            caseLeftRight: withArg(\.1)(Result.right),
            caseRightLeft: withArg(\.0)(Result.right),
            caseRightRight: withArg(\.0)(Result.right)
        )
    }
}
