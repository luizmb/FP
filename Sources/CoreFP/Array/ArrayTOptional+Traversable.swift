// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
public extension Array {
    /// traverse :: (a -> b?) -> [a] -> [b]?
    /// traverse _ []     = Just []
    /// traverse f (x:xs) = liftA2 (:) (f x) (traverse f xs)
    func traverse<B>(_ f: (Element) -> B?) -> [B]? {
        reduce(.some([])) { acc, x in
            acc.flatMap { arr in f(x).map { arr + [$0] } }
        }
    }

    /// sequence :: [a?] -> [a]?
    /// sequence = traverse id
    func sequence<A>() -> [A]? where Element == A? {
        traverse(CoreFP.id)
    }
}
// swiftlint:enable discouraged_optional_collection
