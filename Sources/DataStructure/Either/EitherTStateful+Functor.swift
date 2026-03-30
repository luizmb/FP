import Foundation

// EitherTStateful: outer = Either, inner = Stateful
// Type: Either<L, Stateful<S, A>>

public extension Either {
    func mapT<S, Inner, C>(_ fn: @escaping (Inner) -> C) -> Either<A, Stateful<S, C>>
    where B == Stateful<S, Inner> {
        mapRight { stateful in stateful.fmap(fn) }
    }

    static func fmapT<S, Inner, C>(
        _ fn: @escaping (Inner) -> C
    ) -> (Either<A, Stateful<S, Inner>>) -> Either<A, Stateful<S, C>> {
        { either in either.mapT(fn) }
    }
}
