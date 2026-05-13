/// A bidirectional, lossless conversion between `S` and `A`.
///
/// An `Iso<S, A>` captures a total bijection: `get` converts `S → A` and
/// `reverseGet` converts `A → S`, and the two are mutual inverses.
///
/// Every `Iso` is also a valid `Lens`, `Prism`, and `AffineTraversal`, and can be
/// composed freely with all of them via `>>>` / `<<<`.
public struct Iso<S, A>: Sendable {
    public let get: @Sendable (S) -> A
    public let reverseGet: @Sendable (A) -> S

    public init(get: @escaping @Sendable (S) -> A, reverseGet: @escaping @Sendable (A) -> S) {
        self.get = get
        self.reverseGet = reverseGet
    }

    public func callAsFunction(_ whole: S) -> A { get(whole) }

    /// The inverse iso — swaps `get` and `reverseGet`.
    public var reverse: Iso<A, S> {
        Iso<A, S>(get: reverseGet, reverseGet: get)
    }

    /// Apply a transform through the iso: convert to `A`, transform, convert back.
    public func over(_ transform: @escaping @Sendable (A) -> A) -> @Sendable (S) -> S {
        { s in reverseGet(transform(get(s))) }
    }

    /// Lifts an `EndoMut<A>` into an `EndoMut<S>` through this iso.
    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in
            var part = get(s)
            f(&part)
            s = reverseGet(part)
        }
    }

    /// View this iso as a `Lens` using `init(get:setMut:)` — no CoW on `S`.
    public var asLens: Lens<S, A> {
        Lens(get: get, setMut: { s, a in s = reverseGet(a) })
    }

    /// View this iso as a `Prism` with an explicit `tryModifyMut` — no CoW on `S`.
    public var asPrism: Prism<S, A> {
        Prism(
            preview: { .some(get($0)) },
            review: reverseGet,
            tryModifyMut: { s, f in var part = get(s); f(&part); s = reverseGet(part) }
        )
    }

    /// View this iso as an `AffineTraversal` using `init(preview:setMut:)` — no CoW on `S`.
    public var asAffineTraversal: AffineTraversal<S, A> {
        AffineTraversal(preview: { .some(get($0)) }, setMut: { s, a in s = reverseGet(a) })
    }
}

extension Iso where S == A {
    public static var id: Iso<S, S> {
        Iso(get: { $0 }, reverseGet: { $0 })
    }
}

/// Builds an `Iso` from explicit forward and reverse functions.
public func iso<S, A>(get: @escaping @Sendable (S) -> A, reverseGet: @escaping @Sendable (A) -> S) -> Iso<S, A> {
    Iso(get: get, reverseGet: reverseGet)
}
