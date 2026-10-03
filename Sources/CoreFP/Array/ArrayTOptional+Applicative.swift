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
public func applyArrayOptional<A: Sendable, B>(_ fns: [(@Sendable (A) -> B)?], _ values: [A?]) -> [B?] {
    fns.flatMapT { f in values.mapT(f) }
}

/// liftA2 for ArrayTOptional: (A,B)->C -> [A?] -> [B?] -> [C?]
/// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
public func liftA2ArrayOptional<A: Sendable, B: Sendable, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> @Sendable ([A?], [B?]) -> [C?] {
    { arrA, arrB in
        arrA.flatMapT { a in arrB.mapT { b in fn(a, b) } }
    }
}

/// seqRight for ArrayTOptional: [A?] -> [B?] -> [B?]
/// ma *> mb = ma >>= \_ -> mb
public func seqRightArrayOptional<A, B: Sendable>(_ lhs: [A?], _ rhs: [B?]) -> [B?] {
    lhs.flatMapT(const(rhs))
}

/// seqLeft for ArrayTOptional: [A?] -> [B?] -> [A?]
/// ma <* mb = ma >>= \a -> fmap (const a) mb
public func seqLeftArrayOptional<A: Sendable, B: Sendable>(_ lhs: [A?], _ rhs: [B?]) -> [A?] {
    lhs.flatMapT { a in rhs.mapT(const(a)) }
}
