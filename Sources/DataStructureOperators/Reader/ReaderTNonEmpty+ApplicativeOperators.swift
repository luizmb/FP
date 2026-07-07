// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import Foundation

// ReaderTNonEmpty: outer = Reader, inner = NonEmpty
// Type: Reader<Environment, NonEmpty<A>>

/// (<*>) :: Reader<Env, NonEmpty<(A -> B)>> -> Reader<Env, NonEmpty<A>> -> Reader<Env, NonEmpty<B>>
public func <*> <Env, A, B>(
    _ readerF: Reader<Env, NonEmpty<@Sendable (A) -> B>>,
    _ readerA: Reader<Env, NonEmpty<A>>
) -> Reader<Env, NonEmpty<B>> {
    applyReaderNonEmpty(readerF, readerA)
}

/// (*>) :: Reader<Env, NonEmpty<A>> -> Reader<Env, NonEmpty<B>> -> Reader<Env, NonEmpty<B>>
public func *> <Env, A, B>(
    _ lhs: Reader<Env, NonEmpty<A>>,
    _ rhs: Reader<Env, NonEmpty<B>>
) -> Reader<Env, NonEmpty<B>> {
    seqRightReaderNonEmpty(lhs, rhs)
}

/// (<*) :: Reader<Env, NonEmpty<A>> -> Reader<Env, NonEmpty<B>> -> Reader<Env, NonEmpty<A>>
public func <* <Env, A, B>(
    _ lhs: Reader<Env, NonEmpty<A>>,
    _ rhs: Reader<Env, NonEmpty<B>>
) -> Reader<Env, NonEmpty<A>> {
    seqLeftReaderNonEmpty(lhs, rhs)
}
