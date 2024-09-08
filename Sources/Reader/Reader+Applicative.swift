import FP
import Foundation

public extension Reader {
    // liftA2 :: (b1 -> b2 -> b) -> Either a b1 -> Either a b2 -> Either a b
    static func liftA2<B1, B2>(_ fn: @escaping (B1, B2) -> Output) -> (
        Reader<Environment, B1>, Reader<Environment, B2>
    ) -> Reader<Environment, Output> {
        { readerA, readerB in
            Reader { env in
                fn(readerA(env), readerB(env))
            }
        }
    }

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
