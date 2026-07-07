// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
import Foundation

// OptionalTArray: outer = Optional, inner = Array
// Type: [A]? = Optional<[A]>
// Haskell: ListT Maybe

public extension Optional {
    /// flatMapT for Optional<[A]>
    /// (>>=) :: [a]? -> (a -> [b]?) -> [b]?
    /// nil → nil
    /// .some(arr) → mapM fn arr (sequence the results, concatenating on success)
    func flatMapT<A, B>(_ fn: @escaping @Sendable (A) -> [B]?) -> [B]? where Wrapped == [A] {
        flatMap { arr in
            arr.map(fn).reduce(.some([])) { (acc: [B]?, next: [B]?) in
                acc.flatMap { combined in next.map { combined + $0 } }
            }
        }
    }

    /// Curried bindT for Optional<[A]>
    static func bindT<A, B>(_ fn: @escaping @Sendable (A) -> [B]?) -> ([A]?) -> [B]? {
        { opt in opt.flatMapT(fn) }
    }
}

/// Kleisli composition for `OptionalT + Array` (left-to-right)
/// (>=>) :: (a -> [b]?) -> (b -> [c]?) -> a -> [c]?
public func kleisliT<A, B, C>(
    _ fn1: @escaping @Sendable (A) -> [B]?,
    _ fn2: @escaping @Sendable (B) -> [C]?
) -> (A) -> [C]? {
    { a in fn1(a).flatMapT(fn2) }
}

// swiftlint:enable discouraged_optional_collection
