// MARK: - AffineTraversal<S, A>
//
// An `AffineTraversal` focuses on zero or one value of type `A` inside `S`.
// It is the result of composing a `Lens` with a `Prism` (in either order):
// the whole `S` is always present (Lens property), but the focus may be absent
// (Prism property).
//
// ## In-place mutation
//
// `tryModifyMut` applies a mutation to the focused `A` in place, keeping
// `S` as `inout` throughout. When absent, it is a no-op.
//
// ## lift and compose
//
// `lift` turns an `EndoMut<A>` into an `EndoMut<S>`. When the focus is absent
// the result is a no-op.
//
// `compose` is the named-function backing for the `>>>` operator, available
// without importing `CoreFPOperators`.

public struct AffineTraversal<S, A>: Sendable {
    public let preview: @Sendable (S) -> A?
    public let set: @Sendable (S, A) -> S
    public let tryModifyMut: @Sendable (inout S, (inout A) -> Void) -> Void

    /// Standard 2-closure init. `tryModifyMut` is synthesised from
    /// `preview`+`set`: copies `A` once, keeps `S` as `inout`.
    public init(preview: @escaping @Sendable (S) -> A?, set: @escaping @Sendable (S, A) -> S) {
        self.preview = preview
        self.set = set
        self.tryModifyMut = { s, f in
            guard var part = preview(s) else { return }
            f(&part)
            s = set(s, part)
        }
    }

    /// Full init for callers that can supply a more efficient `tryModifyMut`.
    public init(
        preview: @escaping @Sendable (S) -> A?,
        set: @escaping @Sendable (S, A) -> S,
        tryModifyMut: @escaping @Sendable (inout S, (inout A) -> Void) -> Void
    ) {
        self.preview = preview
        self.set = set
        self.tryModifyMut = tryModifyMut
    }

    /// Inout-setter init. `tryModifyMut` keeps `S` as `inout` — no CoW on `S`.
    public init(preview: @escaping @Sendable (S) -> A?, setMut: @escaping @Sendable (inout S, A) -> Void) {
        self.preview = preview
        self.set = { s, a in
            guard preview(s) != nil else { return s }
            var c = s; setMut(&c, a); return c
        }
        self.tryModifyMut = { s, f in
            guard var part = preview(s) else { return }
            f(&part)
            setMut(&s, part)
        }
    }

    public func callAsFunction(_ whole: S) -> A? { preview(whole) }

    public func over(_ transform: @escaping @Sendable (A) -> A) -> @Sendable (S) -> S {
        { s in preview(s).map { set(s, transform($0)) } ?? s }
    }

    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in tryModifyMut(&s) { a in f(&a) } }
    }
}

extension AffineTraversal where S == A {
    public static var id: AffineTraversal<S, S> {
        AffineTraversal(preview: { .some($0) }, set: { _, a in a }, tryModifyMut: { s, f in f(&s) })
    }
}

/// Lifts a `WritableKeyPath` to an optional property into an `AffineTraversal`.
public func affineTraversal<S: Sendable, A: Sendable>(_ keyPath: WritableKeyPath<S, A?>) -> AffineTraversal<S, A> {
    AffineTraversal(
        preview: { @Sendable s in s[keyPath: keyPath] },
        set: { @Sendable s, a in var c = s; c[keyPath: keyPath] = a; return c },
        tryModifyMut: { @Sendable s, f in
            guard var value = s[keyPath: keyPath] else { return }
            f(&value)
            s[keyPath: keyPath] = value
        }
    )
}
