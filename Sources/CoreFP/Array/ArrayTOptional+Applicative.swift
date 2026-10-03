// SPDX-License-Identifier: Apache-2.0
import Foundation

// ArrayTOptional: outer = Array, inner = Optional
// Type: [A?] = Array<Optional<A>>
// Haskell: MaybeT []
//
// The applicative is derived from the monad (`<*>` = `ap`): sequential and short-circuiting
// exactly like `flatMapT`. A `nil` on the left yields a single `nil` and never runs the right side.

/// apply for ArrayTOptional: [(A->B)?] -> [A?] -> [B?]
/// mf <*> ma = mf >>= \f -> fmap f ma
public func applyArrayOptional<A, B>(_ fns: [(@Sendable (A) -> B)?], _ values: [A?]) -> [B?] {
    bindArrayOptional(fns) { f in values.mapT(f) }
}

/// liftA2 for ArrayTOptional: (A,B)->C -> [A?] -> [B?] -> [C?]
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2ArrayOptional<A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> ([A?], [B?]) -> [C?] {
    { arrA, arrB in
        bindArrayOptional(arrA) { a in arrB.map { optB in optB.map { b in fn(a, b) } } }
    }
}

/// seqRight for ArrayTOptional: [A?] -> [B?] -> [B?]
/// ma *> mb = ma >>= \_ -> mb
public func seqRightArrayOptional<A, B>(_ lhs: [A?], _ rhs: [B?]) -> [B?] {
    bindArrayOptional(lhs, const(rhs))
}

/// seqLeft for ArrayTOptional: [A?] -> [B?] -> [A?]
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftArrayOptional<A, B>(_ lhs: [A?], _ rhs: [B?]) -> [A?] {
    bindArrayOptional(lhs) { a in rhs.map { optB in optB.map(const(a)) } }
}
