import Foundation

public extension Reader {
    // ReaderT + Array
    func mapT<A, B>(_ fn: @escaping (A) -> B) -> Reader<Environment, [B]>
    where Output == [A] {
        mapReader { array in
            array.map(fn)
        }
    }

    static func fmap<A, B>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, [A]>) -> Reader<Environment, [B]>
    where Output == [A] {
        { $0.mapT(fn) }
    }
}
