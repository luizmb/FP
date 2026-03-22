import Foundation
import CoreFP

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
}
