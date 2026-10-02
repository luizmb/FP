// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
public extension Array {
    /// traverse :: (a -> b?) -> [a] -> [b]?
    /// traverse _ []     = Just []
    /// traverse f (x:xs) = liftA2 (:) (f x) (traverse f xs)
    ///
    /// O(n): appends into one buffer and stops calling `f` at the first `nil`.
    func traverse<B>(_ f: (Element) -> B?) -> [B]? {
        var result: [B] = []
        result.reserveCapacity(count)
        for element in self {
            guard let b = f(element) else { return nil }
            result.append(b)
        }
        return result
    }

    /// sequence :: [a?] -> [a]?
    /// sequence = traverse id
    func sequence<A>() -> [A]? where Element == A? {
        traverse(CoreFP.id)
    }
}

// swiftlint:enable discouraged_optional_collection
