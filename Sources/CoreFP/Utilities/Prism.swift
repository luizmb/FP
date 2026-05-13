// MARK: - Prism<S, A>
//
// A `Prism` focuses on zero or one value of type `A` inside `S` — typically
// one case of an enum. `preview` extracts the focused value if present;
// `review` reconstructs `S` from `A`.
//
// ## In-place mutation and enums
//
// Swift has no mechanism for `inout` access to an enum's associated value
// directly (there is no modify coroutine for enum cases). `tryModifyMut`
// therefore always copies `A` out, passes `inout A` to the closure, then
// reconstructs `S` via `review`. The outer `S` is kept `inout` throughout,
// so no CoW copy occurs on `S` itself — only the enum case value is copied.
//
// This is the best achievable in safe Swift. In a chain like
// `stateLens >>> routePrism >>> itemsLens`, the prism is the only link that
// copies; the lenses on either side remain zero-copy.
//
// ## lift and tryModifyMut
//
// `lift` packages `tryModifyMut` as an `EndoMut<S>`. When the focus is absent
// the resulting `EndoMut` is a no-op and `S` is left unchanged.
//
// ## compose — operator-free composition
//
// `compose` is the named-function backing for the `>>>` operator.

public struct Prism<S, A>: Sendable {
    public let preview: @Sendable (S) -> A?
    public let review: @Sendable (A) -> S
    public let tryModifyMut: @Sendable (inout S, (inout A) -> Void) -> Void

    /// Standard 2-closure init. `tryModifyMut` is synthesised from
    /// `preview`+`review`: copies `A` once, keeps `S` as `inout`.
    public init(preview: @escaping @Sendable (S) -> A?, review: @escaping @Sendable (A) -> S) {
        self.preview = preview
        self.review = review
        self.tryModifyMut = { s, f in
            guard var part = preview(s) else { return }
            f(&part)
            s = review(part)
        }
    }

    /// Full init for callers that can supply an explicit `tryModifyMut`.
    public init(
        preview: @escaping @Sendable (S) -> A?,
        review: @escaping @Sendable (A) -> S,
        tryModifyMut: @escaping @Sendable (inout S, (inout A) -> Void) -> Void
    ) {
        self.preview = preview
        self.review = review
        self.tryModifyMut = tryModifyMut
    }

    public func callAsFunction(_ whole: S) -> A? { preview(whole) }

    /// Applies a pure transform if the focus is present; returns a new `S`.
    /// Prefer `lift(_:)` when working with `EndoMut` and large CoW states.
    public func over(_ transform: @escaping @Sendable (A) -> A) -> @Sendable (S) -> S {
        { s in preview(s).map { review(transform($0)) } ?? s }
    }

    /// Replaces the focused value if present; no-op otherwise.
    public func set(_ s: S, _ a: A) -> S {
        preview(s).map { _ in review(a) } ?? s
    }

    /// Lifts an `EndoMut<A>` into an `EndoMut<S>` focused through this prism.
    /// When the focus is absent the resulting `EndoMut` is a no-op.
    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in tryModifyMut(&s) { a in f(&a) } }
    }
}

extension Prism where S == A {
    public static var id: Prism<S, S> {
        Prism(preview: { .some($0) }, review: { $0 }, tryModifyMut: { s, f in f(&s) })
    }
}

/// Builds a `Prism` from an optional-returning `KeyPath` and a `review` function.
public func prism<S: Sendable, A: Sendable>(_ keyPath: KeyPath<S, A?>, review: @escaping @Sendable (A) -> S) -> Prism<S, A> {
    Prism(preview: { @Sendable s in s[keyPath: keyPath] }, review: review)
}

/// Builds a `Prism` from explicit `preview` and `review` functions.
public func prism<S, A>(preview: @escaping @Sendable (S) -> A?, review: @escaping @Sendable (A) -> S) -> Prism<S, A> {
    Prism(preview: preview, review: review)
}
