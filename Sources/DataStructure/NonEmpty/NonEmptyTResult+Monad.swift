// SPDX-License-Identifier: Apache-2.0
// NonEmptyTResult: outer = NonEmpty, inner = Result
// Type: NonEmpty<Result<A, E>>  (Success = A, Failure = E)

public extension NonEmpty {
    /// flatMapT for NonEmpty<Result<A, E>> — maps over success values, preserves failures.
    /// .failure → .failure
    /// .success(a) → fn(a)  (inner flatMap)
    func flatMapT<Inner, E, Output>(
        _ fn: (Inner) -> NonEmpty<Result<Output, E>>
    ) -> NonEmpty<Result<Output, E>> where A == Result<Inner, E> {
        let h: Result<Inner, E> = head
        let t: [Result<Inner, E>] = tail
        func step(_ element: Result<Inner, E>) -> NonEmpty<Result<Output, E>> {
            switch element {
            case let .failure(e):
                NonEmpty<Result<Output, E>>(head: .failure(e))

            case let .success(a):
                fn(a)
            }
        }
        let headResult = step(h)
        let tailResults = t.flatMap { step($0).toArray }
        return NonEmpty<Result<Output, E>>(head: headResult.head, tail: headResult.tail + tailResults)
    }

    /// The `property` property.
    static func bindT<Inner, E, Output>(
        _ fn: @escaping @Sendable (Inner) -> NonEmpty<Result<Output, E>>
    ) -> (NonEmpty<Result<Inner, E>>) -> NonEmpty<Result<Output, E>> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `NonEmptyTResult` (left-to-right)
/// (>=>) :: (a -> NonEmpty<Result<b,e>>) -> (b -> NonEmpty<Result<c,e>>) -> a -> NonEmpty<Result<c,e>>
public func kleisliT<A, B, C, E>(
    _ fn1: @escaping @Sendable (A) -> NonEmpty<Result<B, E>>,
    _ fn2: @escaping @Sendable (B) -> NonEmpty<Result<C, E>>
) -> (A) -> NonEmpty<Result<C, E>> {
    { a in fn1(a).flatMapT(fn2) }
}
