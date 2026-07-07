// SPDX-License-Identifier: Apache-2.0

// MARK: - Comonad

public extension Zipper {
    /// extract :: Zipper A -> A
    /// The value currently under focus.
    var extract: A { focus }

    /// duplicate :: Zipper A -> Zipper (Zipper A)
    /// The focus becomes `self`; ``left`` holds every zipper reachable by repeatedly
    /// calling ``moveLeft()`` (closest-to-`self` first); ``right`` holds every zipper
    /// reachable by repeatedly calling ``moveRight()`` (closest-to-`self` first).
    func duplicate() -> Zipper<Zipper<A>> {
        var lefts: [Zipper<A>] = []
        var cursor = self
        while let previous = cursor.moveLeft() {
            lefts.append(previous)
            cursor = previous
        }

        var rights: [Zipper<A>] = []
        cursor = self
        while let next = cursor.moveRight() {
            rights.append(next)
            cursor = next
        }

        return Zipper<Zipper<A>>(left: lefts, focus: self, right: rights)
    }

    /// extend :: (Zipper A -> B) -> Zipper A -> Zipper B
    func extend<B>(_ fn: (Zipper<A>) -> B) -> Zipper<B> {
        duplicate().map(fn)
    }

    /// coflatMap is extend with the more familiar (value-first) name.
    func coflatMap<B>(_ fn: (Zipper<A>) -> B) -> Zipper<B> {
        extend(fn)
    }

    /// Curried static form for point-free use.
    static func extend<B>(
        _ fn: @escaping @Sendable (Zipper<A>) -> B
    ) -> (Zipper<A>) -> Zipper<B> {
        { $0.extend(fn) }
    }
}

/// extract :: Zipper A -> A
public func extract<A>(_ z: Zipper<A>) -> A {
    z.extract
}

/// extend :: (Zipper A -> B) -> Zipper A -> Zipper B
public func extend<A, B>(
    _ fn: @escaping @Sendable (Zipper<A>) -> B
) -> (Zipper<A>) -> Zipper<B> {
    { $0.extend(fn) }
}

/// duplicate :: Zipper A -> Zipper (Zipper A)
public func duplicate<A>(_ z: Zipper<A>) -> Zipper<Zipper<A>> {
    z.duplicate()
}
