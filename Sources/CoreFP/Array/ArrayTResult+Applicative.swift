// SPDX-License-Identifier: Apache-2.0
import Foundation

// ArrayTResult: outer = Array, inner = Result
// Type: [Result<A,E>] = Array<Result<A,E>>
// Haskell: ExceptT e []
//
// The applicative is derived from the monad (`<*>` = `ap`): sequential and short-circuiting
// exactly like `flatMapT`. A `.failure` on the left yields a single `.failure` and never runs the right side.

/// apply for ArrayTResult: [Result<(A->B),E>] -> [Result<A,E>] -> [Result<B,E>]
/// mf <*> ma = mf >>= \f -> fmap f ma
public func applyArrayResult<A, B, E: Error>(
    _ fns: [Result<@Sendable (A) -> B, E>],
    _ values: [Result<A, E>]
) -> [Result<B, E>] {
    bindArrayResult(fns) { f in values.mapT(f) }
}

/// liftA2 for ArrayTResult: (A,B)->C -> [Result<A,E>] -> [Result<B,E>] -> [Result<C,E>]
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2ArrayResult<A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> ([Result<A, E>], [Result<B, E>]) -> [Result<C, E>] {
    { arrA, arrB in
        bindArrayResult(arrA) { a in arrB.map { resultB in resultB.map { b in fn(a, b) } } }
    }
}

/// seqRight for ArrayTResult: [Result<A,E>] -> [Result<B,E>] -> [Result<B,E>]
/// ma *> mb = ma >>= \_ -> mb
public func seqRightArrayResult<A, B, E: Error>(
    _ lhs: [Result<A, E>],
    _ rhs: [Result<B, E>]
) -> [Result<B, E>] {
    bindArrayResult(lhs, const(rhs))
}

/// seqLeft for ArrayTResult: [Result<A,E>] -> [Result<B,E>] -> [Result<A,E>]
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftArrayResult<A, B, E: Error>(
    _ lhs: [Result<A, E>],
    _ rhs: [Result<B, E>]
) -> [Result<A, E>] {
    bindArrayResult(lhs) { a in rhs.map { resultB in resultB.map(const(a)) } }
}
