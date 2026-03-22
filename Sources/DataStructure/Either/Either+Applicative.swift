import Core
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

    /// apply :: Either<a, (b0 -> b)> -> Either<a, b0> -> Either<a, b>
    static func apply<B0>(_ functions: Either<A, (B0) -> B>, _ values: Either<A, B0>) -> Either<A, B> {
        functions.flatMap(values.mapRight)
    }

    /// seqRight :: Either<a, b> -> Either<a, c> -> Either<a, c>
    /// Run both, discard the left result, return the right
    func seqRight<C>(_ rhs: Either<A, C>) -> Either<A, C> {
        flatMap(const(rhs))
    }

    /// seqLeft :: Either<a, b> -> Either<a, c> -> Either<a, b>
    /// Run both, return the left result
    func seqLeft<C>(_ rhs: Either<A, C>) -> Either<A, B> {
        flatMap { b in rhs.mapRight(const(b)) }
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

    private static func specialRightRight<Ba, Bb>(
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
