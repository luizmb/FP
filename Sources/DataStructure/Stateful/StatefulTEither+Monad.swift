import Foundation

public extension Stateful {
    // StatefulT + Either — Stateful<S, Either<L, A>>
    //
    // Note: Either.flatMap is @escaping, so we pattern-match directly to avoid
    // the "inout parameter captured by escaping closure" error.

    func flatMapT<L, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Either<L, B>>
    ) -> Stateful<S, Either<L, B>> where A == Either<L, Inner> {
        Stateful<S, Either<L, B>> { s in
            switch self.run(&s) {
            case .left(let l): .left(l)
            case .right(let a): fn(a).run(&s)
            }
        }
    }

    static func bindT<L, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, Either<L, B>>
    ) -> (Stateful<S, Either<L, Inner>>) -> Stateful<S, Either<L, B>>
    where A == Either<L, Inner> {
        { $0.flatMapT(fn) }
    }
}
