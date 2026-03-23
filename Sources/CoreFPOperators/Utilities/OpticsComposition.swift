import CoreFP

// MARK: - Lens compositions

public func >>> <S, A, B>(lhs: Lens<S, A>, rhs: Lens<A, B>) -> Lens<S, B> {
    Lens(
        get: lhs.get >>> rhs.get,
        set: { s, b in lhs.set(s, rhs.set(lhs.get(s), b)) }
    )
}

public func >>> <S, A, B>(lhs: Lens<S, A>, rhs: Prism<A, B>) -> AffineTraversal<S, B> {
    AffineTraversal(
        preview: lhs.get >>> rhs.preview,
        set: { s, b in lhs.set(s, rhs.review(b)) }
    )
}

public func >>> <S, A, B>(lhs: Lens<S, A>, rhs: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
    AffineTraversal(
        preview: lhs.get >>> rhs.preview,
        set: { s, b in lhs.set(s, rhs.set(lhs.get(s), b)) }
    )
}

// MARK: - Prism compositions

public func >>> <S, A, B>(lhs: Prism<S, A>, rhs: Prism<A, B>) -> Prism<S, B> {
    Prism(
        preview: lhs.preview >>> { $0.flatMap(rhs.preview) },
        review: rhs.review >>> lhs.review
    )
}

public func >>> <S, A, B>(lhs: Prism<S, A>, rhs: Lens<A, B>) -> AffineTraversal<S, B> {
    AffineTraversal(
        preview: lhs.preview >>> { $0.map(rhs.get) },
        set: { s, b in lhs.preview(s).map { a in lhs.review(rhs.set(a, b)) } ?? s }
    )
}

public func >>> <S, A, B>(lhs: Prism<S, A>, rhs: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
    AffineTraversal(
        preview: lhs.preview >>> { $0.flatMap(rhs.preview) },
        set: { s, b in lhs.preview(s).map { a in lhs.review(rhs.set(a, b)) } ?? s }
    )
}

// MARK: - AffineTraversal compositions

public func >>> <S, A, B>(lhs: AffineTraversal<S, A>, rhs: Lens<A, B>) -> AffineTraversal<S, B> {
    AffineTraversal(
        preview: lhs.preview >>> { $0.map(rhs.get) },
        set: { s, b in lhs.preview(s).map { a in lhs.set(s, rhs.set(a, b)) } ?? s }
    )
}

public func >>> <S, A, B>(lhs: AffineTraversal<S, A>, rhs: Prism<A, B>) -> AffineTraversal<S, B> {
    AffineTraversal(
        preview: lhs.preview >>> { $0.flatMap(rhs.preview) },
        set: { s, b in lhs.preview(s).map { _ in lhs.set(s, rhs.review(b)) } ?? s }
    )
}

public func >>> <S, A, B>(lhs: AffineTraversal<S, A>, rhs: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
    AffineTraversal(
        preview: lhs.preview >>> { $0.flatMap(rhs.preview) },
        set: { s, b in lhs.preview(s).map { a in lhs.set(s, rhs.set(a, b)) } ?? s }
    )
}
