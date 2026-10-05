// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
import Foundation

// OptionalTArray: outer = Optional, inner = Array
// Type: [A]? = Optional<[A]>
// Haskell: ListT Maybe

extension Optional {
    /// flatMapT for Optional<[A]>
    /// (>>=) :: [a]? -> (a -> [b]?) -> [b]?
    /// nil → nil
    /// .some(arr) → mapM fn arr (sequence the results, concatenating on success)
    ///
    /// O(total output): appends into one buffer and stops calling `fn` at the first `nil`.
    func flatMapT<A, B>(_ fn: @escaping @Sendable (A) -> [B]?) -> [B]? where Wrapped == [A] {
        flatMap { arr in
            var result: [B] = []
            for element in arr {
                guard let chunk = fn(element) else { return nil }
                result.append(contentsOf: chunk)
            }
            return result
        }
    }

    /// Curried bindT for Optional<[A]>
    static func bindT<A, B>(_ fn: @escaping @Sendable (A) -> [B]?) -> @Sendable ([A]?) -> [B]? {
        { opt in opt.flatMapT(fn) }
    }
}

/// Kleisli composition for `OptionalT + Array` (left-to-right)
/// (>=>) :: (a -> [b]?) -> (b -> [c]?) -> a -> [c]?
func kleisliT<A, B, C>(
    _ fn1: @escaping @Sendable (A) -> [B]?,
    _ fn2: @escaping @Sendable (B) -> [C]?
) -> @Sendable (A) -> [C]? {
    { a in fn1(a).flatMapT(fn2) }
}

// swiftlint:enable discouraged_optional_collection
