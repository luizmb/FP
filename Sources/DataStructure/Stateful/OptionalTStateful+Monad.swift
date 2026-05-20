import Foundation

// OptionalTStateful: outer = Optional, inner = Stateful
// Type: Stateful<S, A>? = Optional<Stateful<S, A>>
//
// Note: unlike OptionalTResult, the inner type is a function (inout S) -> A.
// We cannot inspect its output without a concrete state, so flatMapT sequences
// computations structurally: nil propagates; some(stateful) composes via flatMap.

public extension Optional {
    /// flatMapT :: Stateful<s, a>? -> (a -> Stateful<s, b>) -> Stateful<s, b>?
    /// nil             → nil
    /// some(stateful)  → some(stateful.flatMap(fn))
    func flatMapT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> Stateful<S, B>?
    where Wrapped == Stateful<S, A> {
        map { stateful in stateful.flatMap(fn) }
    }

    static func bindT<S, A, B>(_ fn: @escaping @Sendable (A) -> Stateful<S, B>) -> @Sendable (Stateful<S, A>?) -> Stateful<S, B>? {
        { opt in opt.flatMapT(fn) }
    }
}
