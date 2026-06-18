// SPDX-License-Identifier: Apache-2.0
import Foundation

// ReaderTStateful: outer = Reader, inner = Stateful
// Type: Reader<Env, Stateful<S, A>>

/// apply for ReaderTStateful: Reader<Env,Stateful<S,(A->B)>> -> Reader<Env,Stateful<S,A>> -> Reader<Env,Stateful<S,B>>
public func applyReaderStateful<Env, S, A, B>(
    _ rf: Reader<Env, Stateful<S, @Sendable (A) -> B>>,
    _ ra: Reader<Env, Stateful<S, A>>
) -> Reader<Env, Stateful<S, B>> {
    Reader { env in Stateful<S, B>.apply(rf(env), ra(env)) }
}

/// liftA2 for ReaderTStateful
public func liftA2ReaderStateful<Env, S, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Reader<Env, Stateful<S, A>>, Reader<Env, Stateful<S, B>>) -> Reader<Env, Stateful<S, C>> {
    { ra, rb in
        Reader { env in
            let sa = ra(env)
            let sb = rb(env)
            return Stateful<S, C> { s in fn(sa.run(&s), sb.run(&s)) }
        }
    }
}

/// seqRight for ReaderTStateful
public func seqRightReaderStateful<Env, S, A, B>(
    _ lhs: Reader<Env, Stateful<S, A>>,
    _ rhs: Reader<Env, Stateful<S, B>>
) -> Reader<Env, Stateful<S, B>> {
    Reader { env in lhs(env).seqRight(rhs(env)) }
}

/// seqLeft for ReaderTStateful
public func seqLeftReaderStateful<Env, S, A, B>(
    _ lhs: Reader<Env, Stateful<S, A>>,
    _ rhs: Reader<Env, Stateful<S, B>>
) -> Reader<Env, Stateful<S, A>> {
    Reader { env in lhs(env).seqLeft(rhs(env)) }
}
