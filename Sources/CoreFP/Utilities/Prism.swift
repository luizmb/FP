public struct Prism<S, A>: @unchecked Sendable {
    public let preview: (S) -> A?
    public let review: (A) -> S

    public init(preview: @escaping (S) -> A?, review: @escaping (A) -> S) {
        self.preview = preview
        self.review = review
    }

    public func over(_ transform: @escaping (A) -> A) -> (S) -> S {
        { s in preview(s).map { review(transform($0)) } ?? s }
    }

    /// Replaces the focused value if the receiver matches this case; no-op otherwise.
    public func set(_ s: S, _ a: A) -> S {
        preview(s).map { _ in review(a) } ?? s
    }
}

extension Prism where S == A {
    /// The identity `Prism`: preview always succeeds, review is the identity function.
    public static var id: Prism<S, S> {
        Prism(preview: { .some($0) }, review: { $0 })
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
