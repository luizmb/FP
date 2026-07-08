// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Reader {
    /// pure :: a -> Reader<env, a>  — constant reader, ignores the environment
    static func pure(_ value: Output) -> Reader<Environment, Output> where Output: Sendable {
        Reader(const(value))
    }

    /// liftA2 :: (b1 -> b2 -> b) -> Reader e b1 -> Reader e b2 -> Reader e b
    static func liftA2<B1, B2>(_ fn: @escaping @Sendable (B1, B2) -> Output) -> @Sendable (
        Reader<Environment, B1>, Reader<Environment, B2>
    ) -> Reader<Environment, Output> {
        { readerA, readerB in
            Reader { env in
                fn(readerA(env), readerB(env))
            }
        }
    }

    /// apply :: Reader<e, (a -> b)> -> Reader<e, a> -> Reader<e, b>
    static func apply<A>(
        _ readerF: Reader<Environment, @Sendable (A) -> Output>,
        _ readerA: Reader<Environment, A>
    ) -> Reader<Environment, Output> {
        Reader { env in readerF(env)(readerA(env)) }
    }

    /// seqRight :: Reader<e, a> -> Reader<e, b> -> Reader<e, b>
    /// Run both, discard the left result, return the right
    func seqRight<A>(_ rhs: Reader<Environment, A>) -> Reader<Environment, A> {
        Reader<Environment, A> { env in
            _ = self(env)
            return rhs(env)
        }
    }

    /// seqLeft :: Reader<e, a> -> Reader<e, b> -> Reader<e, a>
    /// Run both, return the left result
    func seqLeft<Ignore>(_ rhs: Reader<Environment, Ignore>) -> Reader<Environment, Output> {
        Reader<Environment, Output> { env in
            let a = self(env)
            _ = rhs(env)
            return a
        }
    }

    /// Combines two or more `Reader`s into a single `Reader` producing a tuple of all their outputs,
    /// running each against the same shared environment.
    /// zip :: Reader e b1 -> Reader e b2 -> ... -> Reader e (b1, b2, ...)
    /// - Parameters:
    ///   - first: The first `Reader` to combine.
    ///   - second: The second `Reader` to combine.
    ///   - additional: Any further `Reader`s to combine, via variadic generics.
    /// - Returns: A `Reader` that runs every argument against the same environment and tuples the results.
    static func zip<B1, B2, each Bx>(
        _ first: Reader<Environment, B1>,
        _ second: Reader<Environment, B2>,
        _ additional: repeat (Reader<Environment, each Bx>)
    ) -> Reader<Environment, Output>
    where Output == (B1, B2, repeat each Bx) {
        Reader { env in
            (first(env), second(env), repeat (each additional)(env))
        }
    }
}
