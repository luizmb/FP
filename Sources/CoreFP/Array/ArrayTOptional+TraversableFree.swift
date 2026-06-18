// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
/// Sequence a list of optionals
/// sequence :: [a?] -> [a]?
public func sequence<A>(_ optionals: [A?]) -> [A]? {
    optionals.traverse(CoreFP.id)
}

/// Map and sequence
/// traverse :: (a -> b?) -> [a] -> [b]?
public func traverse<A, B>(_ fn: @escaping @Sendable (A) -> B?) -> ([A]) -> [B]? {
    { array in
        array.traverse(fn)
    }
}

// swiftlint:enable discouraged_optional_collection
