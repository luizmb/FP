// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<*>) :: Reader<env, Validation<e,(a->b)>> -> Reader<env, Validation<e,a>> -> Reader<env, Validation<e,b>>
public func <*> <Env, E: Semigroup, A, B>(
    _ readerF: Reader<Env, Validation<E, @Sendable (A) -> B>>,
    _ readerA: Reader<Env, Validation<E, A>>
) -> Reader<Env, Validation<E, B>> {
    applyReaderValidation(readerF, readerA)
}

/// (*>) :: Reader<env, Validation<e,a>> -> Reader<env, Validation<e,b>> -> Reader<env, Validation<e,b>>
public func *> <Env, E: Semigroup, A, B>(
    _ lhs: Reader<Env, Validation<E, A>>,
    _ rhs: Reader<Env, Validation<E, B>>
) -> Reader<Env, Validation<E, B>> {
    seqRightReaderValidation(lhs, rhs)
}

/// (<*) :: Reader<env, Validation<e,a>> -> Reader<env, Validation<e,b>> -> Reader<env, Validation<e,a>>
public func <* <Env, E: Semigroup, A, B>(
    _ lhs: Reader<Env, Validation<E, A>>,
    _ rhs: Reader<Env, Validation<E, B>>
) -> Reader<Env, Validation<E, A>> {
    seqLeftReaderValidation(lhs, rhs)
}
