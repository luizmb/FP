import CoreFP
import Foundation

public extension Stateful {
    /// apply :: Stateful<s, (input -> a)> -> Stateful<s, input> -> Stateful<s, a>
    /// Runs sf then sa left-to-right, threading state through both.
    /// Follows Reader's convention: `A` is the result type, `Input` is the argument type.
    static func apply<Input>(_ sf: Stateful<S, (Input) -> A>, _ sa: Stateful<S, Input>) -> Stateful<S, A> {
        Stateful<S, A> { s in
            let f = sf.run(&s)
            let a = sa.run(&s)
            return f(a)
        }
    }

    func seqRight<B>(_ other: Stateful<S, B>) -> Stateful<S, B> {
        Stateful<S, B> { s in
            _ = self.run(&s)
            return other.run(&s)
        }
    }

    func seqLeft<B>(_ other: Stateful<S, B>) -> Stateful<S, A> {
        Stateful<S, A> { s in
            let a = self.run(&s)
            _ = other.run(&s)
            return a
        }
    }

    static func liftA2<B, C>(
        _ fn: @escaping (A, B) -> C
    ) -> (Stateful<S, A>, Stateful<S, B>) -> Stateful<S, C> {
        { sa, sb in
            Stateful<S, C> { s in
                let a = sa.run(&s)
                let b = sb.run(&s)
                return fn(a, b)
            }
        }
    }

    /// zip :: Stateful<s, a1> -> Stateful<s, a2> -> Stateful<s, (a1, a2)>
    /// Threads state left-to-right through both computations.
    static func zip<A1, A2>(_ sa1: Stateful<S, A1>, _ sa2: Stateful<S, A2>) -> Stateful<S, A>
    where A == (A1, A2) {
        Stateful<S, (A1, A2)> { s in
            let a1 = sa1.run(&s)
            let a2 = sa2.run(&s)
            return (a1, a2)
        }
    }

    /// zip3 :: Stateful<s, a1> -> Stateful<s, a2> -> Stateful<s, a3> -> Stateful<s, (a1, a2, a3)>
    /// Threads state left-to-right through all three computations.
    static func zip3<A1, A2, A3>(
        _ sa1: Stateful<S, A1>,
        _ sa2: Stateful<S, A2>,
        _ sa3: Stateful<S, A3>
    ) -> Stateful<S, A>
    where A == (A1, A2, A3) {
        Stateful<S, (A1, A2, A3)> { s in
            let a1 = sa1.run(&s)
            let a2 = sa2.run(&s)
            let a3 = sa3.run(&s)
            return (a1, a2, a3)
        }
    }

    /// zip4 :: Stateful<s, a1> -> … -> Stateful<s, a4> -> Stateful<s, (a1, a2, a3, a4)>
    /// Threads state left-to-right through all four computations.
    static func zip4<A1, A2, A3, A4>(
        _ sa1: Stateful<S, A1>,
        _ sa2: Stateful<S, A2>,
        _ sa3: Stateful<S, A3>,
        _ sa4: Stateful<S, A4>
    ) -> Stateful<S, A>
    where A == (A1, A2, A3, A4) {
        Stateful<S, (A1, A2, A3, A4)> { s in
            let a1 = sa1.run(&s)
            let a2 = sa2.run(&s)
            let a3 = sa3.run(&s)
            let a4 = sa4.run(&s)
            return (a1, a2, a3, a4)
        }
    }
}
