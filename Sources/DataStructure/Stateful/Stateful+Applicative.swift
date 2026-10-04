// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// apply :: Stateful<s, (input -> a)> -> Stateful<s, input> -> Stateful<s, a>
    /// Runs sf then sa left-to-right, threading state through both.
    /// Follows Reader's convention: `A` is the result type, `Input` is the argument type.
    static func apply<Input>(_ sf: Stateful<S, @Sendable (Input) -> A>, _ sa: Stateful<S, Input>) -> Stateful<S, A> {
        Stateful<S, A> { s in
            let f = sf.run(&s)
            let a = sa.run(&s)
            return f(a)
        }
    }

    /// seqRight :: Stateful<s, a> -> Stateful<s, b> -> Stateful<s, b>
    /// Runs both left-to-right, threading state through both, and keeps only the right-hand value.
    func seqRight<B>(_ other: Stateful<S, B>) -> Stateful<S, B> {
        Stateful<S, B> { s in
            _ = self.run(&s)
            return other.run(&s)
        }
    }

    /// seqLeft :: Stateful<s, a> -> Stateful<s, b> -> Stateful<s, a>
    /// Runs both left-to-right, threading state through both, and keeps only the left-hand value.
    func seqLeft<B>(_ other: Stateful<S, B>) -> Stateful<S, A> {
        Stateful<S, A> { s in
            let a = self.run(&s)
            _ = other.run(&s)
            return a
        }
    }

    /// Combines two `Stateful` computations with a binary function, threading the state left-to-right through both.
    /// liftA2 :: (a -> b -> c) -> Stateful s a -> Stateful s b -> Stateful s c
    static func liftA2<B, C>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> @Sendable (Stateful<S, A>, Stateful<S, B>) -> Stateful<S, C> {
        { sa, sb in
            Stateful<S, C> { s in
                let a = sa.run(&s)
                let b = sb.run(&s)
                return fn(a, b)
            }
        }
    }

    /// Combines two or more `Stateful`s into one producing a tuple of all their outputs,
    /// threading the state left to right through every argument.
    /// zip :: Stateful s a1 -> Stateful s a2 -> ... -> Stateful s (a1, a2, ...)
    static func zip<A1, A2, each Ax>(
        _ first: Stateful<S, A1>,
        _ second: Stateful<S, A2>,
        _ additional: repeat Stateful<S, each Ax>
    ) -> Stateful<S, A>
    where A == (A1, A2, repeat each Ax) {
        Stateful<S, A> { s in
            let a1 = first.run(&s)
            let a2 = second.run(&s)
            return (a1, a2, repeat (each additional).run(&s))
        }
    }
}
