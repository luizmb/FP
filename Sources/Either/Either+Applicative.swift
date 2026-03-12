import FP
import Foundation

public extension Either {
    // liftA2 :: (b1 -> b2 -> b) -> Either a b1 -> Either a b2 -> Either a b
    static func liftA2<B1, B2>(_ fn: @escaping (B1, B2) -> B) -> (
        Either<A, B1>, Either<A, B2>
    ) -> Either<A, B> {
        { eitherA, eitherB in
            .specialRightRight(lhs: eitherA, rhs: eitherB, handling: fn)
        }
    }

    fileprivate struct UnexpectedLeftError<L: Sendable>: Error {
        let left: L
    }

    static func zip<B1, B2, each Bx>(
        _ first: Either<A, B1>,
        _ second: Either<A, B2>,
        _ additional: repeat Either<A, (each Bx)>
    ) -> Either<A, B>
    where B == (B1, B2, repeat each Bx), A: Sendable {
        func pickRight<L, R>(_ either: Either<L, R>) -> Result<R, UnexpectedLeftError<L>> {
            switch either {
            case let .left(left): .failure(UnexpectedLeftError(left: left))
            case let .right(right): .success(right)
            }
        }

        do {
            return Either.right((
                try pickRight(first).get(),
                try pickRight(second).get(),
                repeat try pickRight(each additional).get()
            ))
        } catch {
            return Either.left(error.left)
        }
    }

    static func specialRightRight<Ba, Bb>(
        lhs: Either<A, Ba>,
        rhs: Either<A, Bb>,
        handling: @escaping (Ba, Bb) -> B
    ) -> Either<A, B> {
        .match(
            lhs, rhs,
            caseLeftLeft: withArg(\.0)(Either.left),
            caseLeftRight: withArg(\.0)(Either.left),
            caseRightLeft: withArg(\.1)(Either.left),
            caseRightRight: untuple(compose(handling, Either.right))
        )
    }
}
