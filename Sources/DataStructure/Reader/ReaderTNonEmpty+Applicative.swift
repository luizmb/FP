// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// ReaderTNonEmpty: outer = Reader, inner = NonEmpty
// Type: Reader<Environment, NonEmpty<A>>

/// Apply for ReaderT NonEmpty
public func applyReaderNonEmpty<Env, A, B>(
    _ readerF: Reader<Env, NonEmpty<@Sendable (A) -> B>>,
    _ readerA: Reader<Env, NonEmpty<A>>
) -> Reader<Env, NonEmpty<B>> {
    Reader { env in
        NonEmpty.apply(readerF(env), readerA(env))
    }
}

/// liftA2 for ReaderT NonEmpty
public func liftA2ReaderNonEmpty<Env, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Reader<Env, NonEmpty<A>>, Reader<Env, NonEmpty<B>>) -> Reader<Env, NonEmpty<C>> where A: Sendable {
    { readerA, readerB in
        Reader { env in
            NonEmpty.liftA2(fn)(readerA(env), readerB(env))
        }
    }
}

/// seqRight for ReaderT NonEmpty
public func seqRightReaderNonEmpty<Env, A, B>(
    _ lhs: Reader<Env, NonEmpty<A>>,
    _ rhs: Reader<Env, NonEmpty<B>>
) -> Reader<Env, NonEmpty<B>> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderT NonEmpty
public func seqLeftReaderNonEmpty<Env, A, B>(
    _ lhs: Reader<Env, NonEmpty<A>>,
    _ rhs: Reader<Env, NonEmpty<B>>
) -> Reader<Env, NonEmpty<A>> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
