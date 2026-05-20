import Foundation

// StatefulT + Reader — free functions for Stateful<S, Reader<Env, A>>

/// apply for Stateful<S, Reader>
public func applyStatefulReader<S, Env, A, B>(
    _ sf: Stateful<S, Reader<Env, (A) -> B>>,
    _ sa: Stateful<S, Reader<Env, A>>
) -> Stateful<S, Reader<Env, B>> {
    Stateful<S, Reader<Env, B>> { s in
        let readerF = sf.run(&s)
        let readerA = sa.run(&s)
        return Reader { env in readerF(env)(readerA(env)) }
    }
}

/// liftA2 for Stateful<S, Reader>
public func liftA2StatefulReader<S, Env, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, Reader<Env, A>>, Stateful<S, Reader<Env, B>>) -> Stateful<S, Reader<Env, C>> {
    { sa, sb in
        Stateful<S, Reader<Env, C>> { s in
            Reader.liftA2(fn)(sa.run(&s), sb.run(&s))
        }
    }
}

/// seqRight for Stateful<S, Reader>
public func seqRightStatefulReader<S, Env, A, B>(
    _ lhs: Stateful<S, Reader<Env, A>>,
    _ rhs: Stateful<S, Reader<Env, B>>
) -> Stateful<S, Reader<Env, B>> {
    Stateful<S, Reader<Env, B>> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for Stateful<S, Reader>
public func seqLeftStatefulReader<S, Env, A, B>(
    _ lhs: Stateful<S, Reader<Env, A>>,
    _ rhs: Stateful<S, Reader<Env, B>>
) -> Stateful<S, Reader<Env, A>> {
    Stateful<S, Reader<Env, A>> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
