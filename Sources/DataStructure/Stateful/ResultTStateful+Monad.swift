import Foundation

// ResultTStateful: outer = Result, inner = Stateful
// Type: Result<Stateful<S, A>, E> = Result wrapping a Stateful computation
//
// flatMapT sequences computations structurally: .failure propagates;
// .success(stateful) composes via flatMap.

public extension Result {
    /// flatMapT :: Result<Stateful<s, a>, e> -> (a -> Stateful<s, b>) -> Result<Stateful<s, b>, e>
    /// .failure(e)       → .failure(e)
    /// .success(stateful) → .success(stateful.flatMap(fn))
    func flatMapT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> Result<Stateful<S, B>, Failure>
    where Success == Stateful<S, A> {
        map { stateful in stateful.flatMap(fn) }
    }

    static func bindT<S, A, B>(
        _ fn: @escaping @Sendable (A) -> Stateful<S, B>
    ) -> (Result<Stateful<S, A>, Failure>) -> Result<Stateful<S, B>, Failure> {
        { result in result.flatMapT(fn) }
    }
}
