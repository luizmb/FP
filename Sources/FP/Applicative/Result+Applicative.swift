import Foundation

public extension Result {
    // liftA2 :: (b1 -> b2 -> b) -> Either a b1 -> Either a b2 -> Either a b
    static func liftA2<A1, A2>(_ fn: @escaping (A1, A2) -> A) -> (
        Result<A1, B>, Result<A2, B>
    ) -> Result<A, B> {
        { resultA, resultB in
            .specialLeftLeft(lhs: resultA, rhs: resultB, handling: fn)
        }
    }

    static func zip<A1, A2, each Ax>(
        _ first: Result<A1, B>,
        _ second: Result<A2, B>,
        _ additional: repeat Result<(each Ax), B>
    ) -> Result<A, B>
    where A == (A1, A2, repeat each Ax) {
        func unwrap<T, E: Error>(_ t: Result<T, E>) throws(E) -> T {
            try t.get()
        }

        do {
            return try Result.success((
                unwrap(first),
                unwrap(second),
                repeat unwrap(each additional)
            ))
        } catch {
            return Result.failure(error)
        }
    }
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
