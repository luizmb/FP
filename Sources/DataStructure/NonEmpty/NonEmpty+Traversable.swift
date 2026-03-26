import CoreFP

// MARK: - Traversable

public extension NonEmpty {

    // MARK: Optional effect

    /// Map each element to an `Optional`; return `nil` if any element fails.
    func traverse<B>(_ fn: (A) -> B?) -> NonEmpty<B>? {
        guard let h = fn(head) else { return nil }
        var t: [B] = []
        for element in tail {
            guard let b = fn(element) else { return nil }
            t.append(b)
        }
        return NonEmpty<B>(head: h, tail: t)
    }

    /// Sequence `NonEmpty<A?>` into `NonEmpty<A>?`.
    func sequence<B>() -> NonEmpty<B>? where A == B? {
        traverse(id)
    }

    // MARK: Result effect (short-circuits on first failure)

    /// Map each element to a `Result`; return the first failure encountered.
    func traverse<B, E>(_ fn: (A) -> Result<B, E>) -> Result<NonEmpty<B>, E> {
        switch fn(head) {
        case .failure(let e): return .failure(e)
        case .success(let h):
            var t: [B] = []
            for element in tail {
                switch fn(element) {
                case .failure(let e): return .failure(e)
                case .success(let b): t.append(b)
                }
            }
            return .success(NonEmpty<B>(head: h, tail: t))
        }
    }

    /// Sequence `NonEmpty<Result<B, E>>` into `Result<NonEmpty<B>, E>`.
    func sequence<B, E>() -> Result<NonEmpty<B>, E> where A == Result<B, E> {
        traverse(id)
    }

    // MARK: Either effect (short-circuits on first left)

    /// Map each element to an `Either`; return the first `.left` encountered.
    func traverse<L, B>(_ fn: (A) -> Either<L, B>) -> Either<L, NonEmpty<B>> {
        switch fn(head) {
        case .left(let l): return .left(l)
        case .right(let h):
            var t: [B] = []
            for element in tail {
                switch fn(element) {
                case .left(let l): return .left(l)
                case .right(let b): t.append(b)
                }
            }
            return .right(NonEmpty<B>(head: h, tail: t))
        }
    }

    /// Sequence `NonEmpty<Either<L, B>>` into `Either<L, NonEmpty<B>>`.
    func sequence<L, B>() -> Either<L, NonEmpty<B>> where A == Either<L, B> {
        traverse(id)
    }

    // MARK: Validation effect (accumulates all failures)

    /// Map each element to a `Validation`; accumulate ALL failures.
    func traverse<E: Semigroup, B>(_ fn: (A) -> Validation<E, B>) -> Validation<E, NonEmpty<B>> {
        let headResult: Validation<E, NonEmpty<B>>
        switch fn(head) {
        case .failure(let e): headResult = .failure(e)
        case .success(let b): headResult = .success(NonEmpty<B>(head: b))
        }
        return tail.map(fn).reduce(headResult) { acc, next in
            switch (acc, next) {
            case (.success(let ne), .success(let b)): .success(ne.append(b))
            case (.failure(let e1), .failure(let e2)): .failure(E.combine(e1, e2))
            case (.success, .failure(let e)): .failure(e)
            case (.failure(let e), .success): .failure(e)
            }
        }
    }

    /// Sequence `NonEmpty<Validation<E, B>>` into `Validation<E, NonEmpty<B>>`.
    func sequence<E: Semigroup, B>() -> Validation<E, NonEmpty<B>> where A == Validation<E, B> {
        traverse(id)
    }
}
