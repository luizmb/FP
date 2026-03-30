import CoreFPOperators
import DataStructure

// EitherTStateful: outer = Either, inner = Stateful
// Type: Either<L, Stateful<S, A>>

// (<£^>) :: (a -> b) -> Either<l, Stateful<s, a>> -> Either<l, Stateful<s, b>>
public func <£^> <L, S, A, B>(_ fn: @escaping (A) -> B, _ either: Either<L, Stateful<S, A>>) -> Either<L, Stateful<S, B>> {
    either.mapT(fn)
}

// (<&^>) :: Either<l, Stateful<s, a>> -> (a -> b) -> Either<l, Stateful<s, b>>
public func <&^> <L, S, A, B>(_ either: Either<L, Stateful<S, A>>, _ fn: @escaping (A) -> B) -> Either<L, Stateful<S, B>> {
    either.mapT(fn)
}
