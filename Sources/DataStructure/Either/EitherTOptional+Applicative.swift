// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// EitherTOptional: outer = Either, inner = Optional
// Type: Either<L, A?> = Either<L, Optional<A>>
// Haskell: MaybeT (Either L)
//
// The applicative is the one induced by the monad (`<*> = ap`), so it is sequential and
// short-circuits exactly like `flatMapTEitherOptional`: the first `.left` or `.right(nil)`
// in left-to-right order wins. Each function below is `flatMapTEitherOptional` + `mapTEitherOptional`
// with the bind's case analysis inlined, so no non-`Sendable` value is captured in a `@Sendable` closure.

/// apply for EitherTOptional: Either<L,(A->B)?> -> Either<L,A?> -> Either<L,B?>
/// (<*>) = ap :: mf >>= \f -> fmap f ma
public func applyEitherOptional<L, A, B>(
    _ fns: Either<L, (@Sendable (A) -> B)?>,
    _ values: Either<L, A?>
) -> Either<L, B?> {
    switch fns {
    case let .left(l):
        .left(l)

    case .right(.none):
        .right(.none)

    case let .right(.some(fn)):
        mapTEitherOptional(fn, values)
    }
}

/// liftA2 for EitherTOptional
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2EitherOptional<L, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Either<L, A?>, Either<L, B?>) -> Either<L, C?> {
    { lhs, rhs in
        switch (lhs, rhs) {
        case let (.left(l), _):
            .left(l)

        case (.right(.none), _):
            .right(.none)

        case let (.right(.some), .left(l)):
            .left(l)

        case let (.right(.some(a)), .right(optB)):
            .right(optB.map { b in fn(a, b) })
        }
    }
}

/// seqRight for EitherTOptional
/// ma *> mb = ma >>= \_ -> mb
public func seqRightEitherOptional<L, A, B>(
    _ lhs: Either<L, A?>,
    _ rhs: Either<L, B?>
) -> Either<L, B?> {
    switch lhs {
    case let .left(l):
        .left(l)

    case .right(.none):
        .right(.none)

    case .right(.some):
        rhs
    }
}

/// seqLeft for EitherTOptional
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftEitherOptional<L, A, B>(
    _ lhs: Either<L, A?>,
    _ rhs: Either<L, B?>
) -> Either<L, A?> {
    switch (lhs, rhs) {
    case let (.left(l), _):
        .left(l)

    case (.right(.none), _):
        .right(.none)

    case let (.right(.some), .left(l)):
        .left(l)

    case let (.right(.some(a)), .right(optB)):
        .right(optB.map(const(a)))
    }
}
