// SPDX-License-Identifier: Apache-2.0

// MARK: - Functor

public extension Zipper {
    /// Transform every element — structure and focus position preserved, contents changed.
    func map<B>(_ fn: (A) -> B) -> Zipper<B> {
        Zipper<B>(left: left.map(fn), focus: fn(focus), right: right.map(fn))
    }

    /// Curried, `@Sendable` form of `map`, matching this library's standard `fmap` shape.
    static func fmap<B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Zipper<A>) -> Zipper<B> {
        { $0.map(fn) }
    }
}

// MARK: - Free functions

/// `fmap` for `Zipper`.
public func fmap<A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ z: Zipper<A>
) -> Zipper<B> {
    z.map(fn)
}
