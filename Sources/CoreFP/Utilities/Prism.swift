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

public struct Prism<S, A>: @unchecked Sendable {
    public let preview: (S) -> A?
    public let review: (A) -> S

    /// Applies `f` to the focused value if present, then reconstructs `S`
    /// via `review`. No-op when the focus is absent.
    ///
    /// Copies the enum case value (`A`) once. The outer `S` is `inout`
    /// throughout — no CoW copy occurs on `S` itself.
    public let tryModifyMut: (inout S, (inout A) -> Void) -> Void

    /// Standard 2-closure init. `tryModifyMut` is synthesised from
    /// `preview`+`review`: copies `A` once, keeps `S` as `inout`.
    public init(preview: @escaping (S) -> A?, review: @escaping (A) -> S) {
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
        preview: @escaping (S) -> A?,
        review: @escaping (A) -> S,
        tryModifyMut: @escaping (inout S, (inout A) -> Void) -> Void
    ) {
        self.preview = preview
        self.review = review
        self.tryModifyMut = tryModifyMut
    }

    public func callAsFunction(_ whole: S) -> A? { preview(whole) }

    /// Applies a pure transform if the focus is present; returns a new `S`.
    /// Prefer `lift(_:)` when working with `EndoMut` and large CoW states.
    public func over(_ transform: @escaping (A) -> A) -> (S) -> S {
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

/// Builds a `Prism` from an optional-returning `KeyPath` (the preview) and a `review` function.
///
/// ```swift
/// enum Shape { case circle(Double), rectangle(Double, Double) }
///
/// let circlePrism: Prism<Shape, Double> = prism(\.circleRadius, review: Shape.circle)
/// ```
public func prism<S, A>(_ keyPath: KeyPath<S, A?>, review: @escaping (A) -> S) -> Prism<S, A> {
    Prism(preview: { $0[keyPath: keyPath] }, review: review)
}

/// Builds a `Prism` from explicit `preview` and `review` functions.
public func prism<S, A>(preview: @escaping (S) -> A?, review: @escaping (A) -> S) -> Prism<S, A> {
    Prism(preview: preview, review: review)
}
