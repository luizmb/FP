import Foundation

// OptionalTEither: outer = Optional, inner = Either
// Type: Either<L,A>? = Optional<Either<L,A>>

public extension Optional {
    /// mapT for Optional<Either<L,A>> — maps over the inner Either's right side
    func mapT<L, A, B>(_ fn: @escaping @Sendable (A) -> B) -> Either<L, B>? where Wrapped == Either<L, A> {
        map { either in either.mapRight(fn) }
    }

    static func fmapT<L, A, B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable (Either<L, A>?) -> Either<L, B>? {
        { opt in opt.mapT(fn) }
    }
}
