import CoreFP

// ReaderTValidation: outer = Reader, inner = Validation
// Type: Reader<Env, Validation<E, A>>
// Runs both readers independently, then accumulates Validation errors.

public func applyReaderValidation<Env, E: Semigroup, A, B>(
    _ readerF: Reader<Env, Validation<E, (A) -> B>>,
    _ readerA: Reader<Env, Validation<E, A>>
) -> Reader<Env, Validation<E, B>> {
    Reader { env in Validation.apply(readerF(env), readerA(env)) }
}

public func liftA2ReaderValidation<Env, E: Semigroup, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Reader<Env, Validation<E, A>>, Reader<Env, Validation<E, B>>) -> Reader<Env, Validation<E, C>> {
    { ra, rb in Reader { env in Validation.liftA2(fn)(ra(env), rb(env)) } }
}

public func seqRightReaderValidation<Env, E: Semigroup, A, B>(
    _ lhs: Reader<Env, Validation<E, A>>,
    _ rhs: Reader<Env, Validation<E, B>>
) -> Reader<Env, Validation<E, B>> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

public func seqLeftReaderValidation<Env, E: Semigroup, A, B>(
    _ lhs: Reader<Env, Validation<E, A>>,
    _ rhs: Reader<Env, Validation<E, B>>
) -> Reader<Env, Validation<E, A>> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
