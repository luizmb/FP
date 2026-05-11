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

    public func callAsFunction(_ whole: S) -> A { get(whole) }

    /// The inverse iso — swaps `get` and `reverseGet`.
    public var reverse: Iso<A, S> {
        Iso<A, S>(get: reverseGet, reverseGet: get)
    }

    /// Apply a transform through the iso: convert to `A`, transform, convert back.
    public func over(_ transform: @escaping (A) -> A) -> (S) -> S {
        { s in reverseGet(transform(get(s))) }
    }

    /// Lifts an `EndoMut<A>` into an `EndoMut<S>` through this iso.
    ///
    /// Converts `S → A`, applies the mutation to `inout A`, then replaces `S`
    /// with `reverseGet(a)` — all via `inout S`, so no CoW copy occurs on `S`.
    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in
            var part = get(s)
            f(&part)
            s = reverseGet(part)
        }
    }

    /// View this iso as a `Lens`.
    ///
    /// Uses `init(get:setMut:)` so that `modifyMut` keeps `S` as `inout`
    /// throughout — no CoW copy on `S` during write-back.
    public var asLens: Lens<S, A> {
        Lens(get: get, setMut: { s, a in s = reverseGet(a) })
    }

    /// View this iso as a `Prism`. Preview always succeeds; review uses `reverseGet`.
    ///
    /// Supplies an explicit `tryModifyMut` that skips the always-succeeding
    /// `guard` in the synthesised form and keeps `S` as `inout`.
    public var asPrism: Prism<S, A> {
        Prism(
            preview: { .some(get($0)) },
            review: reverseGet,
            tryModifyMut: { s, f in var part = get(s); f(&part); s = reverseGet(part) }
        )
    }

    /// View this iso as an `AffineTraversal`.
    ///
    /// Uses `init(preview:setMut:)` so that `tryModifyMut` keeps `S` as `inout`
    /// throughout — no CoW copy on `S` during write-back.
    public var asAffineTraversal: AffineTraversal<S, A> {
        AffineTraversal(preview: { .some(get($0)) }, setMut: { s, a in s = reverseGet(a) })
    }
}

extension Iso where S == A {
    /// The identity `Iso`: both directions are the identity function.
    /// This is the strongest identity optic; use `.asLens`, `.asPrism`, or `.asAffineTraversal`
    /// to obtain weaker forms.
    public static var id: Iso<S, S> {
        Iso(get: { $0 }, reverseGet: { $0 })
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
