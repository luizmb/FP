import Foundation

// EitherTStateful: outer = Either, inner = Stateful
// Type: Either<L, Stateful<S, A>>

public extension Either {
    func mapT<S, Inner, C>(_ fn: @escaping @Sendable (Inner) -> C) -> Either<A, Stateful<S, C>>
    where B == Stateful<S, Inner> {
        mapRight { stateful in stateful.map(fn) }
    }

    static func fmapT<S, Inner, C>(
        _ fn: @escaping @Sendable (Inner) -> C
    ) -> @Sendable (Either<A, Stateful<S, Inner>>) -> Either<A, Stateful<S, C>> {
        { either in either.mapT(fn) }
    }
}
