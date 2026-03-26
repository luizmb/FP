/// A bidirectional, lossless conversion between `S` and `A`.
///
/// An `Iso<S, A>` captures a total bijection: `get` converts `S → A` and
/// `reverseGet` converts `A → S`, and the two are mutual inverses:
///
/// ```swift
/// iso.reverseGet(iso.get(s)) == s   // round-trip from S
/// iso.get(iso.reverseGet(a)) == a   // round-trip from A
/// ```
///
/// Every `Iso` is also a valid `Lens`, `Prism`, and `AffineTraversal`, and can be
/// composed freely with all of them via `>>>` / `<<<`.
public struct Iso<S, A>: @unchecked Sendable {
    public let get: (S) -> A
    public let reverseGet: (A) -> S

    public init(get: @escaping (S) -> A, reverseGet: @escaping (A) -> S) {
        self.get = get
        self.reverseGet = reverseGet
    }

    /// The inverse iso — swaps `get` and `reverseGet`.
    public var reverse: Iso<A, S> {
        Iso<A, S>(get: reverseGet, reverseGet: get)
    }

    /// Apply a transform through the iso: convert to `A`, transform, convert back.
    public func over(_ transform: @escaping (A) -> A) -> (S) -> S {
        { s in reverseGet(transform(get(s))) }
    }

    /// View this iso as a `Lens`. The setter ignores the original `S` and uses `reverseGet`.
    public var asLens: Lens<S, A> {
        Lens(get: get, set: { _, a in reverseGet(a) })
    }

    /// View this iso as a `Prism`. Preview always succeeds; review uses `reverseGet`.
    public var asPrism: Prism<S, A> {
        Prism(preview: { .some(get($0)) }, review: reverseGet)
    }

    /// View this iso as an `AffineTraversal`.
    public var asAffineTraversal: AffineTraversal<S, A> {
        AffineTraversal(preview: { .some(get($0)) }, set: { _, a in reverseGet(a) })
    }
}

/// Builds an `Iso` from explicit forward and reverse functions.
///
/// ```swift
/// let addOne = iso(get: { $0 + 1 }, reverseGet: { $0 - 1 })
/// addOne.get(5)            // 6
/// addOne.reverseGet(6)     // 5
/// addOne.reverse.get(6)    // 5
/// ```
public func iso<S, A>(get: @escaping (S) -> A, reverseGet: @escaping (A) -> S) -> Iso<S, A> {
    Iso(get: get, reverseGet: reverseGet)
}
