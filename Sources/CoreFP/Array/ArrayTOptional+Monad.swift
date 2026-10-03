// SPDX-License-Identifier: Apache-2.0
import Foundation

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>
// Haskell: MaybeT []

public extension Array {
    /// flatMapT for [A?]
    /// (>>=) :: [a?] -> (a -> [b?]) -> [b?]
    /// For each element: nil → [nil], .some(a) → fn(a)
    func flatMapT<A, B>(_ fn: @escaping @Sendable (A) -> [B?]) -> [B?] where Element == A? {
        bindArrayOptional(self, fn)
    }

    /// Curried bindT for [A?]
    static func bindT<A, B>(_ fn: @escaping @Sendable (A) -> [B?]) -> @Sendable ([A?]) -> [B?] {
        { arr in arr.flatMapT(fn) }
    }
}

/// The `MaybeT []` bind, shared by ``Array/flatMapT(_:)`` and the applicative surface
/// (`applyArrayOptional`, `liftA2ArrayOptional`, `seqRightArrayOptional`, `seqLeftArrayOptional`),
/// so `<*>` = `ap` holds by construction. Non-escaping, so callers may capture non-`Sendable` values.
/// nil → [nil], .some(a) → fn(a)
func bindArrayOptional<A, B>(_ arr: [A?], _ fn: (A) -> [B?]) -> [B?] {
    arr.flatMap { optA in optA.map(fn) ?? [.none] }
}

/// Kleisli composition for `ArrayT + Optional` (left-to-right)
/// (>=>) :: (a -> [b?]) -> (b -> [c?]) -> a -> [c?]
public func kleisliT<A, B, C>(
    _ fn1: @escaping @Sendable (A) -> [B?],
    _ fn2: @escaping @Sendable (B) -> [C?]
) -> @Sendable (A) -> [C?] {
    { a in fn1(a).flatMapT(fn2) }
}
