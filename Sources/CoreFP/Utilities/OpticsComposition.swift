// MARK: - Lens compositions

extension Lens {
    public func compose<B>(_ other: Lens<A, B>) -> Lens<S, B> {
        Lens<S, B>(
            get: { other.get(get($0)) },
            set: { s, b in set(s, other.set(get(s), b)) },
            modifyMut: { s, f in modifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    public func compose<B>(_ other: Prism<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { other.preview(get($0)) },
            set: { s, b in set(s, other.review(b)) },
            tryModifyMut: { s, f in modifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }

    public func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { other.preview(get($0)) },
            set: { s, b in set(s, other.set(get(s), b)) },
            tryModifyMut: { s, f in modifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }
}

// MARK: - Prism compositions

extension Prism {
    public func compose<B>(_ other: Prism<A, B>) -> Prism<S, B> {
        Prism<S, B>(
            preview: { preview($0).flatMap(other.preview) },
            review: { review(other.review($0)) },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }

    public func compose<B>(_ other: Lens<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).map(other.get) },
            set: { s, b in preview(s).map { a in review(other.set(a, b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    public func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).flatMap(other.preview) },
            set: { s, b in preview(s).map { a in review(other.set(a, b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }
}

// MARK: - AffineTraversal compositions

extension AffineTraversal {
    public func compose<B>(_ other: Lens<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).map(other.get) },
            set: { s, b in preview(s).map { a in set(s, other.set(a, b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.modifyMut(&a, f) } }
        )
    }

    public func compose<B>(_ other: Prism<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).flatMap(other.preview) },
            set: { s, b in preview(s).map { _ in set(s, other.review(b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }

    public func compose<B>(_ other: AffineTraversal<A, B>) -> AffineTraversal<S, B> {
        AffineTraversal<S, B>(
            preview: { preview($0).flatMap(other.preview) },
            set: { s, b in preview(s).map { a in set(s, other.set(a, b)) } ?? s },
            tryModifyMut: { s, f in tryModifyMut(&s) { a in other.tryModifyMut(&a, f) } }
        )
    }
}
