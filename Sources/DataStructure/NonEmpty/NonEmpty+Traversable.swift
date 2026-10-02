// SPDX-License-Identifier: Apache-2.0
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
        traverse(CoreFP.id)
    }

    // MARK: Result effect (short-circuits on first failure)

    /// Map each element to a `Result`; return the first failure encountered.
    func traverse<B, E>(_ fn: (A) -> Result<B, E>) -> Result<NonEmpty<B>, E> {
        switch fn(head) {
        case let .failure(e):
            return .failure(e)

        case let .success(h):
            var t: [B] = []
            for element in tail {
                switch fn(element) {
                case let .failure(e):
                    return .failure(e)

                case let .success(b):
                    t.append(b)
                }
            }
            return .success(NonEmpty<B>(head: h, tail: t))
        }
    }

    /// Sequence `NonEmpty<Result<B, E>>` into `Result<NonEmpty<B>, E>`.
    func sequence<B, E>() -> Result<NonEmpty<B>, E> where A == Result<B, E> {
        traverse(CoreFP.id)
    }

    // MARK: Either effect (short-circuits on first left)

    /// Map each element to an `Either`; return the first `.left` encountered.
    func traverse<L, B>(_ fn: (A) -> Either<L, B>) -> Either<L, NonEmpty<B>> {
        switch fn(head) {
        case let .left(l):
            return .left(l)

        case let .right(h):
            var t: [B] = []
            for element in tail {
                switch fn(element) {
                case let .left(l):
                    return .left(l)

                case let .right(b):
                    t.append(b)
                }
            }
            return .right(NonEmpty<B>(head: h, tail: t))
        }
    }

    /// Sequence `NonEmpty<Either<L, B>>` into `Either<L, NonEmpty<B>>`.
    func sequence<L, B>() -> Either<L, NonEmpty<B>> where A == Either<L, B> {
        traverse(CoreFP.id)
    }

    // MARK: Validation effect (accumulates all failures)

    /// Map each element to a `Validation`; accumulate ALL failures.
    func traverse<E: Semigroup, B>(_ fn: (A) -> Validation<E, B>) -> Validation<E, NonEmpty<B>> {
        // One pass: successes go into a pre-sized buffer, failures into a list
        // folded once with `sconcat` (O(n) for concatenative error types like `[String]`).
        let headResult = fn(head)
        var values: [B] = []
        values.reserveCapacity(tail.count)
        var errors: [E] = []
        for element in tail {
            switch fn(element) {
            case let .success(b):
                values.append(b)

            case let .failure(e):
                errors.append(e)
            }
        }
        switch headResult {
        case let .success(b):
            guard let firstError = errors.first else { return .success(NonEmpty<B>(head: b, tail: values)) }
            return .failure(E.sconcat(firstError, Array(errors.dropFirst())))

        case let .failure(e):
            return .failure(E.sconcat(e, errors))
        }
    }

    /// Sequence `NonEmpty<Validation<E, B>>` into `Validation<E, NonEmpty<B>>`.
    func sequence<E: Semigroup, B>() -> Validation<E, NonEmpty<B>> where A == Validation<E, B> {
        traverse(CoreFP.id)
    }
}
