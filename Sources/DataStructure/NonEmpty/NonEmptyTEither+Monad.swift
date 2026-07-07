// SPDX-License-Identifier: Apache-2.0
// NonEmptyTEither: outer = NonEmpty, inner = Either
// Type: NonEmpty<Either<L, A>>

public extension NonEmpty {
    /// flatMapT for NonEmpty<Either<L, A>> — Right values expand via fn, Lefts propagate.
    /// .left(l)    → NonEmpty<Either<L, B>>(head: .left(l))
    /// .right(a)   → fn(a)  (inner bind)
    func flatMapT<L, Inner, B>(
        _ fn: (Inner) -> NonEmpty<Either<L, B>>
    ) -> NonEmpty<Either<L, B>> where A == Either<L, Inner> {
        let h: Either<L, Inner> = head
        let t: [Either<L, Inner>] = tail
        func step(_ element: Either<L, Inner>) -> NonEmpty<Either<L, B>> {
            switch element {
            case let .left(l):
                NonEmpty<Either<L, B>>(head: .left(l))

            case let .right(a):
                fn(a)
            }
        }
        let headResult = step(h)
        let tailResults = t.flatMap { step($0).toArray }
        return NonEmpty<Either<L, B>>(head: headResult.head, tail: headResult.tail + tailResults)
    }

    /// The `property` property.
    static func bindT<L, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> NonEmpty<Either<L, B>>
    ) -> (NonEmpty<Either<L, Inner>>) -> NonEmpty<Either<L, B>> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `NonEmptyT + Either` (left-to-right)
/// (>=>) :: (a0 -> NonEmpty<Either<l, a>>) -> (a -> NonEmpty<Either<l, b>>) -> a0 -> NonEmpty<Either<l, b>>
public func kleisliT<L, A0, A, B>(
    _ fn1: @escaping @Sendable (A0) -> NonEmpty<Either<L, A>>,
    _ fn2: @escaping @Sendable (A) -> NonEmpty<Either<L, B>>
) -> (A0) -> NonEmpty<Either<L, B>> {
    { a0 in fn1(a0).flatMapT(fn2) }
}
